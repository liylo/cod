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
    wire [ADDR_WIDTH-1:0] IF_PC_new_1;
    wire [ADDR_WIDTH-1:0] IF_PC_new;
    wire [ADDR_WIDTH-1:0] IF_PC_reg;
    wire [ADDR_WIDTH-1:0] IF_instr;
    wire [1:0] PC_flush_and_bubble;
    wire  IF_stall_and_flush;
    
  

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
        .stall_and_flush(PC_flush_and_bubble),
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
    wire [1:0] ID_MemtoReg;
    wire ID_RegWrite;
    wire ID_MemWrite;
    wire ID_MemRead;
    wire ID_MemSize;
    wire [2:0] ID_Branch;
    wire [1:0] ID_ALUSrc;
    wire [3:0] ID_ALUOp;

    wire [4:0] ID_rd;
    wire [4:0] ID_rs1;
    wire [4:0] ID_rs2;
    wire [DATA_WIDTH-1:0] ID_imm;
    wire ID_imm_type;

    wire [DATA_WIDTH-1:0] WB_wdata;
    wire [DATA_WIDTH-1:0] ID_rf_rdata_a;
    wire [DATA_WIDTH-1:0] ID_rf_rdata_b;

    wire  ID_stall_and_flush;



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

    wire [DATA_WIDTH-1:0] ID_final_rdata_a;
    wire [DATA_WIDTH-1:0] ID_final_rdata_b;

ID_REG_IN_MUX id_reg_in_mux1 (
.read_addr(ID_rs1),
.write_addr(MEMWB_rd_addr),
 .write_enable(MEMWB_RegWrite),

.write_data(WB_wdata),
.read_data(ID_rf_rdata_a),

   .final_data(ID_final_rdata_a)
);

