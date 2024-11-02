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
    input wire [4:0] IDEX_rd_addr,
    input wire IDEXMemRead,

    output wire stall_and_flush
);
    always_comb begin: 
        stall_and_flush = IDEXMemRead && (
            (IDEX_rd_addr != 0) && (
                (IDEX_rd_addr == IFID_rs1_addr) ||
                (IDEX_rd_addr == IFID_rs2_addr)
            )
        );
    end
endmodule
