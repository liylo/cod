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

        // Determine flush signals
        // if (branch) begin
        //     PC_stall_and_flush[1] = 1'b1; // Flush
        //     IFID_stall_and_flush[1] = 1'b1; // Flush
        //     IDEX_stall_and_flush[1] = 1'b1; // Flush
        // end

        // Determine stall signals
        if (hazard) begin
            PC_stall_and_flush[0] = 1'b1; // Stall
            IFID_stall_and_flush[0] = 1'b1; // Stall
            IDEX_stall_and_flush[0] = 1'b1; // Stall
        end else if (mem) begin
            PC_stall_and_flush[0] = 1'b1; // Stall
            IFID_stall_and_flush[0] = 1'b1; // Stall
            IDEX_stall_and_flush[0] = 1'b1; // Stall
            EXMEM_stall_and_flush[0] = 1'b1; // Stall
            MEMWB_stall_and_flush[0] = 1'b1; // Stall
        end else if (im) begin
            // if (prev_mem && !mem) begin // Using prev_mem to detect falling edge
            //     PC_stall_and_flush[0] = 1'b1; // Stall
            //     IFID_stall_and_flush[0] = 1'b1; // Stall
            //     IDEX_stall_and_flush[0] = 1'b1; // Stall
            //     EXMEM_stall_and_flush[0] = 1'b1; // Stall
            //     MEMWB_stall_and_flush[0] = 1'b1; // Stall
            // end else begin
                PC_stall_and_flush[0] = 1'b1; // Stall
                IFID_stall_and_flush[0] = 1'b1; // Stall
                IDEX_stall_and_flush[0] = 1'b1; // Stall
                EXMEM_stall_and_flush[0] = 1'b1; // Stall
                MEMWB_stall_and_flush[0] = 1'b1; // Stall
            // end
        end else if(branch) begin
            PC_stall_and_flush[1] = 1'b1; // Flush
            IFID_stall_and_flush[1] = 1'b1; // Flush
            IDEX_stall_and_flush[1] = 1'b1; // Flush
        end
    end
endmodule
