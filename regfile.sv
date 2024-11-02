`default_nettype none
module regfile(
    input wire clk,
    input wire reset,

    input wire  [4:0]  rf_raddr_a,
    output  reg [31:0] rf_rdata_a,
    input wire  [4:0]  rf_raddr_b,
    output  reg [31:0] rf_rdata_b,
    input wire  [4:0]  rf_waddr,
    input wire  [31:0] rf_wdata,
    input wire  rf_we
);

logic [31:0] regfile[31:0];

// read part
always_comb begin
    rf_rdata_a = (rf_raddr_a == 0) ? 0 : regfile[rf_raddr_a];
    rf_rdata_b = (rf_raddr_b == 0) ? 0 : regfile[rf_raddr_b];
end

// write part
always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 32; i++) begin
            regfile[i] <= 0;
        end
    end
    else if (rf_we && rf_waddr != 0) begin
        regfile[rf_waddr] <= rf_wdata;
    end
end



endmodule