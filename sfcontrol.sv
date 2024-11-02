`default_nettype none
/*
    stall_and_flush[0] = stall, stall_and_flush[1] = flush;
*/
module SFCONTROL #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,         // Address width
    parameter DATA_WIDTH = 32          // Data width
)(
    output reg [1:0] IFID_stall_and_flush,
    output reg [1:0] IDEX_stall_and_flush,
    output reg [1:0] EXMEM_stall_and_flush,
    output reg [1:0] MEMWB_stall_and_flush,
    output reg [1:0] PC_stall_and_flush,

    input wire clk,
    input wire reset,

    input wire branch,
    input wire mem,
    input wire im,
    input wire hazard
);

    reg prev_mem;
    wire mem_falling_edge;

    // Detect falling edge of 'mem' signal
    assign mem_falling_edge = prev_mem && (!mem);

    // Sequential logic to update 'prev_mem'
    always @(posedge clk or posedge reset) begin
        if (reset)
            prev_mem <= 1'b0;
        else
            prev_mem <= mem;
    end

    // Combinational logic for stall and flush signals
    always @* begin
        // Default values
        IFID_stall_and_flush = 2'b00;
        IDEX_stall_and_flush = 2'b00;
        EXMEM_stall_and_flush = 2'b00;
        MEMWB_stall_and_flush = 2'b00;
        PC_stall_and_flush = 2'b00;

        // Flush signals for branch instructions
        if (branch) begin
            IFID_stall_and_flush[1] = 1'b1; // Flush
            IDEX_stall_and_flush[1] = 1'b1; // Flush
        end

        // Handle 'im' signal with previous 'mem' status
        if (im) begin
            if (mem_falling_edge) begin
                // Stall IFID, IDEX, EXMEM stages
                IFID_stall_and_flush[0] = 1'b1; // Stall
                IDEX_stall_and_flush[0] = 1'b1; // Stall
                EXMEM_stall_and_flush[0] = 1'b1; // Stall
            end else begin
                // Stall IFID stage only
                IFID_stall_and_flush[0] = 1'b1; // Stall
            end
        end

        // Stall signals when 'mem' is asserted
        if (mem) begin
            // Stall IFID, IDEX, EXMEM stages
            IFID_stall_and_flush[0] = 1'b1; // Stall
            IDEX_stall_and_flush[0] = 1'b1; // Stall
            EXMEM_stall_and_flush[0] = 1'b1; // Stall
        end

        // Stall signals for hazard detection
        if (hazard) begin
            // Stall IFID, IDEX, EXMEM, MEMWB stages
            IFID_stall_and_flush[0] = 1'b1; // Stall
            IDEX_stall_and_flush[0] = 1'b1; // Stall
            EXMEM_stall_and_flush[0] = 1'b1; // Stall
            MEMWB_stall_and_flush[0] = 1'b1; // Stall
        end
    end
endmodule
