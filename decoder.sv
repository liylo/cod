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
    // all possible instructions
    // opcode
    input wire [6:0] opcode,
    // I type
    input wire [11:0] I_imm,
    input wire [4:0] rd,
    input wire [4:0] rs1,
    input wire [2:0] funct3,
    // R type
    input wire [4:0] rs2,

    // S type
    input wire [11:0] S_imm,

    // SB type
    input wire [11:0] SB_imm,

    // U type
    input wire [19:0] U_imm,
    
    // UJ type
    input wire [19:0] UJ_imm,

    output wire [DATA_WIDTH-1:0] imm,
    output wire  imm_type,

    // regfile interface
    output rf_raddr_a,
    output rf_raddr_b,
    output rf_waddr
);
    always_comb begin
        case(opcode)
            7b0110111: begin
                imm = U_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = rs2;
                rf_waddr = rd;
            end
            7b0010111: begin
                imm = U_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 0;
                rf_waddr = rd;
            end
            7b1101111: begin
                imm = UJ_imm;
                imm_type = 4'b1001;
                rf_raddr_a = rs1;
                rf_raddr_b = 0;
                rf_waddr = rd;
            end
            7b1100111: begin
                imm = I_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 0;
                rf_waddr = rd;
            end
            7b0000011: begin
                imm = I_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 0;
                rf_waddr = rd;
            end
            7b0010011: begin
                imm = I_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 0;
                rf_waddr = rd;
            end
        endcase
    end

endmodule