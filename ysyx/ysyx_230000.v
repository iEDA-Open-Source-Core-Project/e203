
module ysyx_230000 (
  input          clock,
  input          reset,
  input          io_master_arready,
  output         io_master_arvalid,
  output [31:0]  io_master_araddr,
  output [3:0]   io_master_arid,
  output [7:0]   io_master_arlen,
  output [2:0]   io_master_arsize,
  output [1:0]   io_master_arburst,
  output         io_master_rready,
  input          io_master_rvalid,
  input  [1:0]   io_master_rresp,
  input  [63:0]  io_master_rdata,
  input          io_master_rlast,
  input  [3:0]   io_master_rid,
  input          io_master_awready,
  output         io_master_awvalid,
  output [31:0]  io_master_awaddr,
  output [3:0]   io_master_awid,
  output [7:0]   io_master_awlen,
  output [2:0]   io_master_awsize,
  output [1:0]   io_master_awburst,
  input          io_master_wready,
  output         io_master_wvalid,
  output [63:0]  io_master_wdata,
  output [7:0]   io_master_wstrb,
  output         io_master_wlast,
  output         io_master_bready,
  input          io_master_bvalid,
  input  [1:0]   io_master_bresp,
  input  [3:0]   io_master_bid,
  output         io_slave_arready,
  input          io_slave_arvalid,
  input  [31:0]  io_slave_araddr,
  input  [3:0]   io_slave_arid,
  input  [7:0]   io_slave_arlen,
  input  [2:0]   io_slave_arsize,
  input  [1:0]   io_slave_arburst,
  input          io_slave_rready,
  output         io_slave_rvalid,
  output [1:0]   io_slave_rresp,
  output [63:0]  io_slave_rdata,
  output         io_slave_rlast,
  output [3:0]   io_slave_rid,
  output         io_slave_awready,
  input          io_slave_awvalid,
  input  [31:0]  io_slave_awaddr,
  input  [3:0]   io_slave_awid,
  input  [7:0]   io_slave_awlen,
  input  [2:0]   io_slave_awsize,
  input  [1:0]   io_slave_awburst,
  output         io_slave_wready,
  input          io_slave_wvalid,
  input  [63:0]  io_slave_wdata,
  input  [7:0]   io_slave_wstrb,
  input          io_slave_wlast,
  input          io_slave_bready,
  output         io_slave_bvalid,
  output [1:0]   io_slave_bresp,
  output [3:0]   io_slave_bid,
  input          io_interrupt,
  output [5:0]   io_sram0_addr,
  output         io_sram0_cen,
  output         io_sram0_wen,
  output [127:0] io_sram0_wmask,
  output [127:0] io_sram0_wdata,
  input  [127:0] io_sram0_rdata,
  output [5:0]   io_sram1_addr,
  output         io_sram1_cen,
  output         io_sram1_wen,
  output [127:0] io_sram1_wmask,
  output [127:0] io_sram1_wdata,
  input  [127:0] io_sram1_rdata,
  output [5:0]   io_sram2_addr,
  output         io_sram2_cen,
  output         io_sram2_wen,
  output [127:0] io_sram2_wmask,
  output [127:0] io_sram2_wdata,
  input  [127:0] io_sram2_rdata,
  output [5:0]   io_sram3_addr,
  output         io_sram3_cen,
  output         io_sram3_wen,
  output [127:0] io_sram3_wmask,
  output [127:0] io_sram3_wdata,
  input  [127:0] io_sram3_rdata,
  output [5:0]   io_sram4_addr,
  output         io_sram4_cen,
  output         io_sram4_wen,
  output [127:0] io_sram4_wmask,
  output [127:0] io_sram4_wdata,
  input  [127:0] io_sram4_rdata,
  output [5:0]   io_sram5_addr,
  output         io_sram5_cen,
  output         io_sram5_wen,
  output [127:0] io_sram5_wmask,
  output [127:0] io_sram5_wdata,
  input  [127:0] io_sram5_rdata,
  output [5:0]   io_sram6_addr,
  output         io_sram6_cen,
  output         io_sram6_wen,
  output [127:0] io_sram6_wmask,
  output [127:0] io_sram6_wdata,
  input  [127:0] io_sram6_rdata,
  output [5:0]   io_sram7_addr,
  output         io_sram7_cen,
  output         io_sram7_wen,
  output [127:0] io_sram7_wmask,
  output [127:0] io_sram7_wdata,
  input  [127:0] io_sram7_rdata
);

  assign io_slave_awready = 0;
  assign io_slave_wready = 0;
  assign io_slave_bvalid = 0;
  assign io_slave_bresp = 0;
  assign io_slave_bid = 0;
  assign io_slave_arready = 0;
  assign io_slave_rvalid = 0;
  assign io_slave_rresp = 0;
  assign io_slave_rdata = 0;
  assign io_slave_rlast = 0;
  assign io_slave_rid = 0;


  wire jtag_TDI = 1'b0;
  wire jtag_TDO;
  wire jtag_TCK = 1'b0;
  wire jtag_TMS = 1'b0;
  wire jtag_TRST = 1'b0;

  wire jtag_DRV_TDO = 1'b0;
  wire hfclk = clock;
  wire lfextclk = clock;
  wire rst_n = !reset;


