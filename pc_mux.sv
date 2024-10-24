`default_nettype none

module PC_MUX #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire [ADDR_WIDTH-1:0] PC_reg_in,  
    input  wire [ADDR_WIDTH-1:0] Branch_in,
    // 1 from branch, 0 from PC + 4
    input  wire is_branch,  
    output wire [ADDR_WIDTH-1:0] PC_out
);
    always_comb begin : 
        if (is_branch != 0) begin
            PC_out = Branch_in;
        end
        else begin
            PC_out = PC_reg_in;
        end
    end
endmodule