`default_nettype none

module IDEXREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    input wire flush,

    // from reg
    input wire [DATA_WIDTH-1:0] reg_a,
    input wire [DATA_WIDTH-1:0] reg_b,
    input wire [4:0] rd_addr,

    output wire [DATA_WIDTH-1:0] reg_a_out,
    output wire [DATA_WIDTH-1:0] reg_b_out,
    output wire [4:0] rd_addr_out,

    // from decoder
    input wire [DATA_WIDTH-1:0] imm,
    input wire  imm_type,

    // PC
    input wire [ADDR_WIDTH-1:0] PC_in,
)

endmodule