`default_nettype none

module DECODER #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    // From IFID stage
    input wire [31:0] instruction,

    output wire [4:0] rd,       // Destination register index
                                 // 0: No destination register (e.g., Store, Branch)
                                 // 1-31: Valid destination register indices

    output wire [4:0] rs1,      // Source register 1 index
                                 // 0-31: Valid source register indices

    output wire [4:0] rs2,      // Source register 2 index
                                 // 0-31: Valid source register indices
                                 // For instructions that do not use rs2, this can be ignored

    output wire [DATA_WIDTH-1:0] imm,  // Immediate value, sign-extended
                                         // 0: No immediate value (e.g., R-type)
                                         // Non-zero: Immediate value extracted and sign-extended

    output wire imm_type,        // Immediate type indicator
                                 // 1: Instruction includes an immediate value
                                 // 0: Instruction does not include an immediate value
    output wire [4:0] waddr
);
    assign waddr = rd; //TODO: 为了测试，暂时这样写
    reg [4:0] rd_reg;
    reg [4:0] rs1_reg;
    reg [4:0] rs2_reg;
    reg [DATA_WIDTH-1:0] imm_reg;
    reg imm_type_reg;

    assign rd = rd_reg;
    assign rs1 = rs1_reg;
    assign rs2 = rs2_reg;
    assign imm = imm_reg;
    assign imm_type = imm_type_reg;

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    localparam OPCODE_R_TYPE     = 7'b0110011;
    localparam OPCODE_I_TYPE     = 7'b0010011;
    localparam OPCODE_LOAD       = 7'b0000011;
    localparam OPCODE_STORE      = 7'b0100011;
    localparam OPCODE_BRANCH     = 7'b1100011;
    localparam OPCODE_JALR       = 7'b1100111;
    localparam OPCODE_JAL        = 7'b1101111;
    localparam OPCODE_LUI        = 7'b0110111;
    localparam OPCODE_AUIPC      = 7'b0010111;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_reg <= 5'b0;
            rs1_reg <= 5'b0;
            rs2_reg <= 5'b0;
            imm_reg <= {DATA_WIDTH{1'b0}};
            imm_type_reg <= 1'b0;
        end else begin
            case (opcode)
                OPCODE_R_TYPE: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= instruction[19:15];
                    rs2_reg <= instruction[24:20];
                    imm_reg <= {DATA_WIDTH{1'b0}};
                    imm_type_reg <= 1'b0;
                end

                OPCODE_I_TYPE: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= instruction[19:15];
                    rs2_reg <= 5'b0;
                    imm_reg <= {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:20]};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_LOAD: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= instruction[19:15];
                    rs2_reg <= 5'b0;
                    imm_reg <= {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:20]};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_STORE: begin
                    rd_reg <= 5'b0;
                    rs1_reg <= instruction[19:15];
                    rs2_reg <= instruction[24:20];
                    imm_reg <= {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:25], instruction[11:7]};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_BRANCH: begin
                    rd_reg <= 5'b0;
                    rs1_reg <= instruction[19:15];
                    rs2_reg <= instruction[24:20];
                    imm_reg <= {{(DATA_WIDTH-13){instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_JALR: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= instruction[19:15];
                    rs2_reg <= 5'b0;
                    imm_reg <= {{(DATA_WIDTH-12){instruction[31]}}, instruction[31:20]};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_JAL: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= 5'b0;
                    rs2_reg <= 5'b0;
                    imm_reg <= {{(DATA_WIDTH-21){instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_LUI: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= 5'b0;
                    rs2_reg <= 5'b0;
                    imm_reg <= {instruction[31:12], 12'b0};
                    imm_type_reg <= 1'b1;
                end

                OPCODE_AUIPC: begin
                    rd_reg <= instruction[11:7];
                    rs1_reg <= 5'b0;
                    rs2_reg <= 5'b0;
                    imm_reg <= {instruction[31:12], 12'b0};
                    imm_type_reg <= 1'b1;
                end

                default: begin
                    rd_reg <= 5'b0;
                    rs1_reg <= 5'b0;
                    rs2_reg <= 5'b0;
                    imm_reg <= {DATA_WIDTH{1'b0}};
                    imm_type_reg <= 1'b0;
                end
            endcase
        end
    end

endmodule
