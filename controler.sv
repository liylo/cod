`default_nettype none

// Define ALU operation types
typedef enum logic [3:0] {
    ADD  = 4'b0001,  
    SUB  = 4'b0010,  
    AND  = 4'b0011,  
    OR   = 4'b0100,  
    XOR  = 4'b0101,  
    NOT  = 4'b0110,  // Bitwise NOT, B is ignored
    SLL  = 4'b0111,  // Logical shift left by B[4:0] bits
    SRL  = 4'b1000,  // Logical shift right by B[4:0] bits
    SRA  = 4'b1001,  // Arithmetic shift right by B[4:0] bits
    ROL  = 4'b1010   // Rotate left by B[4:0] bits
} alu_ops_t;

module Controler(
    input wire clk,
    input wire reset,

    input wire [31:0] instruction,

    output reg MemtoReg,   // 1: Write data from memory to register
                           // 0: Write data from ALU to register
    output reg RegWrite,   // 1: Enable writing to the register file
                           // 0: Disable writing to the register file
    output reg MemWrite,   // 1: Enable writing to memory
                           // 0: Disable writing to memory
    output reg MemRead,    // 1: Enable reading from memory
                           // 0: Disable reading from memory
    output reg Branch,     // 1: Enable branch operation
                           // 0: Disable branch operation
    output reg ALUSrc,     // 1: ALU second operand is an immediate value
                           // 0: ALU second operand is from a register
    output reg [3:0] ALUOp  // Specifies the ALU operation to perform based on alu_ops_t
);

    wire [6:0] opcode    = instruction[6:0];
    wire [2:0] funct3    = instruction[14:12];
    wire [6:0] funct7    = instruction[31:25];
    wire [4:0] shamt     = instruction[24:20]; // Shift amount for shift instructions

    localparam OPCODE_R_TYPE     = 7'b0110011;
    localparam OPCODE_I_TYPE     = 7'b0010011;
    localparam OPCODE_LOAD       = 7'b0000011;
    localparam OPCODE_STORE      = 7'b0100011;
    localparam OPCODE_BRANCH     = 7'b1100011;
    localparam OPCODE_JALR       = 7'b1100111;
    localparam OPCODE_JAL        = 7'b1101111;
    localparam OPCODE_LUI        = 7'b0110111;
    localparam OPCODE_AUIPC      = 7'b0010111;

    always_comb begin
        case (opcode)
            OPCODE_R_TYPE: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b0;

                case ({funct7, funct3})
                    {7'b0000000, 3'b000}: ALUOp = ADD;
                    {7'b0100000, 3'b000}: ALUOp = SUB;
                    {7'b0000000, 3'b111}: ALUOp = AND;
                    {7'b0000000, 3'b110}: ALUOp = OR;
                    {7'b0000000, 3'b100}: ALUOp = XOR;
                    {7'b0000000, 3'b001}: ALUOp = SLL;
                    {7'b0000000, 3'b101}: ALUOp = SRL;
                    {7'b0100000, 3'b101}: ALUOp = SRA;
                    default: ALUOp = ADD;
                endcase
            end

            OPCODE_I_TYPE: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b1;

                case (funct3)
                    3'b000: ALUOp = ADD;
                    3'b111: ALUOp = AND;
                    3'b110: ALUOp = OR;
                    3'b100: ALUOp = XOR;
                    3'b001: ALUOp = SLL;
                    3'b101: begin
                        if (funct7[5] == 1'b0)
                            ALUOp = SRL;
                        else
                            ALUOp = SRA;
                    end
                    default: ALUOp = ADD;
                endcase
            end

            OPCODE_LOAD: begin
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b1;
                Branch   = 1'b0;
                ALUSrc   = 1'b1;
                ALUOp    = ADD;
            end

            OPCODE_STORE: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b0;
                MemWrite = 1'b1;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b1;
                ALUOp    = ADD;
            end

            OPCODE_BRANCH: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b1;
                ALUSrc   = 1'b0;
                ALUOp    = SUB;
            end

            OPCODE_JALR: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b1;
                ALUOp    = ADD;
            end

            OPCODE_JAL: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b0;
                ALUOp    = ADD;
            end

            OPCODE_LUI: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b1;
                ALUOp    = ADD;
            end

            OPCODE_AUIPC: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b1;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b1;
                ALUOp    = ADD;
            end

            default: begin
                MemtoReg = 1'b0;
                RegWrite = 1'b0;
                MemWrite = 1'b0;
                MemRead  = 1'b0;
                Branch   = 1'b0;
                ALUSrc   = 1'b0;
                ALUOp    = ADD;
            end
        endcase
    end

endmodule
