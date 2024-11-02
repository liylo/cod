module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,  // 低电平有效
    output reg sram_oe_n,  // 使能输出，读为 0，写为 1
    output reg sram_we_n,  // 使能写，写为 0，读为 1
    output reg [SRAM_BYTES-1:0] sram_be_n
);

  // DID: 实现 SRAM 控制器
  // 状态机状态定义
  typedef enum logic [2:0] {
    STATE_IDLE = 0,
    STATE_READ = 1,
    STATE_READ_2 = 2,
    STATE_WRITE = 3,
    STATE_WRITE_2 = 4,
    STATE_WRITE_3 = 5,
    STATE_DONE = 6
  } state_t;

  state_t state;  // 状态机状态

  // 定义内部信号
  reg [SRAM_DATA_WIDTH-1:0] sram_data_o_reg;
  wire [SRAM_DATA_WIDTH-1:0] sram_data_i_comb;
  reg sram_data_t_reg;

  assign sram_data = sram_data_t_reg ? {SRAM_DATA_WIDTH{1'bz}} : sram_data_o_reg;
  assign sram_data_i_comb = sram_data;


  always_ff @(posedge clk_i) begin  // 时序逻辑
    if (rst_i) begin
      wb_ack_o <= 0;
      state <= STATE_IDLE;
      sram_ce_n <= 1'b1;
      sram_oe_n <= 1'b1;
      sram_we_n <= 1'b1;
      // high-Z when reset
      sram_data_t_reg <= 1'b1;
      sram_data_o_reg <= {SRAM_DATA_WIDTH{1'b0}};
    end else begin
      case (state)
        STATE_IDLE: begin
          if (wb_stb_i && wb_cyc_i) begin
            if (wb_we_i) begin  // 写操作
              sram_data_t_reg <= 1'b0;
              sram_data_o_reg <= wb_dat_i;
              sram_ce_n <= 0;  // 内存结束休眠
              sram_oe_n <= 1;  // 禁止输出
              sram_we_n <= 1;  // 禁止写
              sram_addr <= wb_adr_i[SRAM_ADDR_WIDTH+1:2];
              sram_be_n <= ~wb_sel_i;
              state <= STATE_WRITE;
            end else begin
              sram_data_t_reg <= 1'b1;
              sram_ce_n <= 0;  // 内存结束休眠
              sram_oe_n <= 0;  // 使能输出
              sram_we_n <= 1;  // 禁止写
              sram_addr <= wb_adr_i[SRAM_ADDR_WIDTH+1:2];
              // sram_be_n 应该是 SEL_I 的反转
              sram_be_n <= ~wb_sel_i;
              state <= STATE_READ;
            end
          end
        end
        STATE_READ: begin 
        end
        STATE_READ_2: begin
            wb_ack_o <= 1;  // 使能应答
            sram_oe_n <= 1;  // 禁止输出
            sram_ce_n <= 1;  // 使能内存
            state <= STATE_DONE;
        end
        STATE_DONE: begin
          wb_ack_o <= 0;  // 禁止应答
          sram_data_t_reg <= 1'b1;
          state <= STATE_IDLE;
        end
        STATE_WRITE: begin
          sram_we_n <= 0;  // 使能写
          state <= STATE_WRITE_2;
        end
        STATE_WRITE_2: begin
          sram_we_n <= 1;  // 禁止写
          state <= STATE_WRITE_3;
        end
        STATE_WRITE_3: begin
          sram_ce_n <= 1;  // 使能内存
          wb_ack_o <= 1;  // 使能应答
          state <= STATE_DONE;
        end
        default: begin
          state <= STATE_IDLE;
        end
      endcase
    end
  end
endmodule
