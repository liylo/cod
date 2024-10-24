`default_nettype none

module (module_name) #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32           // Data width
)(
    output wire [1:0] IFID_stall_and_flush,
    output wire [1:0] IDEX_stall_and_flush,
    output wire [1:0] EXMEM_stall_and_flush,
    output wire [1:0] MEMWB_stall_and_flush,
    output wire [1:0] PC_stall_and_flush,

    input  wire branch,
    input  wire mem,
    input  wire im,
    input  wire hazard
)

endmodule