`default_nettype none

module Branch #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire reset,

    output wire flush,

    input wire branch,
    input wire [DATA_WIDTH-1:0] imm,

    output wire [ADDR_WIDTH-1:0] bracnch_out,
);
(

)

endmodule