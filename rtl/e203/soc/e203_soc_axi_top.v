 /*                                                                      
 Copyright 2018-2020 Nuclei System Technology, Inc.                
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
  Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */                                                                      
                                                                         
                                                                         
                                                                         
module e203_soc_axi_top(

    // This clock should comes from the crystal pad generated high speed clock (16MHz)
  input  hfextclk,
  output hfxoscen,// The signal to enable the crystal pad generated clock

  // This clock should comes from the crystal pad generated low speed clock (32.768KHz)
  input  lfextclk,
  output lfxoscen,// The signal to enable the crystal pad generated clock


  // The JTAG TCK is input, need to be pull-up
  input   io_pads_jtag_TCK_i_ival,

  // The JTAG TMS is input, need to be pull-up
  input   io_pads_jtag_TMS_i_ival,

  // The JTAG TDI is input, need to be pull-up
  input   io_pads_jtag_TDI_i_ival,

  // The JTAG TDO is output have enable
  output  io_pads_jtag_TDO_o_oval,
  output  io_pads_jtag_TDO_o_oe,

  // The GPIO are all bidir pad have enables
  input  [32-1:0] io_pads_gpioA_i_ival,
  output [32-1:0] io_pads_gpioA_o_oval,
  output [32-1:0] io_pads_gpioA_o_oe,

  input  [32-1:0] io_pads_gpioB_i_ival,
  output [32-1:0] io_pads_gpioB_o_oval,
  output [32-1:0] io_pads_gpioB_o_oe,

  //QSPI0 SCK and CS is output without enable
  output  io_pads_qspi0_sck_o_oval,
  output  io_pads_qspi0_cs_0_o_oval,

  //QSPI0 DQ is bidir I/O with enable, and need pull-up enable
  input   io_pads_qspi0_dq_0_i_ival,
  output  io_pads_qspi0_dq_0_o_oval,
  output  io_pads_qspi0_dq_0_o_oe,
  input   io_pads_qspi0_dq_1_i_ival,
  output  io_pads_qspi0_dq_1_o_oval,
  output  io_pads_qspi0_dq_1_o_oe,
  input   io_pads_qspi0_dq_2_i_ival,
  output  io_pads_qspi0_dq_2_o_oval,
  output  io_pads_qspi0_dq_2_o_oe,
  input   io_pads_qspi0_dq_3_i_ival,
  output  io_pads_qspi0_dq_3_o_oval,
  output  io_pads_qspi0_dq_3_o_oe,
  
  // Erst is input need to be pull-up by default
  input   io_pads_aon_erst_n_i_ival,

  // dbgmode are inputs need to be pull-up by default
  input  io_pads_dbgmode0_n_i_ival,
  input  io_pads_dbgmode1_n_i_ival,
  input  io_pads_dbgmode2_n_i_ival,

  // BootRom is input need to be pull-up by default
  input  io_pads_bootrom_n_i_ival,


  // dwakeup is input need to be pull-up by default
  input  io_pads_aon_pmu_dwakeup_n_i_ival,

      // PMU output is just output without enable
  output io_pads_aon_pmu_padrst_o_oval,
  output io_pads_aon_pmu_vddpaden_o_oval 

);

// * Here is an example AXI Peripheral
  wire expl_axi_arvalid;
  wire expl_axi_arready;
  wire [32-1:0] expl_axi_araddr;
  wire [3:0] expl_axi_arcache;
  wire [2:0] expl_axi_arprot;
  wire [1:0] expl_axi_arlock;
  wire [1:0] expl_axi_arburst;
  wire [3:0] expl_axi_arlen;
  wire [2:0] expl_axi_arsize;

  wire expl_axi_awvalid;
  wire expl_axi_awready;
  wire [32-1:0] expl_axi_awaddr;
  wire [3:0] expl_axi_awcache;
  wire [2:0] expl_axi_awprot;
  wire [1:0] expl_axi_awlock;
  wire [1:0] expl_axi_awburst;
  wire [3:0] expl_axi_awlen;
  wire [2:0] expl_axi_awsize;

  wire expl_axi_rvalid;
  wire expl_axi_rready;
  wire [64-1:0] expl_axi_rdata;
  wire [1:0] expl_axi_rresp;
  wire expl_axi_rlast;

  wire expl_axi_wvalid;
  wire expl_axi_wready;
  wire [64-1:0] expl_axi_wdata;
  wire [(64/8)-1:0] expl_axi_wstrb;
  wire expl_axi_wlast;

  wire expl_axi_bvalid;
  wire expl_axi_bready;
  wire [1:0] expl_axi_bresp;

