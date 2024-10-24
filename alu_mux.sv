`default_nettype none
// ALU_MUX Module
// This module selects the appropriate data source for the ALU based on forwarding signals and a secondary mux control.
module ALU_MUX #(
    parameter PC_ADDR    = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    // Forwarding inputs with higher priority
    input  wire [1:0]               forward,      
    input  wire [DATA_WIDTH-1:0]    exmem_data,  
    input  wire [DATA_WIDTH-1:0]    memwb_data,  

    input  wire                     which_mux,    
    input  wire [DATA_WIDTH-1:0]    pc_in,        
    input  wire [DATA_WIDTH-1:0]    reg_in,      

    output wire [DATA_WIDTH-1:0]    alu_mux_out   
);
    always_comb begin
        alu_mux_out = (forward == 2'b01) ? exmem_data :   // Priority 1: EX/MEM forwarding
                         (forward == 2'b10) ? memwb_data :   // Priority 2: MEM/WB forwarding
                         (which_mux) ? pc_in : reg_in; 
    end   
endmodule