ID_REG_IN_MUX id_reg_in_mux2 (
.read_addr(ID_rs2),
.write_addr(MEMWB_rd_addr),
 .write_enable(MEMWB_RegWrite),

.write_data(WB_wdata),
.read_data(ID_rf_rdata_b),

   .final_data(ID_final_rdata_b)
);

    regfile regfile_unit (
        .clk(clk),
        .reset(reset),
        .rf_raddr_a(ID_rs1),
        .rf_rdata_a(ID_rf_rdata_a),
        .rf_raddr_b(ID_rs2),
        .rf_rdata_b(ID_rf_rdata_b),
        .rf_waddr(MEMWB_rd_addr),
        .rf_wdata(WB_wdata),
        .rf_we(MEMWB_RegWrite)
    );

    // ID/EX stage signals
    wire [1:0] IDEX_MemtoReg;
    wire IDEX_RegWrite;
    wire IDEX_MemWrite;
    wire IDEX_MemRead;
    wire IDEX_MemSize;
    wire [2:0] IDEX_Branch;
    wire [1:0] IDEX_ALUSrc;
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
        .clk(clk),//
        .reset(reset),//
        .flush_and_stall(IDEX_flush_and_stall),//
        .MemtoReg(ID_MemtoReg),//
        .RegWrite(ID_RegWrite),//
        .MemtoReg_out(IDEX_MemtoReg),//
        .RegWrite_out(IDEX_RegWrite),//
        .MemWrite(ID_MemWrite),//
        .MemRead(ID_MemRead),//
        .Branch(ID_Branch),
        .MemSize(ID_MemSize),
        .ALUSrc(ID_ALUSrc),
        .ALUOp(ID_ALUOp),
        .PC_in(IFID_PC),
        .rs1_data(ID_final_rdata_a),
        .rs2_data(ID_final_rdata_b),
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
        .MemWrite_out(IDEX_MemWrite),
        .MemRead_out(IDEX_MemRead),
        .MemSize_out(IDEX_MemSize),
        .Branch_out(IDEX_Branch),
        .imm_type_out(IDEX_imm_type),
        .imm_out(IDEX_imm),

        .rs1_addr_out(IDEX_rs1),
        .rs2_addr_out(IDEX_rs2),
        .rd_addr_out(IDEX_rd)
    );

    // EX stage signals
    wire [1:0] EX_forward_A;
    wire [1:0] EX_forward_B;
    wire [DATA_WIDTH-1:0] EX_alu_a;
    wire [DATA_WIDTH-1:0] EX_alu_b;
    wire [DATA_WIDTH-1:0] EX_alu_result;
    wire [ADDR_WIDTH-1:0] EX_next_pc;

    // EX stage module
    ALU_MUX #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) ex_alu_mux_a (
        .forward(EX_forward_A),
        .exmem_data(EXMEM_ALU_result),
        .memwb_data(WB_wdata),
        .which_mux(IDEX_ALUSrc[1]),
        .pc_or_imm_in(IDEX_PC),
        .reg_in(IDEX_rdata_a),
        .alu_mux_out(EX_alu_a)
    );

    ALU_MUX #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) ex_alu_mux_b (
        .forward(EX_forward_B),
        .exmem_data(EXMEM_ALU_result),
        .memwb_data(WB_wdata),
        .which_mux(IDEX_ALUSrc[0]),
        .pc_or_imm_in(IDEX_imm),
        .reg_in(IDEX_rdata_b),
        .alu_mux_out(EX_alu_b)
    );

    ALU_final alu_unit(
        .alu_op(IDEX_ALUOp),
        .A(EX_alu_a),
        .B(EX_alu_b),
        .result(EX_alu_result)
    );

    SUM sum_unit(
        .PC_reg_in(IDEX_PC),
        .reg_a_in(IDEX_rdata_a),
        .imm(IDEX_imm),
        .branch(IDEX_Branch),
        .PC_reg_out(EX_next_pc)
    );

    Forward #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) forward_unit (
        .Forward_op1(EX_forward_A),
        .Forward_op2(EX_forward_B),
        .IDEX_rs1_addr(IDEX_rs1),
        .IDEX_rs2_addr(IDEX_rs2),
        .EXMEM_rd_addr(EXMEM_rd_addr),
        .MEMWB_rd_addr(MEMWB_rd_addr),

        .MEMWBRegWrite(MEMWB_RegWrite),
        .EXMEMRegWrite(IDEX_RegWrite)
    ) ;


    // EXMEM stage signals
    wire [1:0] EXMEM_MemtoReg;
    wire EXMEM_RegWrite;
    wire EXMEM_MemWrite;
    wire EXMEM_MemRead;
    wire EXMEM_MemSize;
    wire [2:0] EXMEM_Branch;
    wire [ADDR_WIDTH-1:0] EXMEM_PC;
    wire [ADDR_WIDTH-1:0] EXMEM_Next_PC;
    wire [DATA_WIDTH-1:0] EXMEM_ALU_result;
    wire [DATA_WIDTH-1:0] EXMEM_rs1_data;
    wire [DATA_WIDTH-1:0] EXMEM_rs2_data;
    wire [4:0] EXMEM_rs1_addr;
    wire [4:0] EXMEM_rs2_addr;
    wire [4:0] EXMEM_rd_addr;
    wire [1:0] EXMEM_flush_and_stall;


    // EXMEM stage module
    EXMEMREG #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) exmem (
        .clk(clk),
        .reset(reset),
        .flush_and_stall(EXMEM_flush_and_stall),
        .MemtoReg(IDEX_MemtoReg),
        .RegWrite(IDEX_RegWrite),
        .MemWrite(IDEX_MemWrite),
        .MemRead(IDEX_MemRead),
        .MemSize(IDEX_MemSize),
        .Branch(IDEX_Branch),
        .PC_in(IDEX_PC),
        .Next_PC_in(EX_next_pc),
        .ALU_result_in(EX_alu_result),
        .rs1_data(IDEX_rdata_a),
        .rs2_data(IDEX_rdata_b),
        .rs1_addr(IDEX_rs1),
        .rs2_addr(IDEX_rs2),
        .rd_addr(IDEX_rd),
        .PC_out(EXMEM_PC),
        .Next_PC_out(EXMEM_Next_PC),
        .ALU_result_out(EXMEM_ALU_result),
        .rs1_data_out(EXMEM_rs1_data),
        .rs2_data_out(EXMEM_rs2_data),
        .rs1_addr_out(EXMEM_rs1_addr),
        .rs2_addr_out(EXMEM_rs2_addr),
        .rd_addr_out(EXMEM_rd_addr),
        .MemtoReg_out(EXMEM_MemtoReg),
        .RegWrite_out(EXMEM_RegWrite),
        .MemWrite_out(EXMEM_MemWrite),
        .MemRead_out(EXMEM_MemRead),
        .MemSize_out(EXMEM_MemSize),
        .Branch_out(EXMEM_Branch)
    );

    // MEM stage signals
    wire MEM_branch_flush;
    wire [ADDR_WIDTH-1:0] MEM_Branch_pc;
    wire MEM_branch;
    wire [31:0] MEM_memory_data;
    wire  MEM_flush_and_stall;


    // MEM stage module
    Branch #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) mem_branch (
        .clk(clk),
        .reset(reset),
        .flush(MEM_branch_flush),
        .branch(EXMEM_Branch),
        .Next_PC(EXMEM_Next_PC),
        .ALU_result(EXMEM_ALU_result),
        .branch_out(MEM_Branch_pc),
        .use_branch(MEM_branch)
    );

    MEMORY #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) mem (
        .clk_i(clk),
        .rst_i(reset),
        .stall_and_flush_out(MEM_flush_and_stall),
        .wb_cyc_o(id_wb_cyc_o),
        .wb_stb_o(id_wb_stb_o),
        .wb_ack_i(id_wb_ack_i),
        .wb_adr_o(id_wb_adr_o),
        .wb_dat_o(id_wb_dat_o),
        .wb_dat_i(id_wb_dat_i),
        .wb_sel_o(id_wb_sel_o),
        .wb_we_o(id_wb_we_o),
        .Mem_size_in(EXMEM_MemSize),
        .Mem_write_in(EXMEM_MemWrite),
        .Mem_Read_in(EXMEM_MemRead),
        .Mem_addr_in(EXMEM_ALU_result),
        .Mem_data_in(EXMEM_rs2_data),
        .Mem_data_out(MEM_memory_data)
    );

    // MEMWB stage signals
    wire [1:0] MEMWB_MemtoReg;
    wire MEMWB_RegWrite;
    wire [ADDR_WIDTH-1:0] MEMWB_PC;
    wire [DATA_WIDTH-1:0] MEMWB_ALU_result;
    wire [DATA_WIDTH-1:0] MEMWB_memory_data;
    wire [4:0] MEMWB_rd_addr;
    wire [1:0] MEMWB_flush_and_stall;

    // MEMWB stage module
    MEMWBREG #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) memwb (
        .clk(clk),
        .reset(reset),
        .flush_and_stall(MEMWB_flush_and_stall),
        .MemtoReg(EXMEM_MemtoReg),
        .RegWrite(EXMEM_RegWrite),
        .PC_in(EXMEM_PC),
        .ALU_result_in(EXMEM_ALU_result),
        .memory_data_in(MEM_memory_data),
        .rd_addr_in(EXMEM_rd_addr),
        .PC_out(MEMWB_PC),
        .ALU_result_out(MEMWB_ALU_result),
        .memory_data_out(MEMWB_memory_data),
        .rd_addr_out(MEMWB_rd_addr),
        .MemtoReg_out(MEMWB_MemtoReg),
        .RegWrite_out(MEMWB_RegWrite)
    );

    // WB stage signals


    // WB stage module
    REG_MUX #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) wb_reg_mux (
        .which_mux(MEMWB_MemtoReg),
        .mem_in(MEMWB_memory_data),
        .alu_in(MEMWB_ALU_result),
        .reg_out(WB_wdata),
        .PC_reg_in(MEMWB_PC)
    );

    // Stall&Flush Controll
    SFCONTROL #(
        .PC_ADDR(32'h8000_0000),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) sfcontrol (
        .IFID_stall_and_flush(IFID_flush_and_stall),
        .IDEX_stall_and_flush(IDEX_flush_and_stall),
        .EXMEM_stall_and_flush(EXMEM_flush_and_stall),
        .MEMWB_stall_and_flush(MEMWB_flush_and_stall),
        .branch(MEM_branch_flush),
        .mem(MEM_flush_and_stall),
        .im(IF_stall_and_flush),
        .hazard(ID_stall_and_flush),
        .PC_stall_and_flush(PC_flush_and_bubble),
        .clk(clk),
        .reset(reset)
    );


endmodule
