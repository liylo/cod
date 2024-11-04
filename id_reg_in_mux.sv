`default_nettype none

module ID_REG_IN_MUX(
    input wire [4:0] read_addr,
    input wire [4:0] write_addr,
    input wire write_enable,

    input wire [31:0] write_data,
    input wire [31:0] read_data,

    output reg [31:0] final_data
);
    always_comb begin
        if (write_enable && write_addr == read_addr) begin
            final_data = write_data;
        end else begin
            final_data = read_data;
        end
    end

endmodule