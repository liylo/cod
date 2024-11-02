`default_nettype none

/*
 * IDEXREG module for RISC-V pipeline
 *
 * Responsibilities:
 * 1. Store control and data signals from ID stage to EX stage
 * 2. Handle pipeline stalls and flushes
 */
module IDEXREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    input wire [1:0] flush_and_stall,

    // Save for WB stage
    input wire MemtoReg,
    input wire RegWrite,

    output reg MemtoReg_out,   // 1: Write data from memory to register
                               // 0: Write data from ALU to register
    output reg RegWrite_out,   // 1: Enable writing to the register file
                               // 0: Disable writing to the register file

    // Save for MEM stage
    input wire MemWrite,
    input wire MemRead,
    input wire [2:0] Branch,
    input wire MemSize,

    output reg MemWrite_out,   // 1: Enable writing to memory
                               // 0: Disable writing to memory
    output reg MemRead_out,    // 1: Enable reading from memory
                               // 0: Disable reading from memory
    output reg MemSize_out,    // 1: 32-bit memory access
                               // 0: 8-bit memory access
    output reg [2:0] Branch_out,     // 1: Enable branch operation
                               // 0: Disable branch operation

    // Save for EX stage
    input wire [3:0] ALUOp,
    input wire [1:0] ALUSrc,

    output reg [3:0] ALUOp_out, // Specifies the ALU operation to perform based on alu_ops_t
    output reg [1:0] ALUSrc_out,      // 1: ALU second operand is an immediate value
                               // 0: ALU second operand is from a register

    // Save for ID/EX stage
    input wire [ADDR_WIDTH-1:0] PC_in,

    input wire [DATA_WIDTH-1:0] rs1_data,
    input wire [DATA_WIDTH-1:0] rs2_data,
    input wire [4:0] rs1_addr,  // Source register 1 index
    input wire [4:0] rs2_addr,  // Source register 2 index
    input wire [4:0] rd_addr,   // Destination register index

    input wire imm_type,
    input wire [DATA_WIDTH-1:0] imm,

    output reg [ADDR_WIDTH-1:0] PC_out,

    output reg [DATA_WIDTH-1:0] rs1_data_out,
    output reg [DATA_WIDTH-1:0] rs2_data_out,
    output reg [4:0] rs1_addr_out, // Source register 1 index
    output reg [4:0] rs2_addr_out, // Source register 2 index
    output reg [4:0] rd_addr_out,  // Destination register index

    output reg imm_type_out,         // 1: Instruction includes an immediate value
                                     // 0: Instruction does not include an immediate value
    output reg [DATA_WIDTH-1:0] imm_out // Immediate value, sign-extended
);

    // Decode flush and stall signals
    wire stall = flush_and_stall[0];
    wire flush = flush_and_stall[1];

    // Sequential logic to capture signals on clock edge or handle reset/flush/stall
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all outputs to default values
            MemtoReg_out   <= 1'b0;
            RegWrite_out   <= 1'b0;
            MemWrite_out   <= 1'b0;
            MemRead_out    <= 1'b0;
            MemSize_out    <= 1'b1;
            Branch_out     <= 3'b000;
            ALUOp_out      <= 4'b0000;
            ALUSrc_out     <= 1'b00;
            PC_out         <= PC_ADDR;
            rs1_data_out   <= {DATA_WIDTH{1'b0}};
            rs2_data_out   <= {DATA_WIDTH{1'b0}};
            rs1_addr_out   <= 5'b00000;
            rs2_addr_out   <= 5'b00000;
            rd_addr_out    <= 5'b00000;
            imm_type_out   <= 1'b0;
            imm_out        <= {DATA_WIDTH{1'b0}};
        end else if (flush) begin
            // Flush the pipeline by setting control signals to safe defaults and data signals to zero
            MemtoReg_out   <= 1'b0;
            RegWrite_out   <= 1'b0;
            MemWrite_out   <= 1'b0;
            MemRead_out    <= 1'b0;
            MemSize_out    <= 1'b1;
            Branch_out     <= 3'b000;
            ALUOp_out      <= 4'b0000;
            ALUSrc_out     <= 1'b00;
            PC_out         <= PC_in;
            rs1_data_out   <= {DATA_WIDTH{1'b0}};
            rs2_data_out   <= {DATA_WIDTH{1'b0}};
            rs1_addr_out   <= 5'b00000;
            rs2_addr_out   <= 5'b00000;
            rd_addr_out    <= 5'b00000;
            imm_type_out   <= 1'b0;
            imm_out        <= {DATA_WIDTH{1'b0}};
        end else if (!stall) begin
            // Update all outputs with input values
            MemtoReg_out   <= MemtoReg;
            RegWrite_out   <= RegWrite;
            MemWrite_out   <= MemWrite;
            MemRead_out    <= MemRead;
            MemSize_out    <= MemSize;
            Branch_out     <= Branch;
            ALUOp_out      <= ALUOp;
            ALUSrc_out     <= ALUSrc;
            PC_out         <= PC_in;
            rs1_data_out   <= rs1_data;
            rs2_data_out   <= rs2_data;
            rs1_addr_out   <= rs1_addr;
            rs2_addr_out   <= rs2_addr;
            rd_addr_out    <= rd_addr;
            imm_type_out   <= imm_type;
            imm_out        <= imm;
        end
        // If stall is asserted, hold the current values (do nothing)
    end

endmodule
