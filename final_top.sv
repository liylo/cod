`default_nettype none

module final_top (
    input wire clk_50M,     
    input wire clk_11M0592, 

    input wire push_btn, 
    input wire reset_btn,  

    input wire [3:0] touch_btn,
    input wire [31:0] dip_sw, 
    output wire [15:0] leds,    
    output wire [7:0] dpy0,  
    output wire [7:0] dpy1,    

   
    output wire uart_rdn,       
    output wire uart_wrn,      
    input wire uart_dataready,  
    input wire uart_tbre,        
    input wire uart_tsre,     

    // BaseRAM signals
    inout wire [31:0] base_ram_data,  
    output wire [19:0] base_ram_addr, 
    output wire [3:0] base_ram_be_n,  
    output wire base_ram_ce_n,       
    output wire base_ram_oe_n,       
    output wire base_ram_we_n,       

    // ExtRAM signals
    inout wire [31:0] ext_ram_data,   
    output wire [19:0] ext_ram_addr,  
    output wire [3:0] ext_ram_be_n,  
    output wire ext_ram_ce_n,        
    output wire ext_ram_oe_n,        
    output wire ext_ram_we_n,        

    // Direct UART signals (unused in this example)
    output wire txd, 
    input wire rxd, 

    // Flash memory signals 
    output wire [22:0] flash_a,
    inout wire [15:0] flash_d,
    output wire flash_rp_n,
    output wire flash_vpen,
    output wire flash_ce_n,
    output wire flash_oe_n,
    output wire flash_we_n,
    output wire flash_byte_n,

    // USB controller signals 
    output wire sl811_a0,
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input wire sl811_intrq,
    input wire sl811_drq_n,

    // Network controller signals 
    output wire dm9k_cmd,
    inout wire [15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,

    // Video output signals
    output wire [2:0] video_red,    
    output wire [2:0] video_green,  
    output wire [1:0] video_blue,  
    output wire video_hsync,        
    output wire video_vsync,        
    output wire video_clk,         
    output wire video_de            
);

 
    // PLL 分频示例
    logic locked, clk_10M, clk_20M;

    pll_example clock_gen (
        .clk_in1(clk_50M),
        .clk_out1(clk_10M),   // Generate system clock
        .clk_out2(clk_20M),  // Generate UART clock
        .reset(reset_btn),
        .locked(locked)
    );

    // Synchronous reset generation
    logic reset_of_clk10M;
    always_ff @(posedge clk_10M or negedge locked)  begin
    if (~locked) reset_of_clk10M <= 1'b1;
    else reset_of_clk10M <= 1'b0;
  end


    logic sys_clk;
    logic sys_rst;

    assign sys_clk = clk_10M;
    assign sys_rst = reset_of_clk10M;

    // 本实验不使用 CPLD 串口，禁用防止总线冲突
    assign uart_rdn = 1'b1;
    assign uart_wrn = 1'b1;

    /* =========== CPU Master Instance =========== */
    // Wishbone master signals for instruction fetch (IF) stage
    wire if_wb_cyc_o;
    wire if_wb_stb_o;
    wire if_wb_ack_i;
    wire [31:0] if_wb_adr_o;
    wire [31:0] if_wb_dat_o;
    wire [31:0] if_wb_dat_i;
    wire [3:0]  if_wb_sel_o;
    wire        if_wb_we_o;

    // Wishbone master signals for data access (ID) stage
    wire id_wb_cyc_o;
    wire id_wb_stb_o;
    wire id_wb_ack_i;
    wire [31:0] id_wb_adr_o;
    wire [31:0] id_wb_dat_o;
    wire [31:0] id_wb_dat_i;
    wire [3:0]  id_wb_sel_o;
    wire        id_wb_we_o;

    // CPU master module instance
    cpu_master #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32)
    ) cpu (
        .clk(sys_clk),
        .reset(sys_rst),

        // Wishbone master interface for instruction fetch (IF)
        .if_wb_cyc_o(if_wb_cyc_o),
        .if_wb_stb_o(if_wb_stb_o),
        .if_wb_ack_i(if_wb_ack_i),
        .if_wb_adr_o(if_wb_adr_o),
        .if_wb_dat_o(if_wb_dat_o),
        .if_wb_dat_i(if_wb_dat_i),
        .if_wb_sel_o(if_wb_sel_o),
        .if_wb_we_o(if_wb_we_o),

        // Wishbone master interface for data access (ID)
        .id_wb_cyc_o(id_wb_cyc_o),
        .id_wb_stb_o(id_wb_stb_o),
        .id_wb_ack_i(id_wb_ack_i),
        .id_wb_adr_o(id_wb_adr_o),
        .id_wb_dat_o(id_wb_dat_o),
        .id_wb_dat_i(id_wb_dat_i),
        .id_wb_sel_o(id_wb_sel_o),
        .id_wb_we_o(id_wb_we_o)
    );

    /* =========== Wishbone Arbiter =========== */
    // Arbiter to manage access between IF and ID stages to the memory bus
    wire [31:0] wbm_adr_o;
    wire [31:0] wbm_dat_o;
    wire [31:0] wbm_dat_i;
    wire [3:0]  wbm_sel_o;
    wire        wbm_we_o;
    wire        wbm_cyc_o;
    wire        wbm_stb_o;
    wire        wbm_ack_i;

    wb_arbiter_2 #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .SELECT_WIDTH(4),
        .ARB_TYPE_ROUND_ROBIN(0),
        .ARB_LSB_HIGH_PRIORITY(1)
    ) arbiter (
        .clk(sys_clk),
        .rst(sys_rst),

        // Master 0 interface (Instruction Fetch)
        .wbm0_adr_i(if_wb_adr_o),
        .wbm0_dat_i(if_wb_dat_o),
        .wbm0_dat_o(if_wb_dat_i),
        .wbm0_we_i(if_wb_we_o),
        .wbm0_sel_i(if_wb_sel_o),
        .wbm0_stb_i(if_wb_stb_o),
        .wbm0_ack_o(if_wb_ack_i),
        .wbm0_err_o(),   // Error signal (unused)
        .wbm0_rty_o(),   // Retry signal (unused)
        .wbm0_cyc_i(if_wb_cyc_o),

        // Master 1 interface (Data Access)
        .wbm1_adr_i(id_wb_adr_o),
        .wbm1_dat_i(id_wb_dat_o),
        .wbm1_dat_o(id_wb_dat_i),
        .wbm1_we_i(id_wb_we_o),
        .wbm1_sel_i(id_wb_sel_o),
        .wbm1_stb_i(id_wb_stb_o),
        .wbm1_ack_o(id_wb_ack_i),
        .wbm1_err_o(),   // Error signal (unused)
        .wbm1_rty_o(),   // Retry signal (unused)
        .wbm1_cyc_i(id_wb_cyc_o),

        // Slave interface to memory controller
        .wbs_adr_o(wbm_adr_o),
        .wbs_dat_i(wbm_dat_i),
        .wbs_dat_o(wbm_dat_o),
        .wbs_we_o(wbm_we_o),
        .wbs_sel_o(wbm_sel_o),
        .wbs_stb_o(wbm_stb_o),
        .wbs_ack_i(wbm_ack_i),
        .wbs_err_i(1'b0), // Error signal (unused)
        .wbs_rty_i(1'b0), // Retry signal (unused)
        .wbs_cyc_o(wbm_cyc_o)
    );

    /* =========== MUX for Memory Controller =========== */
    wire wbs0_cyc_o;
    wire wbs0_stb_o; 
    wire wbs0_ack_i;
    wire [31:0] wbs0_adr_o;
    wire [31:0] wbs0_dat_o;
    wire [31:0] wbs0_dat_i;
    wire [3:0]  wbs0_sel_o;
    wire wbs0_we_o;

    wire wbs1_cyc_o;
    wire wbs1_stb_o;
    wire wbs1_ack_i;
    wire [31:0] wbs1_adr_o;
    wire [31:0] wbs1_dat_o;
    wire [31:0] wbs1_dat_i;
    wire [3:0]  wbs1_sel_o;
    wire wbs1_we_o;

    wire wbs2_cyc_o;
    wire wbs2_stb_o;
    wire wbs2_ack_i;
    wire [31:0] wbs2_adr_o;
    wire [31:0] wbs2_dat_o;
    wire [31:0] wbs2_dat_i;
    wire [3:0]  wbs2_sel_o;
    wire wbs2_we_o;

    wb_mux_3 wb_mux (
        .clk(sys_clk),
        .rst(sys_rst),

        // Master interface (to Lab5 master)
        .wbm_adr_i(wbm_adr_o),
        .wbm_dat_i(wbm_dat_o),
        .wbm_dat_o(wbm_dat_i),
        .wbm_we_i(wbm_we_o),
        .wbm_sel_i(wbm_sel_o),
        .wbm_stb_i(wbm_stb_o),
        .wbm_ack_o(wbm_ack_i),
        .wbm_err_o(),
        .wbm_rty_o(),
        .wbm_cyc_i(wbm_cyc_o),

        // Slave interface 0 (to BaseRAM controller)
        // Address range: 0x8000_0000 ~ 0x803F_FFFF
        .wbs0_addr(32'h8000_0000),
        .wbs0_addr_msk(32'hFFC0_0000),

        .wbs0_adr_o(wbs0_adr_o),
        .wbs0_dat_i(wbs0_dat_i),
        .wbs0_dat_o(wbs0_dat_o),
        .wbs0_we_o(wbs0_we_o),
        .wbs0_sel_o(wbs0_sel_o),
        .wbs0_stb_o(wbs0_stb_o),
        .wbs0_ack_i(wbs0_ack_i),
        .wbs0_err_i('0),
        .wbs0_rty_i('0),
        .wbs0_cyc_o(wbs0_cyc_o),

        // Slave interface 1 (to ExtRAM controller)
        // Address range: 0x8040_0000 ~ 0x807F_FFFF
        .wbs1_addr(32'h8040_0000),
        .wbs1_addr_msk(32'hFFC0_0000),

        .wbs1_adr_o(wbs1_adr_o),
        .wbs1_dat_i(wbs1_dat_i),
        .wbs1_dat_o(wbs1_dat_o),
        .wbs1_we_o(wbs1_we_o),
        .wbs1_sel_o(wbs1_sel_o),
        .wbs1_stb_o(wbs1_stb_o),
        .wbs1_ack_i(wbs1_ack_i),
        .wbs1_err_i('0),
        .wbs1_rty_i('0),
        .wbs1_cyc_o(wbs1_cyc_o),

        // Slave interface 2 (to UART controller)
        // Address range: 0x1000_0000 ~ 0x1000_FFFF
        .wbs2_addr(32'h1000_0000),
        .wbs2_addr_msk(32'hFFFF_0000),

        .wbs2_adr_o(wbs2_adr_o),
        .wbs2_dat_i(wbs2_dat_i),
        .wbs2_dat_o(wbs2_dat_o),
        .wbs2_we_o(wbs2_we_o),
        .wbs2_sel_o(wbs2_sel_o),
        .wbs2_stb_o(wbs2_stb_o),
        .wbs2_ack_i(wbs2_ack_i),
        .wbs2_err_i('0),
        .wbs2_rty_i('0),
        .wbs2_cyc_o(wbs2_cyc_o)
    );

    /* =========== Lab5 MUX end =========== */

    /* =========== Lab5 Slaves begin =========== */
    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_base (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs0_cyc_o),
        .wb_stb_i(wbs0_stb_o),
        .wb_ack_o(wbs0_ack_i),
        .wb_adr_i(wbs0_adr_o),
        .wb_dat_i(wbs0_dat_o),
        .wb_dat_o(wbs0_dat_i),
        .wb_sel_i(wbs0_sel_o),
        .wb_we_i(wbs0_we_o),

        // To SRAM chip
        .sram_addr(base_ram_addr),
        .sram_data(base_ram_data),
        .sram_ce_n(base_ram_ce_n),
        .sram_oe_n(base_ram_oe_n),
        .sram_we_n(base_ram_we_n),
        .sram_be_n(base_ram_be_n)
    );

    sram_controller #(
        .SRAM_ADDR_WIDTH(20),
        .SRAM_DATA_WIDTH(32)
    ) sram_controller_ext (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        // Wishbone slave (to MUX)
        .wb_cyc_i(wbs1_cyc_o),
        .wb_stb_i(wbs1_stb_o),
        .wb_ack_o(wbs1_ack_i),
        .wb_adr_i(wbs1_adr_o),
        .wb_dat_i(wbs1_dat_o),
        .wb_dat_o(wbs1_dat_i),
        .wb_sel_i(wbs1_sel_o),
        .wb_we_i(wbs1_we_o),

        // To SRAM chip
        .sram_addr(ext_ram_addr),
        .sram_data(ext_ram_data),
        .sram_ce_n(ext_ram_ce_n),
        .sram_oe_n(ext_ram_oe_n),
        .sram_we_n(ext_ram_we_n),
        .sram_be_n(ext_ram_be_n)
    );

    // UART controller module
    uart_controller #(
        .CLK_FREQ(10_000_000),
        .BAUD(115200)
    ) uart_controller (
        .clk_i(sys_clk),
        .rst_i(sys_rst),

        .wb_cyc_i(wbs2_cyc_o),
        .wb_stb_i(wbs2_stb_o),
        .wb_ack_o(wbs2_ack_i),
        .wb_adr_i(wbs2_adr_o),
        .wb_dat_i(wbs2_dat_o),
        .wb_dat_o(wbs2_dat_i),
        .wb_sel_i(wbs2_sel_o),
        .wb_we_i(wbs2_we_o),

        // to UART pins
        .uart_txd_o(txd),
        .uart_rxd_i(rxd)
    );
    
endmodule
