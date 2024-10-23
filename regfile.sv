`default_nettype none
module regfile(
    input wire clk,
    input wire reset,

    input reg  [4:0]  rf_raddr_a,
    output  wire [31:0] rf_rdata_a,
    input reg  [4:0]  rf_raddr_b,
    output  wire [31:0] rf_rdata_b,
    input reg  [4:0]  rf_waddr,
    input reg  [31:0] rf_wdata,
    input reg  rf_we,
);

logic [31:0] regfile[31:0];

// read part
always_comb begin
    rf_rdata_a = regfile[rf_raddr_a];
    rf_rdata_b = regfile[rf_raddr_b];
end

// write part
always_ff @(posedge clk) begin
    if (reset) begin
        for (int i = 0; i < 32; i++) begin
            regfile[i] <= 0;
        end
        rf_raddr_a <= 0;
        rf_raddr_b <= 0;
    end
    else if (rf_we) begin
        regfile[rf_waddr] <= rf_wdata;
        regfile[0] <= 0;
    end
end


endmodule