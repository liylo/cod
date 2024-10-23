`default_nettype none

module PC_REG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire [ADDR_WIDTH-1:0] PC_new_reg_in,  
    input  wire  flush,
    output wire [ADDR_WIDTH-1:0] PC_reg_out,
);
    reg [ADDR_WIDTH-1:0] pc_reg;

    always_comb begin : 
        PC_reg_out = pc_reg;
    end

endmodule