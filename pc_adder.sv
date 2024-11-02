`default_nettype none

module PC_ADDER #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire [ADDR_WIDTH-1:0] PC_in,  
    output wire [ADDR_WIDTH-1:0] PC_out
);
    assign PC_out = PC_in + 4;

endmodule