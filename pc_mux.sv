`default_nettype none
//TODO: Confirm PC_reg_in
module PC_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire Branch,
    input  wire [DATA_WIDTH-1:0] Branch_pc_in,  
    input  wire [ADDR_WIDTH-1:0] PC_new_reg_in,
    output wire [ADDR_WIDTH-1:0] PC_new_out
);
    // 组合逻辑。如果Branch为1，则输出Branch_pc_in，否则输出PC_new_reg_in
    assign PC_new_out = Branch ? Branch_pc_in : PC_new_reg_in;
endmodule