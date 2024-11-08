`default_nettype none
/*
 * IFIDREG module for RISC-V pipeline
 *
 * Responsibilities:
 * 1. Store the instruction fetched from instruction memory
 * 2. Handle pipeline stalls and flushes
 */
module IFIDREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    // From PC register
    input wire [ADDR_WIDTH-1:0] PC_addr,
    output reg [ADDR_WIDTH-1:0] PC_out,

    // From Instruction Memory
    input wire [DATA_WIDTH-1:0] im_instruction,
    output reg [DATA_WIDTH-1:0] instruction,

    input wire [1:0] flush_and_stall
);

    // Decode flush and stall signals
    wire stall = flush_and_stall[0];
    wire flush = flush_and_stall[1];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            instruction <= 32'h0000_0000; // NOP instruction
            PC_out <= PC_ADDR;            // Reset PC to initial address
        end else if (flush) begin
            instruction <= 32'h0000_0000; // Flush instruction to NOP
            PC_out <= PC_ADDR;            // Update PC
        end else if (!stall) begin
            instruction <= im_instruction; // Load new instruction
            PC_out <= PC_addr;             // Update PC
        end
        // If stall is asserted, hold the current values (do nothing)
    end

endmodule
