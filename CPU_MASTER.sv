`default_nettype none
// five-stage pipeline CPU
module cpu_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
    ) (
    // control signals
    input  wire clk,
    input  wire reset,
    // Wishbone master interface for IF
    output reg if_wb_cyc_o,
    output reg if_wb_stb_o,
    input  wire if_wb_ack_i,
    output reg [ADDR_WIDTH-1:0] if_wb_adr_o,
    output reg [DATA_WIDTH-1:0] if_wb_dat_o,
    input  wire [DATA_WIDTH-1:0] if_wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] if_wb_sel_o,
    output reg if_wb_we_o,

    // Wishbone master interface for ID
    output reg id_wb_cyc_o,
    output reg id_wb_stb_o,
    input  wire id_wb_ack_i,
    output reg [ADDR_WIDTH-1:0] id_wb_adr_o,
    output reg [DATA_WIDTH-1:0] id_wb_dat_o,
    input  wire [DATA_WIDTH-1:0] id_wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] id_wb_sel_o,
    output reg id_wb_we_o
);
    // IF stage signals
    wire [ADDR_WIDTH-1:0] MEM_Branch_pc;
    wire MEM_branch;
    wire [ADDR_WIDTH-1:0] IF_PC_new_1;
    wire [ADDR_WIDTH-1:0] IF_PC_new;
    wire [ADDR_WIDTH-1:0] IF_PC_reg;
    wire [ADDR_WIDTH-1:0] IF_instr;
    wire [1:0] IF_flush_and_bubble;
    wire [1:0] IF_stall_and_flush;
    
  

    // IF stage module
    // Instantiation of PC_MUX module
    PC_MUX #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) if_pc_mux (
        .Branch(MEM_branch),
        .Branch_pc_in(MEM_Branch_pc),
        .PC_new_reg_in(IF_PC_new_1),
        .PC_new_out(IF_PC_new)
    );

    // Instantiation of PC_REG module
    PC_REG #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) if_pc_reg (
        .clk(clk),
        .reset(reset),
        .PC_new_reg_in(IF_PC_new),
        .stall_and_flush(IF_flush_and_bubble),
        .PC_reg_out(IF_PC_reg)
    );

    // Instantiation of PC_ADDER module
    PC_ADDER #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) if_pc_adder (
        .PC_in(IF_PC_reg),
        .PC_out(IF_PC_new_1)
    );  

    // Instantiation of IM module
    IM #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) if_im (
        .clk(clk),
        .reset(reset),
        .PC_addr(IF_PC_reg),
        .instruction(IF_instr),
        .stall_and_flush(IF_stall_and_flush),
        .wb_cyc_o(if_wb_cyc_o),
        .wb_stb_o(if_wb_stb_o),
        .wb_ack_i(if_wb_ack_i),
        .wb_adr_o(if_wb_adr_o),
        .wb_dat_o(if_wb_dat_o),
        .wb_dat_i(if_wb_dat_i),
        .wb_sel_o(if_wb_sel_o),
        .wb_we_o(if_wb_we_o)
    );

    //IFID 
    wire [ADDR_WIDTH-1:0] IFID_PC;
    wire [ADDR_WIDTH-1:0] IFID_instr;
    wire [1:0] IFID_flush_and_stall;

    // IFID module
    IFIDREG #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) ifid (
        .clk(clk),
        .reset(reset),
        .PC_addr(IF_PC_reg),
        .im_instruction(IF_instr),
        .flush_and_stall(IFID_flush_and_stall),
        .PC_out(IFID_PC),
        .instruction(IFID_instr)
    );

    // ID stage signals
    wire ID_MemtoReg;
    wire ID_RegWrite;
    wire ID_MemWrite;
    wire ID_MemRead;
    wire ID_MemSize;
    wire ID_Branch;
    wire ID_ALUSrc;
    wire [3:0] ID_ALUOp;

    wire [4:0] ID_rd;
    wire [4:0] ID_rs1;
    wire [4:0] ID_rs2;
    wire [31:0] ID_imm;
    wire ID_imm_type;

    wire MEMWB_RegWrite;
    wire [4:0] MEMWB_rf_waddr;
    wire [31:0] WB_wdata;
    wire [31:0] ID_rf_rdata_a;
    wire [31:0] ID_rf_rdata_b;

    wire [2:0] ID_stall_and_flush;



    // ID stage module
    Hazard_Detection #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) id_hazard (
        .IFID_rs1_addr(ID_rs1),
        .IFID_rs2_addr(ID_rs2),
        .IDEX_rd(IDEX_rd),
        .IDEX_MemRead(IDEX_MemRead),
        .stall_and_flush(ID_stall_and_flush)
    );

    Controler control_unit (
    .clk(clk),
    .reset(reset),
    .instruction(IFID_instr),
    .MemtoReg(ID_MemtoReg),
    .RegWrite(ID_RegWrite),
    .MemWrite(ID_MemWrite),
    .MemRead(ID_MemRead),
    .MemSize(ID_MemSize),
    .Branch(ID_Branch),
    .ALUSrc(ID_ALUSrc),
    .ALUOp(ID_ALUOp)
    );

    DECODER #(
    .PC_ADDR(32'h8000_0000),   // Assuming a starting PC address
    .ADDR_WIDTH(32),           // Address width as specified
    .DATA_WIDTH(32)            // Data width as specified
) decoder_instance (
    .clk(clk),
    .reset(reset),
    .instruction(IFID_instr),
    .rd(ID_rd),
    .rs1(ID_rs1),
    .rs2(ID_rs2),
    .imm(ID_imm),
    .imm_type(ID_imm_type)
);

    regfile regfile_unit (
        .clk(clk),
        .reset(reset),
        .rf_raddr_a(ID_rs1),
        .rf_rdata_a(ID_rf_rdata_a),
        .rf_raddr_b(ID_rs2),
        .rf_rdata_b(ID_rf_rdata_b),
        .rf_waddr(MEMWB_rf_waddr),
        .rf_wdata(WB_wdata),
        .rf_we(MEMWB_RegWrite)
    );

    // ID/EX stage signals
    wire IDEX_MemtoReg;
    wire IDEX_RegWrite;
    wire IDEX_MemWrite;
    wire IDEX_MemRead;
    wire IDEX_MemSize;
    wire IDEX_Branch;
    wire IDEX_ALUSrc;
    wire [3:0] IDEX_ALUOp;
    wire [DATA_WIDTH-1:0] IDEX_rdata_a;
    wire [DATA_WIDTH-1:0] IDEX_rdata_b;
    wire [4:0] IDEX_rs1;
    wire [4:0] IDEX_rs2;
    wire [4:0] IDEX_rd;
    wire [DATA_WIDTH-1:0] IDEX_imm;
    wire IDEX_imm_type;
    wire [1:0] IDEX_flush_and_stall;
    wire [ADDR_WIDTH-1:0] IDEX_PC;

    // ID/EX stage module
    IDEXREG #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) idex (
        .clk(clk),
        .reset(reset),
        .flush_and_stall(IDEX_flush_and_stall),
        .MemtoReg(ID_MemtoReg),
        .RegWrite(ID_RegWrite),
        .MemWrite(ID_MemWrite),
        .MemRead(ID_MemRead),
        .MemSize(ID_MemSize),
        .Branch(ID_Branch),
        .ALUSrc(ID_ALUSrc),
        .ALUOp(ID_ALUOp),
        .PC_in(IFID_PC),
        .rs1_data(ID_rf_rdata_a),
        .rs2_data(ID_rf_rdata_b),
        .rs1_addr(ID_rs1),
        .rs2_addr(ID_rs2),
        .rd_addr(ID_rd),
        .imm_type(ID_imm_type),
        .imm(ID_imm),
        .PC_out(IDEX_PC),
        .rs1_data_out(IDEX_rdata_a),
        .rs2_data_out(IDEX_rdata_b),
        .ALUOp_out(IDEX_ALUOp),
        .ALUSrc_out(IDEX_ALUSrc),
        .MemtoReg_out(IDEX_MemtoReg),
        .RegWrite_out(IDEX_RegWrite),
        .MemWrite_out(IDEX_MemWrite),
        .MemRead_out(IDEX_MemRead),
        .MemSize_out(IDEX_MemSize),
        .Branch_out(IDEX_Branch),
        .imm_type_out(IDEX_imm_type),
        .imm_out(IDEX_imm)
    );


endmodule
