`default_nettype none

module EXMEMREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire [ADDR_WIDTH-1:0] PC_in,
    input wire [ADDR_WIDTH-1:0] Next_PC_in,

    input wire [DATA_WIDTH-1:0] ALU_in,

    input wire [DATA_WIDTH-1:0] reg_a_in,
    input wire [DATA_WIDTH-1:0] reg_b_in,

    // forward in
    // pass

    output wire [ADDR_WIDTH-1:0] PC_out,
    output wire [ADDR_WIDTH-1:0] Next_PC_out,

    output wire [DATA_WIDTH-1:0] ALU_out,

    input wire flush,
)

endmodule