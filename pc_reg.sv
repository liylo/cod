`default_nettype none

module PC_REG #(
    parameter PC_ADDR = 32'h8000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input  wire [ADDR_WIDTH-1:0] PC_new_reg_in,  
    input  wire [1:0] stall_and_flush,
    output wire [ADDR_WIDTH-1:0] PC_reg_out,
);
    reg [ADDR_WIDTH-1:0] pc_reg;

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
                default: pc_reg <= pc_reg;
            endcase
            cur_state <= next_state;
        end
    end

endmodule