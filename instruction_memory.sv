`default_nettype none
// instrcution memory, physically stored in SRAM, 
// use wishbone interface, essentially a wrapper
module IM #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input wire clk,
    input wire reset,

    input wire [ADDR_WIDTH-1:0] PC_addr,
    output wire [ADDR_WIDTH-1:0] instruction,

    input wire flush,

    // Wishbone master interface
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

typedef enum logic [1:0] {
    IDLE,
    READ,
} state_t;

state_t state;

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        case(state)
            IDLE: begin
                rf_we <= 1'b0;
                wb_cyc_o <= 1'b1;
                wb_stb_o <= 1'b1;
                wb_we_o <= 1'b0; 
                wb_sel_o <= 4'b1111;
                wb_adr_o <= pc_reg;
                state <= READ;
            end
            READ: begin
                if (wb_ack_i) begin
                    // Instruction fetched
                    wb_cyc_o <= 1'b0;
                    wb_stb_o <= 1'b0;
                    instruction <= wb_dat_i;
                    cur_state <= IDLE;
                end
            end
        endcase
    end
end


endmodule