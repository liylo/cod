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

    input wire [4:0] IDEX_rd,
    input reg IDEX_MemRead,
    output reg  stall_and_flush
);
// check conditions
  always_comb begin
    if (IDEX_MemRead && (IFID_rs1_addr == IDEX_rd || IFID_rs2_addr == IDEX_rd)) begin
      stall_and_flush = 1'b1; // stall
    end else begin
      stall_and_flush = 1'b0; // no stall or flush
    end
  end

endmodule
