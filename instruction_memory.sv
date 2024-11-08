`default_nettype none
/*
 * Instruction Memory (IM) module
 *
 * Responsibilities:
 * 1. Fetch instructions from memory using the Wishbone interface.
 * 2. Provide the fetched instruction to the pipeline.
 */

module IM #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire clk,
    input  wire reset,

    input  wire [ADDR_WIDTH-1:0] PC_addr,
    output reg  [DATA_WIDTH-1:0] instruction,

    output wire stall_and_flush,

    // Added flush signal input
    input  wire flush,
    input  wire stall,

    // Wishbone master interface
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input  wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input  wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o,

    // current PC
    output reg [ADDR_WIDTH-1:0] PC_out
);
    // State machine states
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        READ = 2'b01
    } state_t;

    state_t state;

    assign PC_out = wb_adr_o;

    // Sequential logic for state transition and outputs
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            instruction <= {DATA_WIDTH{1'b0}};
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            wb_we_o  <= 1'b0;
            wb_sel_o <= {(DATA_WIDTH/8){1'b0}};
            wb_adr_o <= {ADDR_WIDTH{1'b0}};
            wb_dat_o <= {DATA_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    if (!flush&&!stall) begin
                        wb_cyc_o <= 1'b1;
                        wb_stb_o <= 1'b1;
                        wb_we_o  <= 1'b0;
                        wb_sel_o <= {(DATA_WIDTH/8){1'b1}};
                        wb_adr_o <= PC_addr;
                        state <= READ;
                    end else begin
                        // If flush, remain in IDLE and reset outputs
                        wb_cyc_o <= 1'b0;
                        wb_stb_o <= 1'b0;
                        if (flush) begin
                            instruction <= {DATA_WIDTH{1'b0}};
                        end
                    end
                end
                READ: begin
                    if (flush) begin
                        // If flush occurs during READ, cancel transaction
                        wb_cyc_o <= 1'b0;
                        wb_stb_o <= 1'b0;
                        instruction <= {DATA_WIDTH{1'b0}};
                        state <= IDLE;
                    end else if (wb_ack_i) begin
                        instruction <= wb_dat_i;
                        wb_cyc_o <= 1'b0;
                        wb_stb_o <= 1'b0;
                        state <= IDLE;
                    end
                end
                default: begin
                    // Should not reach here
                    state <= IDLE;
                end
            endcase
        end
    end

    assign stall_and_flush = (state != IDLE);


endmodule
