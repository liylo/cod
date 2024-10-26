`default_nettype none
/*
    stall_and_flush[0] = stall, stall_and_flush[1] = flush;
*/
module SFCONTROL #(
    parameter PC_ADDR = 32'h8000_0000, // Initial PC address
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32           // Data width
)(
    output wire [1:0] IFID_stall_and_flush,
    output wire [1:0] IDEX_stall_and_flush,
    output wire [1:0] EXMEM_stall_and_flush,
    output wire [1:0] MEMWB_stall_and_flush,
    output wire [1:0] PC_stall_and_flush,

    input  wire branch,
    input  wire mem,
    input  wire im,
    input  wire hazard
)
    wire prev_mem;
    initial begin
        prev_mem = 1'b0;
    end
    always_comb begin
        IFID_stall_and_flush = 2'b00;
        IDEX_stall_and_flush = 2'b00;
        EXMEM_stall_and_flush = 2'b00;
        MEMWB_stall_and_flush = 2'b00;
        PC_stall_and_flush = 2'b00;

        // 往 IFID IDEX 发出 flush 信号
        if (branch) begin
            IFID_stall_and_flush = 2'b10;
            IDEX_stall_and_flush = 2'b10;
        end

        if (im) begin
           if (prev_mem&(!mem)) begin
                IFID_stall_and_flush = {IFID_stall_and_flush[1],1'b1};
                IDEX_stall_and_flush = {IDEX_stall_and_flush[1],1'b1};
                EXMEM_stall_and_flush = {EXMEM_stall_and_flush[1],1'b1};
                prev_mem = 1'b0;
           end
           else begin
                IFID_stall_and_flush = {IFID_stall_and_flush[1],1'b1};
           end
        end

        // 在 datamem 有阻塞信号的时候把 IFID/IDEX/EXMEM 全 stall 了
        if (mem) begin
            IFID_stall_and_flush = {IFID_stall_and_flush[1],1'b1};
            IDEX_stall_and_flush = {IDEX_stall_and_flush[1],1'b1};
            EXMEM_stall_and_flush = {EXMEM_stall_and_flush[1],1'b1};
            prev_mem = 1'b1;
        end

        if (hazard) begin
            IFID_stall_and_flush = {IFID_stall_and_flush[1],1'b1};
            IDEX_stall_and_flush = {IDEX_stall_and_flush[1],1'b1};
            EXMEM_stall_and_flush = {EXMEM_stall_and_flush[1],1'b1};
            MEMWB_stall_and_flush = {MEMWB_stall_and_flush[1],1'b1};
        end
    end
endmodule