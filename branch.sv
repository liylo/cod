`default_nettype none

/*
 * Branch module for RISC-V pipeline
 *
 * Responsibilities:
 * 1. Calculate branch target address based on branch condition.
 * 2. Generate flush signal to invalidate incorrect pipeline instructions when a branch is taken.
 */
module Branch #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32           // Data width
)(
    input wire clk,                        // Clock signal
    input wire reset,                      // Reset signal

    output reg flush,                      // 1: Flush the pipeline due to branch taken
                                           // 0: Do not flush the pipeline

    input wire branch,                     // 1: Current instruction is a branch
                                           // 0: Current instruction is not a branch

    input wire [DATA_WIDTH-1:0] Next_PC,   // Calculated branch target address
                                           // Relevant when `branch` is 1

    input wire branch_condition_result,    // 1: Branch condition is met (branch taken)
                                           // 0: Branch condition is not met (branch not taken)

    output reg [ADDR_WIDTH-1:0] branch_out, // Branch target address to update PC
    output reg use_branch      
);
    
    // Sequential logic to handle branch decisions
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            flush       <= 1'b0;
            branch_out  <= PC_ADDR;
            use_branch  <= 0;
        end else begin
            if (branch && branch_condition_result) begin
                flush      <= 1'b1;
                branch_out <= Next_PC;
                use_branch <= 1;
            end else begin
                flush      <= 1'b0;
                branch_out <= PC_ADDR;
                use_branch <= 0;
            end
        end
    end

endmodule
