`default_nettype none
//TODO: update map
module Forward #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,         // Address width
    parameter DATA_WIDTH = 32          // Data width
)(
    output reg [1:0] Forward_op1,
    output reg [1:0] Forward_op2,

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
    always_comb begin
        Forward_op1 = 2'b00; // Default: no forwarding
        Forward_op2 = 2'b00; // Default: no forwarding

        // Forwarding from EX/MEM stage
        if (EXMEMRegWrite && (IDEX_rs1_addr != 5'b00000) && (IDEX_rs1_addr == EXMEM_rd_addr)) begin
            Forward_op1 = 2'b01; // Forward from EX/MEM
        end
        if (EXMEMRegWrite && (IDEX_rs2_addr != 5'b00000) && (IDEX_rs2_addr == EXMEM_rd_addr)) begin
            Forward_op2 = 2'b01; // Forward from EX/MEM
        end

        // Forwarding from MEM/WB stage
        if (MEMWBRegWrite && (IDEX_rs1_addr != 5'b00000) && (IDEX_rs1_addr == MEMWB_rd_addr)) begin
            Forward_op1 = 2'b10; // Forward from MEM/WB
        end
        if (MEMWBRegWrite && (IDEX_rs2_addr != 5'b00000) && (IDEX_rs2_addr == MEMWB_rd_addr)) begin
            Forward_op2 = 2'b10; // Forward from MEM/WB
        end
    end
endmodule
