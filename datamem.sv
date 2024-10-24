module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i, 
    input wire rst_i, 

    // flush
    output wire [1:0] stall_and_flush,

    // wishbone slave interface
    input wire wb_cyc_i, 
    input wire wb_stb_i, 
    output reg wb_ack_o, 
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i, // Byte enable from Wishbone
    input wire wb_we_i, 

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n, 
    output reg sram_oe_n, 
    output reg sram_we_n, 
    output reg [SRAM_BYTES-1:0] sram_be_n // Byte enable for SRAM
);

  typedef enum logic [2:0] {
    STATE_IDLE = 0,
    STATE_READ = 1,
    STATE_READ_2 = 2,
    STATE_WRITE = 3,
    STATE_WRITE_2 = 4,
    STATE_WRITE_3 = 5,
    STATE_DONE = 6
  } state_t;

  state_t state;

  // SRAM data tri-state control
  reg [SRAM_DATA_WIDTH-1:0] sram_data_o_reg;
  reg sram_data_t_reg; // Tri-state control
  
  reg [SRAM_DATA_WIDTH-1:0] sram_data_i_reg; // Input register for SRAM data

  // Assign the tri-state data bus control
  assign sram_data = (sram_data_t_reg) ? 32'bz : sram_data_o_reg;

  // Control signals
  reg ram_ce_n_reg;
  reg ram_oe_n_reg;
  reg ram_we_n_reg;

  // Assign control signals to actual outputs
  assign sram_ce_n = ram_ce_n_reg;
  assign sram_oe_n = ram_oe_n_reg;
  assign sram_we_n = ram_we_n_reg;

  // Main state machine
  always_ff @ (posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      // Reset logic
      ram_ce_n_reg <= 1'b1;
      ram_oe_n_reg <= 1'b1;
      ram_we_n_reg <= 1'b1;
      sram_be_n <= 4'b0000;
      sram_data_o_reg <= 0;
      sram_data_t_reg <= 1'b1; // Default to high-Z (input mode)
      wb_ack_o <= 1'b0;
      state <= STATE_IDLE;
    end else begin
      case (state)
        STATE_IDLE: begin
          if (wb_cyc_i && wb_stb_i) begin
            // stall_and_flush <= 2'b00;
            stall_and_flush <= 2'b10;

            ram_ce_n_reg <= 1'b0; // Enable SRAM
            sram_addr <=  wb_adr_i[SRAM_ADDR_WIDTH+1:2]; // Set address
            sram_be_n <= ~wb_sel_i; // Set byte enable based on wb_sel_i

            if (wb_we_i) begin
              // Write cycle
              sram_data_t_reg <= 1'b0; // Drive sram_data bus (write mode)
              state <= STATE_WRITE;
            end else begin
              // Read cycle
              sram_data_t_reg <= 1'b1; // Set sram_data to high-Z (read mode)
              ram_oe_n_reg <= 1'b0; // Enable SRAM output
              state <= STATE_READ;
            end
          end
        end

        STATE_READ: begin
          // Latch the SRAM data on read cycle
          sram_data_i_reg <= sram_data; // Read data from SRAM
          state <= STATE_READ_2;
        end

        STATE_READ_2: begin
          // Latch read data from SRAM and acknowledge
          // Selectively copy the data bytes based on sram_be_n
          if (~sram_be_n[0]) wb_dat_o[7:0] <= sram_data_i_reg[7:0];
          if (~sram_be_n[1]) wb_dat_o[15:8] <= sram_data_i_reg[15:8];
          if (~sram_be_n[2]) wb_dat_o[23:16] <= sram_data_i_reg[23:16];
          if (~sram_be_n[3]) wb_dat_o[31:24] <= sram_data_i_reg[31:24];

          ram_oe_n_reg <= 1'b1; // Disable output
          ram_ce_n_reg <= 1'b1; // Disable SRAM
          wb_ack_o <= 1'b1; // Acknowledge the read operation
          state <= STATE_DONE;
        end

        STATE_WRITE: begin
          // Setup for writing to SRAM
          ram_we_n_reg <= 1'b0; // Write enable
          sram_data_i_reg <= sram_data;
          state <= STATE_WRITE_2;
        end

STATE_WRITE_2: begin
  // ??????????????? sram_be_n ?????????��???????? (wb_dat_i) ????????????? (sram_data_i_reg)
  if (~sram_be_n[0])
    sram_data_o_reg[7:0] <= wb_dat_i[7:0];  // ��????????
  else
    sram_data_o_reg[7:0] <= sram_data_i_reg[7:0]; // ??????????
  
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

  // ??????????????��??????????????????? sram_data ????
  sram_data_t_reg <= 1'b0; // Ensure driving sram_data
  state <= STATE_WRITE_3;
end

        STATE_WRITE_3: begin
          // Finish the write cycle
          ram_ce_n_reg <= 1'b1; // Disable SRAM
          sram_data_t_reg <= 1'b1; // Set data bus to high-Z
          wb_ack_o <= 1'b1; // Acknowledge the write operation
          ram_we_n_reg <= 1'b1; // Disable write (???��????)
          state <= STATE_DONE;
        end

        STATE_DONE: begin
          // Complete the cycle and reset acknowledgment
          wb_ack_o <= 1'b0; // Reset acknowledgment
          state <= STATE_IDLE; // Return to idle state
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end
endmodule