e203_soc_top u_e203_soc_top(
  .hfextclk(hfclk),

  .hfxoscen(),
  .lfextclk(lfextclk),
  .lfxoscen(),

  .io_pads_jtag_TCK_i_ival (jtag_TCK),
  .io_pads_jtag_TMS_i_ival (jtag_TMS),
  .io_pads_jtag_TDI_i_ival (jtag_TDI),
  .io_pads_jtag_TDO_o_oval (jtag_TDO),
  .io_pads_jtag_TDO_o_oe (),

   .io_pads_gpioA_i_ival(32'b0),
   .io_pads_gpioA_o_oval(),
   .io_pads_gpioA_o_oe  (),

   .io_pads_gpioB_i_ival(32'b0),
   .io_pads_gpioB_o_oval(),
   .io_pads_gpioB_o_oe  (),

   .io_pads_qspi0_sck_o_oval (),
   .io_pads_qspi0_cs_0_o_oval(),
   .io_pads_qspi0_dq_0_i_ival(1'b1),
   .io_pads_qspi0_dq_0_o_oval(),
   .io_pads_qspi0_dq_0_o_oe  (),
   .io_pads_qspi0_dq_1_i_ival(1'b1),
   .io_pads_qspi0_dq_1_o_oval(),
   .io_pads_qspi0_dq_1_o_oe  (),
   .io_pads_qspi0_dq_2_i_ival(1'b1),
   .io_pads_qspi0_dq_2_o_oval(),
   .io_pads_qspi0_dq_2_o_oe  (),
   .io_pads_qspi0_dq_3_i_ival(1'b1),
   .io_pads_qspi0_dq_3_o_oval(),
   .io_pads_qspi0_dq_3_o_oe  (),

  .io_pads_aon_erst_n_i_ival(rst_n),


  .io_pads_dbgmode0_n_i_ival(1'b1),
  .io_pads_dbgmode1_n_i_ival(1'b1),
  .io_pads_dbgmode2_n_i_ival(1'b1),

  .io_pads_bootrom_n_i_ival(1'b0),
  .io_pads_aon_pmu_dwakeup_n_i_ival(1'b1),
  .io_pads_aon_pmu_padrst_o_oval(),
  .io_pads_aon_pmu_vddpaden_o_oval(),

//////////////////////////////////////////////////////////
/// AXI 
    .axi_arvalid   (io_master_arvalid),
    .axi_arready   (io_master_arready),
    .axi_araddr    (io_master_araddr ),
    .axi_arcache   (io_master_arcache),
    .axi_arprot    (io_master_arprot ),
    .axi_arlock    (io_master_arlock ),
    .axi_arburst   (io_master_arburst),
    .axi_arlen     (io_master_arlen  ),
    .axi_arsize    (io_master_arsize ),
    .axi_arid      (io_master_arid),

    .axi_awvalid   (io_master_awvalid),
    .axi_awready   (io_master_awready),
    .axi_awaddr    (io_master_awaddr ),
    .axi_awcache   (io_master_awcache),
    .axi_awprot    (io_master_awprot ),
    .axi_awlock    (io_master_awlock ),
    .axi_awburst   (io_master_awburst),
    .axi_awlen     (io_master_awlen  ),
    .axi_awsize    (io_master_awsize ),
    .axi_awid      (io_master_awid),
      
    .axi_rvalid    (io_master_rvalid ),
    .axi_rready    (io_master_rready ),
    .axi_rdata     (io_master_rdata  ),
    .axi_rresp     (io_master_rresp  ),
    .axi_rlast     (io_master_rlast  ),
    .axi_rid       (io_master_rid),

    .axi_wvalid    (io_master_wvalid ),
    .axi_wready    (io_master_wready ),
    .axi_wdata     (io_master_wdata  ),
    .axi_wstrb     (io_master_wstrb  ),
    .axi_wlast     (io_master_wlast  ),
 
    .axi_bvalid    (io_master_bvalid ),
    .axi_bready    (io_master_bready ),
    .axi_bresp     (io_master_bresp  ),
    .axi_bid       (io_master_bid)

);


endmodule

