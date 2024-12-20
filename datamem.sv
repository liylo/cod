`default_nettype none

module MEMORY #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    // Calculate the number of bytes and byte width
    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // Clock and reset
    input wire clk_i,
    input wire rst_i,

    // Stall signal
    output wire stall_and_flush_out,

    // Wishbone interface
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,

    // CPU interface
    input wire Mem_size_in,               // 0: Byte access, 1: Word access
    input wire Mem_write_in,
    input wire Mem_Read_in,
    input wire [ADDR_WIDTH-1:0] Mem_addr_in,
    input wire [DATA_WIDTH-1:0] Mem_data_in,
    output wire [DATA_WIDTH-1:0] Mem_data_out
);
    // State machine states
    localparam IDLE  = 2'b00;
    localparam READ  = 2'b01;
    localparam WRITE = 2'b10;

    reg [1:0] state, next_state;

    // Internal registers
    reg [ADDR_WIDTH-1:0] addr_reg;
    reg size_reg;
    reg [DATA_WIDTH-1:0] read_data_reg;

    // Combinational logic for immediate data output
    reg [DATA_WIDTH-1:0] read_data_comb;

    // State transition logic
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (Mem_Read_in)
                    next_state = READ;
                else if (Mem_write_in)
                    next_state = WRITE;
                else
                    next_state = IDLE;
            end
            READ: begin
                if (wb_ack_i)
                    next_state = IDLE;
                else
                    next_state = READ;
            end
            WRITE: begin
                if (wb_ack_i)
                    next_state = IDLE;
                else
                    next_state = WRITE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Output logic and register updates
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            // Reset outputs and registers
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_we_o  <= 1'b0;
            wb_adr_o <= {ADDR_WIDTH{1'b0}};
            wb_dat_o <= {DATA_WIDTH{1'b0}};
            wb_sel_o <= {DATA_WIDTH/8{1'b0}};

            addr_reg <= {ADDR_WIDTH{1'b0}};
            size_reg <= 1'b0;
            read_data_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    wb_we_o  <= 1'b0;

                    if (Mem_Read_in || Mem_write_in) begin
                        // Capture inputs
                        addr_reg <= Mem_addr_in;
                        size_reg <= Mem_size_in;
                        wb_adr_o <= Mem_addr_in;
                        wb_we_o  <= Mem_write_in;
                        wb_cyc_o <= 1'b1;
                        wb_stb_o <= 1'b1;

                        // Determine byte enables and data
                        if (Mem_size_in == 1'b0) begin // Byte access
                            case (Mem_addr_in[1:0])
                                2'b00: begin
                                    wb_sel_o <= 4'b0001;
                                    if (Mem_write_in)
                                        wb_dat_o <= {24'b0, Mem_data_in[7:0]};
                                end
                                2'b01: begin
                                    wb_sel_o <= 4'b0010;
                                    if (Mem_write_in)
                                        wb_dat_o <= {16'b0, Mem_data_in[7:0], 8'b0};
                                end
                                2'b10: begin
                                    wb_sel_o <= 4'b0100;
                                    if (Mem_write_in)
                                        wb_dat_o <= {8'b0, Mem_data_in[7:0], 16'b0};
                                end
                                2'b11: begin
                                    wb_sel_o <= 4'b1000;
                                    if (Mem_write_in)
                                        wb_dat_o <= {Mem_data_in[7:0], 24'b0};
                                end
                            endcase
                        end else begin // Word access
                            wb_sel_o <= 4'b1111;
                            if (Mem_write_in)
                                wb_dat_o <= Mem_data_in;
                        end
                        // For read operations, no need to set wb_dat_o
                    end
                end
                READ: begin
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o  <= 1'b0;
                    wb_adr_o <= addr_reg;
                    // Keep the previous wb_sel_o

                    if (wb_ack_i) begin
                        wb_cyc_o <= 1'b0;
                        wb_stb_o <= 1'b0;
                        // Update read_data_reg in the next clock cycle
                        read_data_reg <= read_data_comb;
                    end
                end
                WRITE: begin
                    wb_cyc_o <= 1'b1;
                    wb_stb_o <= 1'b1;
                    wb_we_o  <= 1'b1;
                    wb_adr_o <= addr_reg;
                    // Keep the previous wb_sel_o and wb_dat_o

                    if (wb_ack_i) begin
                        wb_cyc_o <= 1'b0;
                        wb_stb_o <= 1'b0;
                    end
                end
                default: begin
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    wb_we_o  <= 1'b0;
                end
            endcase
        end
    end

    // Combinational logic for immediate data output
    always @(*) begin
        if (state == READ && wb_ack_i) begin
            if (size_reg == 1'b0) begin // Byte access
                case (addr_reg[1:0])
                    2'b00: read_data_comb = {{24{wb_dat_i[7]}}, wb_dat_i[7:0]};
                    2'b01: read_data_comb = {{24{wb_dat_i[15]}}, wb_dat_i[15:8]};
                    2'b10: read_data_comb = {{24{wb_dat_i[23]}}, wb_dat_i[23:16]};
                    2'b11: read_data_comb = {{24{wb_dat_i[31]}}, wb_dat_i[31:24]};
                endcase
            end else begin // Word access
                read_data_comb = wb_dat_i;
            end
        end else begin
            read_data_comb = read_data_reg; // Default to the last read data
        end
    end

    // Output data to CPU (immediate output)
    assign Mem_data_out = read_data_comb;

    // Stall signal (stall when memory access is in progress)
    assign stall_and_flush_out = (next_state != IDLE);

endmodule
