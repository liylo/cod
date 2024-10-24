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
    input wire [31:0] instruction,

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
            // LUI
            7'b0110111: begin
                imm = {U_imm, 12'b0}; // Upper immediate
                imm_type = 4'b1000;
                rf_raddr_a = 5'b0;
                rf_raddr_b = 5'b0;
                rf_waddr = rd;
            end
            // AUIPC
            7'b0010111: begin
                imm = {U_imm, 12'b0}; // Upper immediate
                imm_type = 4'b1000;
                rf_raddr_a = 5'b0;
                rf_raddr_b = 5'b0;
                rf_waddr = rd;
            end
            // JAL
            7'b1101111: begin
                imm = {UJ_imm, 12'b0}; // Upper immediate
                imm_type = 4'b1001;
                rf_raddr_a = 5'b0;
                rf_raddr_b = 5'b0;
                rf_waddr = rd;
            end
            // JALR
            7'b1100111: begin
                imm = I_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 5'b0;
                rf_waddr = rd;
            end
            // LOAD
            7'b0000011: begin
                imm = I_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 5'b0;
                rf_waddr = rd;
            end
            // IMM
            7'b0010011: begin
                imm = I_imm;
                imm_type = 4'b1000;
                rf_raddr_a = rs1;
                rf_raddr_b = 5'b0;
                rf_waddr = rd;
            end
            // STORE
            7'b0100011: begin
                imm = S_imm;
                imm_type = 4'b1010;
                rf_raddr_a = rs1;
                rf_raddr_b = rs2;
                rf_waddr = 5'b0;
            end
            // BRANCH
            7'b1100011: begin
                imm = SB_imm;
                imm_type = 4'b1100;
                rf_raddr_a = rs1;
                rf_raddr_b = rs2;
                rf_waddr = 5'b0;
            end
            // OP
            7'b0110011: begin
                imm = 0;
                imm_type = 4'b0000; // R-type has no immediate
                rf_raddr_a = rs1;
                rf_raddr_b = rs2;
                rf_waddr = rd;
            end
            default: begin
                imm = 0;
                imm_type = 0;
                rf_raddr_a = 5'b0;
                rf_raddr_b = 5'b0;
                rf_waddr = 5'b0;
            end
        endcase
    end


endmodule