e203_soc_top u_e203_soc_top(

  .hfextclk(hfextclk),
  .hfxoscen(hfxoscen),
  .lfextclk(lfextclk),
  .lfxoscen(lfxoscen),
  .io_pads_jtag_TCK_i_ival(io_pads_jtag_TCK_i_ival),
  .io_pads_jtag_TMS_i_ival(io_pads_jtag_TMS_i_ival),
  .io_pads_jtag_TDI_i_ival(io_pads_jtag_TDI_i_ival),
  .io_pads_jtag_TDO_o_oval(io_pads_jtag_TDO_o_oval),
  .io_pads_jtag_TDO_o_oe(io_pads_jtag_TDO_o_oe),
  .io_pads_gpioA_i_ival(io_pads_gpioA_i_ival),
  .io_pads_gpioA_o_oval(io_pads_gpioA_o_oval),
  .io_pads_gpioA_o_oe(io_pads_gpioA_o_oe),
  .io_pads_gpioB_i_ival(io_pads_gpioB_i_ival),
  .io_pads_gpioB_o_oval(io_pads_gpioB_o_oval),
  .io_pads_gpioB_o_oe(io_pads_gpioB_o_oe),
  .io_pads_qspi0_sck_o_oval(io_pads_qspi0_sck_o_oval),
  .io_pads_qspi0_cs_0_o_oval(io_pads_qspi0_cs_0_o_oval),
  .io_pads_qspi0_dq_0_i_ival(io_pads_qspi0_dq_0_i_ival),
  .io_pads_qspi0_dq_0_o_oval(io_pads_qspi0_dq_0_o_oval),
  .io_pads_qspi0_dq_0_o_oe(io_pads_qspi0_dq_0_o_oe),
  .io_pads_qspi0_dq_1_i_ival(io_pads_qspi0_dq_1_i_ival),
  .io_pads_qspi0_dq_1_o_oval(io_pads_qspi0_dq_1_o_oval),
  .io_pads_qspi0_dq_1_o_oe(io_pads_qspi0_dq_1_o_oe),
  .io_pads_qspi0_dq_2_i_ival(io_pads_qspi0_dq_2_i_ival),
  .io_pads_qspi0_dq_2_o_oval(io_pads_qspi0_dq_2_o_oval),
  .io_pads_qspi0_dq_2_o_oe(io_pads_qspi0_dq_2_o_oe),
  .io_pads_qspi0_dq_3_i_ival(io_pads_qspi0_dq_3_i_ival),
  .io_pads_qspi0_dq_3_o_oval(io_pads_qspi0_dq_3_o_oval),
  .io_pads_qspi0_dq_3_o_oe(io_pads_qspi0_dq_3_o_oe),
  .io_pads_aon_erst_n_i_ival(io_pads_aon_erst_n_i_ival),
  .io_pads_dbgmode0_n_i_ival(io_pads_dbgmode0_n_i_ival),
  .io_pads_dbgmode1_n_i_ival(io_pads_dbgmode1_n_i_ival),
  .io_pads_dbgmode2_n_i_ival(io_pads_dbgmode2_n_i_ival),
  .io_pads_bootrom_n_i_ival(io_pads_bootrom_n_i_ival),
  .io_pads_aon_pmu_dwakeup_n_i_ival(io_pads_aon_pmu_dwakeup_n_i_ival),
  .io_pads_aon_pmu_padrst_o_oval(io_pads_aon_pmu_padrst_o_oval),
  .io_pads_aon_pmu_vddpaden_o_oval(io_pads_aon_pmu_vddpaden_o_oval),

//////////////////////////////////////////////////////////
/// AXI 
    .axi_arvalid   (expl_axi_arvalid),
    .axi_arready   (expl_axi_arready),
    .axi_araddr    (expl_axi_araddr ),
    .axi_arcache   (expl_axi_arcache),
    .axi_arprot    (expl_axi_arprot ),
    .axi_arlock    (expl_axi_arlock ),
    .axi_arburst   (expl_axi_arburst),
    .axi_arlen     (expl_axi_arlen  ),
    .axi_arsize    (expl_axi_arsize ),

    .axi_awvalid   (expl_axi_awvalid),
    .axi_awready   (expl_axi_awready),
    .axi_awaddr    (expl_axi_awaddr ),
    .axi_awcache   (expl_axi_awcache),
    .axi_awprot    (expl_axi_awprot ),
    .axi_awlock    (expl_axi_awlock ),
    .axi_awburst   (expl_axi_awburst),
    .axi_awlen     (expl_axi_awlen  ),
    .axi_awsize    (expl_axi_awsize ),
  
    .axi_rvalid    (expl_axi_rvalid ),
    .axi_rready    (expl_axi_rready ),
    .axi_rdata     (expl_axi_rdata  ),
    .axi_rresp     (expl_axi_rresp  ),
    .axi_rlast     (expl_axi_rlast  ),

    .axi_wvalid    (expl_axi_wvalid ),
    .axi_wready    (expl_axi_wready ),
    .axi_wdata     (expl_axi_wdata  ),
    .axi_wstrb     (expl_axi_wstrb  ),
    .axi_wlast     (expl_axi_wlast  ),
 
    .axi_bvalid    (expl_axi_bvalid ),
    .axi_bready    (expl_axi_bready ),
    .axi_bresp     (expl_axi_bresp  )

);

