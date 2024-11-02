`default_nettype none

/*
 * EXMEMREG module for RISC-V pipeline
 *
 * Responsibilities:
 * 1. Store control and data signals from EX stage to MEM stage
 * 2. Handle pipeline stalls and flushes
 */
module MEMWBREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Clock and reset signals
    input wire clk,
    input wire reset,
    
    // Control signals for flush and stall
    input wire [1:0] flush_and_stall, // flush_and_stall[1]: flush, flush_and_stall[0]: stall
    
    // Inputs from EX/MEM pipeline register
    input wire MemtoReg,
    input wire RegWrite,
    input wire [ADDR_WIDTH-1:0] PC_in,
    input wire [DATA_WIDTH-1:0] ALU_result_in,
    input wire [DATA_WIDTH-1:0] memory_data_in,
    input wire [4:0] rd_addr_in,
    input wire [4:0] waddr_in,
    
    // Outputs to WB stage
    output reg [ADDR_WIDTH-1:0] PC_out,
    output reg [DATA_WIDTH-1:0] ALU_result_out,
    output reg [DATA_WIDTH-1:0] memory_data_out,
    output reg [4:0] rd_addr_out,
    output reg [4:0] waddr_out,
    output reg MemtoReg_out,
    output reg RegWrite_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // On reset, set outputs to default values
            PC_out           <= PC_ADDR;
            ALU_result_out   <= {DATA_WIDTH{1'b0}};
            memory_data_out  <= {DATA_WIDTH{1'b0}};
            rd_addr_out      <= 5'b0;
            waddr_out        <= 5'b0;
            MemtoReg_out     <= 1'b0;
            RegWrite_out     <= 1'b0;
        end else if (flush_and_stall[1]) begin
            // Flush: set outputs to NOP/bubble values
            PC_out           <= PC_ADDR;
            ALU_result_out   <= {DATA_WIDTH{1'b0}};
            memory_data_out  <= {DATA_WIDTH{1'b0}};
            rd_addr_out      <= 5'b0;
            waddr_out        <= 5'b0;
            MemtoReg_out     <= 1'b0;
            RegWrite_out     <= 1'b0;
        end else if (flush_and_stall[0]) begin
            // Stall: outputs retain their previous values (do nothing)
            // No assignment needed; registers hold their values
        end else begin
            // Normal operation: update outputs with inputs
            PC_out           <= PC_in;
            ALU_result_out   <= ALU_result_in;
            memory_data_out  <= memory_data_in;
            rd_addr_out      <= rd_addr_in;
            waddr_out        <= waddr_in;
            MemtoReg_out     <= MemtoReg;
            RegWrite_out     <= RegWrite;
        end
    end

endmodule
