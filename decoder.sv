`default_nettype none

module DECODER #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    //from IFID
    input wire [31:0] instruction,

    // all possible instructions
    // opcode
    output wire [6:0] opcode,
    // I type
    output wire [11:0] I_imm,
    output wire [4:0] rd,
    output wire [4:0] rs1,
    output wire [2:0] funct3,
    output wire [4:0] rs2,

    output wire [DATA_WIDTH-1:0] imm,
    output wire  imm_type,

    // regfile interface
    output rf_raddr_a,
    output rf_raddr_b,
    output rf_waddr
);

endmodule