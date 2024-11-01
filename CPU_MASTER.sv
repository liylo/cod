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
    wire [1:0] IFID_flush_and_bubble;

    // IFID module
    IFIDREG #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) ifid (
        .clk(clk),
        .reset(reset),
        .PC_addr(IF_PC_reg),
        .im_instruction(IF_instr),
        .flush_and_bubble(IFID_flush_and_bubble),
        .PC_out(IFID_PC),
        .instruction(IFID_instr)
    );

    // ID stage signals



endmodule
