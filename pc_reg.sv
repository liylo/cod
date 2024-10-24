`default_nettype none

/*
 * PC_REG module for RISC-V pipeline
 *
 * Responsibilities:
 * 1. Hold the current Program Counter (PC) value
 * 2. Handle pipeline stalls and flushes
 */
module PC_REG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32
)
(
    input  wire clk,
    input  wire reset,
    input  wire [ADDR_WIDTH-1:0] PC_new_reg_in,
    input  wire [1:0] stall_and_flush,
    output reg  [ADDR_WIDTH-1:0] PC_reg_out
);

    reg [ADDR_WIDTH-1:0] pc_reg;

    // Decode stall and flush signals
    wire stall = stall_and_flush[0];
    wire flush = stall_and_flush[1];

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= PC_ADDR;         // Reset PC to initial address
        end else if (flush) begin
            pc_reg <= PC_ADDR;         // On flush, reset PC to initial address
        end else if (!stall) begin
            pc_reg <= PC_new_reg_in;   // Update PC with new value
        end
        // If stall is asserted, hold the current PC value
    end

    // Output the current PC value
    always_comb begin
        PC_reg_out = pc_reg;
    end

endmodule
