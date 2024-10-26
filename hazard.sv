`default_nettype none
/*
1. lw   R1, 0(R2)
2. add  R3, R1, R4 
*/
module Hazard_Detection #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32           // Data width
)(
    input wire [4:0] IFID_rs1_addr,
    input wire [4:0] IFID_rs2_addr,

    input wire [4:0] MEMWB_rd_addr,
    input reg is_write,
    output wire [1:0] stall_and_flush
)
// check conditions
  always_comb begin
    if (is_write && (IFID_rs1_addr == MEMWB_rd_addr || IFID_rs2_addr == MEMWB_rd_addr)) begin
      stall_and_flush = 2'b10;
    end else begin
      stall_and_flush = 2'b00;
    end
  end

endmodule
