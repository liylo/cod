`default_nettype none

module ALU_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire which_mux,  
    input  wire [DATA_WIDTH-1:0] pc_in,  
    input  wire [DATA_WIDTH-1:0] reg_in,
    output wire [DATA_WIDTH-1:0] alu_out
);
    always_comb begin : 
        case(which_mux)
            1'b0: begin
                alu_out = reg_in;
            end
            1'b1: begin
                alu_out = pc_in;
            end
            default: begin
                alu_out = 32'h0;
            end
        endcase
    end
endmodule