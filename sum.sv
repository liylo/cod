`default_nettype none
//TODO 内部逻辑还不完善，根据指令设计
module SUM #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire [ADDR_WIDTH-1:0] PC_reg_in,
    input wire [DATA_WIDTH-1:0] reg_a_in,
    input wire [DATA_WIDTH-1:0] imm,

    input wire [2:0] branch, // 0: branch, 1: eq, 2: jump

    output reg [ADDR_WIDTH-1:0] PC_reg_out
);
    
        always_comb begin
            if (branch[0]) begin
                PC_reg_out = PC_reg_in + imm;
            end
            else if (branch[2]) begin
                // jalr
                PC_reg_out = reg_a_in + imm;
            end else begin
                PC_reg_out = PC_reg_in + 4;
            end
        end
        
endmodule