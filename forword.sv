`default_nettype none

module Forward #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32           // Data width
)(
    output wire [DATA_WIDTH-1:0] Forward_op1,
    output wire [DATA_WIDTH-1:0] Forward_op2,

    input  wire [DATA_WIDTH-1:0] IDEX_rs1_data,
    input  wire [DATA_WIDTH-1:0] IDEX_rs2_data,

    input  wire [DATA_WIDTH-1:0] EXMEM_rd_in,
    input  wire [DATA_WIDTH-1:0] MEMWB_rd_in,

    input  wire MEMWBRegWrite,
    input  wire EXMEMRegWrite
)
endmodule