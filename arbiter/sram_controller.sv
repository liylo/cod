module sram_controller_final #(
    parameter DATA_WIDTH      = 32,
    parameter ADDR_WIDTH      = 32,
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES      = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
)(
    input wire clk_i,
    input wire rst_i,

    input wire                 wb_cyc_i,
    input wire                 wb_stb_i,
    output reg                 wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire                 wb_we_i,

    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg                        sram_ce_n,
    output reg                        sram_oe_n,
    output reg                        sram_we_n,
    output reg [SRAM_BYTES-1:0]       sram_be_n
);

typedef enum logic [2:0] {
    STATE_IDLE    = 0,
    STATE_READ    = 1,
    STATE_READ_2  = 2,
    STATE_WRITE   = 3,
    STATE_WRITE_2 = 4,
    STATE_WRITE_3 = 5,
    STATE_DONE    = 6
} state_t;

state_t state;

reg [SRAM_DATA_WIDTH-1:0] sram_data_o_reg;
reg                       sram_data_t_reg;
reg [SRAM_DATA_WIDTH-1:0] sram_data_i_reg;

assign sram_data = (sram_data_t_reg) ? 32'bz : sram_data_o_reg;

reg ram_ce_n_reg;
reg ram_oe_n_reg;
reg ram_we_n_reg;

assign sram_ce_n = ram_ce_n_reg;
assign sram_oe_n = ram_oe_n_reg;
assign sram_we_n = ram_we_n_reg;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        ram_ce_n_reg    <= 1'b1;
        ram_oe_n_reg    <= 1'b1;
        ram_we_n_reg    <= 1'b1;
        sram_be_n       <= 4'b0000;
        sram_data_o_reg <= 0;
        sram_data_t_reg <= 1'b1;
        wb_ack_o        <= 1'b0;
        state           <= STATE_IDLE;
    end else begin
        case (state)
            STATE_IDLE: begin
                if (wb_cyc_i && wb_stb_i) begin
                    ram_ce_n_reg <= 1'b0;
                    sram_addr    <= wb_adr_i[SRAM_ADDR_WIDTH+1:2];
                    sram_be_n    <= ~wb_sel_i;

                    if (wb_we_i) begin
                        sram_data_t_reg <= 1'b0;
                        state           <= STATE_WRITE;
                    end else begin
                        sram_data_t_reg <= 1'b1;
                        ram_oe_n_reg    <= 1'b0;
                        state           <= STATE_READ;
                    end
                end
            end

            STATE_READ: begin
                sram_data_i_reg <= sram_data;
                state           <= STATE_READ_2;
            end

            STATE_READ_2: begin
                if (~sram_be_n[0]) wb_dat_o[7:0]   <= sram_data_i_reg[7:0];
                if (~sram_be_n[1]) wb_dat_o[15:8]  <= sram_data_i_reg[15:8];
                if (~sram_be_n[2]) wb_dat_o[23:16] <= sram_data_i_reg[23:16];
                if (~sram_be_n[3]) wb_dat_o[31:24] <= sram_data_i_reg[31:24];

                ram_oe_n_reg <= 1'b1;
                ram_ce_n_reg <= 1'b1;
                wb_ack_o     <= 1'b1;
                state        <= STATE_DONE;
            end

            STATE_WRITE: begin
                ram_we_n_reg    <= 1'b0;
                sram_data_i_reg <= sram_data;
                state           <= STATE_WRITE_2;
            end

            STATE_WRITE_2: begin
                // For each byte, decide whether to write new data (wb_dat_i) or keep original data (sram_data_i_reg)
                if (~sram_be_n[0])
                    sram_data_o_reg[7:0] <= wb_dat_i[7:0];  // Write new data
                else
                    sram_data_o_reg[7:0] <= sram_data_i_reg[7:0]; // Keep original data

                if (~sram_be_n[1])
                    sram_data_o_reg[15:8] <= wb_dat_i[15:8];
                else
                    sram_data_o_reg[15:8] <= sram_data_i_reg[15:8];

                if (~sram_be_n[2])
                    sram_data_o_reg[23:16] <= wb_dat_i[23:16];
                else
                    sram_data_o_reg[23:16] <= sram_data_i_reg[23:16];

                if (~sram_be_n[3])
                    sram_data_o_reg[31:24] <= wb_dat_i[31:24];
                else
                    sram_data_o_reg[31:24] <= sram_data_i_reg[31:24];

                // Set tri-state buffer to write mode, prepare to drive data onto sram_data bus
                sram_data_t_reg <= 1'b0;
                state           <= STATE_WRITE_3;
            end

            STATE_WRITE_3: begin
                ram_ce_n_reg    <= 1'b1;
                sram_data_t_reg <= 1'b1;
                wb_ack_o        <= 1'b1;
                ram_we_n_reg    <= 1'b1;
                state           <= STATE_DONE;
            end

            STATE_DONE: begin
                wb_ack_o <= 1'b0;
                state    <= STATE_IDLE;
            end

            default: state <= STATE_IDLE;
        endcase
    end
end

endmodule
