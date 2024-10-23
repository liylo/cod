`default_nettype none

module PC_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire [ADDR_WIDTH-1:0] PC_reg_in,  
    input  wire [ADDR_WIDTH-1:0] Branch_in,  
    output wire [ADDR_WIDTH-1:0] PC_out
);
    always_comb begin : 
        PC_out = PC_reg_in;
    end
endmodule