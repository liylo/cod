`default_nettype none

module REG_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire which_mux,  
    input  wire [DATA_WIDTH/8-1:0] rs2_addr,  
    input  wire [DATA_WIDTH/8-1:0] rd_addr,
    output wire [DATA_WIDTH-1:0] reg_out
);
    always_comb begin : 
        case(which_mux)
            1'b0: begin
                reg_out = rd_addr;
            end
            1'b1: begin
                reg_out = rs2_addr;
            end
        endcase
    end
endmodule