sirv_expl_axi_slv # (
  .AW   (32),
  .DW   (64) 
  // .DW   (`E203_XLEN) 
) u_perips_expl_axi_slv (
    .axi_arvalid   (expl_axi_arvalid),
    .axi_arready   (expl_axi_arready),
    .axi_araddr    (expl_axi_araddr ),
    .axi_arcache   (expl_axi_arcache),
    .axi_arprot    (expl_axi_arprot ),
    .axi_arlock    (expl_axi_arlock ),
    .axi_arburst   (expl_axi_arburst),
    .axi_arlen     (expl_axi_arlen  ),
    .axi_arsize    (expl_axi_arsize ),

    .axi_awvalid   (expl_axi_awvalid),
    .axi_awready   (expl_axi_awready),
    .axi_awaddr    (expl_axi_awaddr ),
    .axi_awcache   (expl_axi_awcache),
    .axi_awprot    (expl_axi_awprot ),
    .axi_awlock    (expl_axi_awlock ),
    .axi_awburst   (expl_axi_awburst),
    .axi_awlen     (expl_axi_awlen  ),
    .axi_awsize    (expl_axi_awsize ),
  
    .axi_rvalid    (expl_axi_rvalid ),
    .axi_rready    (expl_axi_rready ),
    .axi_rdata     (expl_axi_rdata  ),
    .axi_rresp     (expl_axi_rresp  ),
    .axi_rlast     (expl_axi_rlast  ),

    .axi_wvalid    (expl_axi_wvalid ),
    .axi_wready    (expl_axi_wready ),
    .axi_wdata     (expl_axi_wdata  ),
    .axi_wstrb     (expl_axi_wstrb  ),
    .axi_wlast     (expl_axi_wlast  ),
 
    .axi_bvalid    (expl_axi_bvalid ),
    .axi_bready    (expl_axi_bready ),
    .axi_bresp     (expl_axi_bresp  ),

    .clk           (clk  ),
    .rst_n         (rst_n) 
  );

endmodule
