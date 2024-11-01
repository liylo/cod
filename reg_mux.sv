`default_nettype none

module REG_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire [1:0] which_mux,  
    input  wire [DATA_WIDTH-1:0] PC_reg_in,  
    input  wire [DATA_WIDTH-1:0] alu_in,
    input  wire [DATA_WIDTH-1:0] mem_in,
    output reg [DATA_WIDTH-1:0] reg_out
);
    always_comb begin
        case(which_mux) 
            2'b00: begin
                reg_out = PC_reg_in;
            end
            2'b01: begin
                reg_out = alu_in;
            end
            2'b10: begin
                reg_out = mem_in;
            end
            default: begin
                reg_out = 32'h0;
            end
        endcase
    end
endmodule