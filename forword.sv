`default_nettype none
//TODO: update map
module Forward #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,         // Address width
    parameter DATA_WIDTH = 32          // Data width
)(
    output wire [DATA_WIDTH-1:0] Forward_op1,
    output wire [DATA_WIDTH-1:0] Forward_op2,

    input  wire [DATA_WIDTH-1:0] IDEX_rs1_data,
    input  wire [DATA_WIDTH-1:0] IDEX_rs2_data,
    input  wire [4:0] IDEX_rs1_addr, 
    input  wire [4:0] IDEX_rs2_addr, 

    input  wire [DATA_WIDTH-1:0] EXMEM_rd_data, 
    input  wire [4:0] EXMEM_rd_addr,            

    input  wire [DATA_WIDTH-1:0] MEMWB_rd_data, 
    input  wire [4:0] MEMWB_rd_addr,           

    // Control signals
    input  wire MEMWBRegWrite,
    input  wire EXMEMRegWrite
);
    always_comb begin : 
    Forward_op1 = (EXMEMRegWrite && (EXMEM_rd_addr != 0) && (EXMEM_rd_addr == IDEX_rs1_addr)) ? EXMEM_rd_data :
                         (MEMWBRegWrite && (MEMWB_rd_addr != 0) && (MEMWB_rd_addr == IDEX_rs1_addr)) ? MEMWB_rd_data :
                         IDEX_rs1_data;

    Forward_op2 = (EXMEMRegWrite && (EXMEM_rd_addr != 0) && (EXMEM_rd_addr == IDEX_rs2_addr)) ? EXMEM_rd_data :
                         (MEMWBRegWrite && (MEMWB_rd_addr != 0) && (MEMWB_rd_addr == IDEX_rs2_addr)) ? MEMWB_rd_data :
                         IDEX_rs2_data;
    end
endmodule
