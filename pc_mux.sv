`default_nettype none
//TODO: Confirm PC_reg_in
module PC_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire MemtoReg,
    input  wire PCtoReg,
    input  wire [DATA_WIDTH-1:0] ALU_result_in,  
    input  wire [DATA_WIDTH-1:0] mem_in,
    input  wire [ADDR_WIDTH-1:0] PC_reg_in,
    output wire [ADDR_WIDTH-1:0] PC_out
);
    always_comb begin
        PC_out = (MemtoReg) ? mem_in :   // Priority 1: MEM forwarding
                     (PCtoReg) ? PC_reg_in : ALU_result_in;   // Priority 2: ALU forwarding
    end
endmodule