`default_nettype none

module IFIDREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    //from pc_reg
    input wire [ADDR_WIDTH-1:0] PC_addr,
    output wire [ADDR_WIDTH-1:0] PC_out,

    // from IM
    output wire [ADDR_WIDTH-1:0] instruction,

    input wire flush,

    // all possible instructions
    // opcode
    output wire [6:0] opcode,
    // I type
    output wire [11:0] I_imm,
    output wire [4:0] rd,
    output wire [4:0] rs1,
    output wire [2:0] funct3,
    // R type
    output wire [4:0] rs2,

    // S type
    output wire [11:0] S_imm,

    // SB type
    output wire [11:0] SB_imm,

    // U type
    output wire [19:0] U_imm,
    
    // UJ type
    output wire [19:0] UJ_imm,
    
);

    always_comb begin : 
        PC_out = PC_addr;
    end

    always_comb begin :
        // opcode
        opcode = instruction[6:0];
        // I type
        I_imm = instruction[31:20];
        rd = instruction[11:7];
        rs1 = instruction[19:15];
        funct3 = instruction[14:12];
        
        // R type
        rs2 = instruction[24:20];

        // S type
        S_imm = {instruction[31:25], instruction[11:7]};

        // SB type
        SB_imm = {instruction[31], instruction[7], instruction[30:25], instruction[11:8]};

        // U type
        U_imm = instruction[31:12];

        // UJ type
        UJ_imm = {instruction[31], instruction[19:12], instruction[20], instruction[30:21]};
    end

endmodule