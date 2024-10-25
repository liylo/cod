`default_nettype none

module Hazard_Detection #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32           // Data width
)(
    input wire [4:0] IFID_rs1_addr,
    input wire [4:0] IFID_rs2_addr,
    input wire [4:0] IDEX_rd_addr,
    input wire MemRead,

    output wire [1:0] stall_and_flush
)
endmodule
