`default_nettype none
/*
    * IFIDREG module
    * 
    * This module is responsible for the following:
    * 1. "Store" the instruction fetched from the instruction memory
    * 2. Stalling the pipeline
    * 3. Flushing the pipeline, means write 0 or so
    * 
    * Inputs:
    * 1. clk: clock signal
    * 2. reset: reset signal
    * 3. PC_addr: Program Counter address
    * 4. flush_and_stall: 2-bit signal to indicate whether to stall or flush the pipeline
    * 
    * Outputs:
    * 1. PC_out: Program Counter output
    * 2. instruction: instruction fetched from the instruction memory
    * 
    * Parameters:
    * 1. PC_ADDR: Program Counter address
    * 2. ADDR_WIDTH: Address width
    * 3. DATA_WIDTH: Data width
    *
*/
module IFIDREG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    //from pc_reg
    input wire [ADDR_WIDTH-1:0] PC_addr,
    output wire [ADDR_WIDTH-1:0] PC_out,

    // from IM
    output wire [ADDR_WIDTH-1:0] instruction,

    input wire [1:0] flush_and_stall,
    
);
    typedef enum logic [1:0] {  
        FETCH = 2'b00,
        STALL = 2'b01,
        FLUSH = 2'b10,
    } state_t;

    state_t cur_state;

    state_t next_state;

    always_comb begin : 
        case(flush_and_stall)
            STALL: next_state = STALL;
            FLUSH: next_state = FLUSH;
            default: next_state = FETCH;
        endcase
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cur_state <= FETCH;
        end else begin
            case(cur_state)
                FETCH: cur_state <= (flush_and_stall == STALL) ? STALL : FETCH;
                // replace instruction with read 0
                FLUSH: begin
                    instruction <= 32'h0000_0000; //TODO: replace with read 0
                    PC_out <= PC_addr; // whatever the PC was, keep it
                end
                default: instruction <= instruction;
            endcase
            cur_state <= next_state;
        end
    end

endmodule