`default_nettype none

module SUM #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire clk,
    input wire reset,

    input wire [ADDR_WIDTH-1:0] PC_reg_in,
    input wire [DATA_WIDTH-1:0] reg_a_in,
    input wire [DATA_WIDTH-1:0] imm,

    input wire branch,

    output wire [ADDR_WIDTH-1:0] PC_reg_out,
);
    
        always_comb begin : 
            if (branch) begin
                PC_reg_out = PC_reg_in + imm;
            end else begin
                PC_reg_out = PC_reg_in + 4;
            end
        end
        
endmodule