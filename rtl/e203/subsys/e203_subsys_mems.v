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
                                                                         
                                                                         
                                                                         
//=====================================================================
//
// Designer   : Bob Hu
//
// Description:
//  The system memory bus and the ROM instance 
//
// ====================================================================


`include "e203_defines.v"

module e203_subsys_mems(
  input                          mem_icb_cmd_valid,
  output                         mem_icb_cmd_ready,
  input  [`E203_ADDR_SIZE-1:0]   mem_icb_cmd_addr, 
  input                          mem_icb_cmd_read, 
  input  [`E203_XLEN-1:0]        mem_icb_cmd_wdata,
  input  [`E203_XLEN/8-1:0]      mem_icb_cmd_wmask,
  //
  output                         mem_icb_rsp_valid,
  input                          mem_icb_rsp_ready,
  output                         mem_icb_rsp_err,
  output [`E203_XLEN-1:0]        mem_icb_rsp_rdata,
  
  //////////////////////////////////////////////////////////
  output                         sysmem_icb_cmd_valid,
  input                          sysmem_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   sysmem_icb_cmd_addr, 
  output                         sysmem_icb_cmd_read, 
  output [`E203_XLEN-1:0]        sysmem_icb_cmd_wdata,
  output [`E203_XLEN/8-1:0]      sysmem_icb_cmd_wmask,
  //
  input                          sysmem_icb_rsp_valid,
  output                         sysmem_icb_rsp_ready,
  input                          sysmem_icb_rsp_err,
  input  [`E203_XLEN-1:0]        sysmem_icb_rsp_rdata,

    //////////////////////////////////////////////////////////
  output                         qspi0_ro_icb_cmd_valid,
  input                          qspi0_ro_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   qspi0_ro_icb_cmd_addr, 
  output                         qspi0_ro_icb_cmd_read, 
  output [`E203_XLEN-1:0]        qspi0_ro_icb_cmd_wdata,
  //
  input                          qspi0_ro_icb_rsp_valid,
  output                         qspi0_ro_icb_rsp_ready,
  input                          qspi0_ro_icb_rsp_err,
  input  [`E203_XLEN-1:0]        qspi0_ro_icb_rsp_rdata,


    //////////////////////////////////////////////////////////   Debug Module
  output                         dm_icb_cmd_valid,
  input                          dm_icb_cmd_ready,
  output [`E203_ADDR_SIZE-1:0]   dm_icb_cmd_addr, 
  output                         dm_icb_cmd_read, 
  output [`E203_XLEN-1:0]        dm_icb_cmd_wdata,
  //
  input                          dm_icb_rsp_valid,
  output                         dm_icb_rsp_ready,
  input  [`E203_XLEN-1:0]        dm_icb_rsp_rdata,

    //////////////////////////////////////////////////////////
  output axi_arvalid,
  input  axi_arready,
  output [32-1:0] axi_araddr,
  output [0:0] axi_arcache,
  output [0:0] axi_arprot,
  output [0:0] axi_arlock,
  output [1:0] axi_arburst,
  output [7:0] axi_arlen,
  output [2:0] axi_arsize,
  output    [3:0]   axi_arid,

  output axi_awvalid,
  input  axi_awready,
  output [32-1:0] axi_awaddr,
  output [0:0] axi_awcache,
  output [0:0] axi_awprot,
  output [0:0] axi_awlock,
  output [1:0] axi_awburst,
  output [7:0] axi_awlen,
  output [2:0] axi_awsize,
  output    [3:0]   axi_awid,

  input  axi_rvalid,
  output axi_rready,
  input  [64-1:0] axi_rdata,
  input  [1:0] axi_rresp,
  input  axi_rlast,
  input  [3:0]axi_rid,

  output axi_wvalid,
  input  axi_wready,
  output [64-1:0] axi_wdata,
  output [(64/8)-1:0] axi_wstrb,
  output axi_wlast,

  input  axi_bvalid,
  output axi_bready,
  input  [1:0] axi_bresp,
  input [3:0] axi_bid,

  input  clk,
  input  bus_rst_n,
  input  rst_n
  );

  assign sysmem_icb_cmd_valid = 1'b0;
  assign sysmem_icb_cmd_addr = 32'h0;
  assign sysmem_icb_cmd_read = 1'b0;
  assign sysmem_icb_cmd_wdata = 64'h0;
  assign sysmem_icb_cmd_wmask = 8'h0;
  assign sysmem_icb_rsp_ready = 1'b0;

  assign qspi0_ro_icb_cmd_valid = 1'b0;
  assign qspi0_ro_icb_cmd_addr = 32'h0;
  assign qspi0_ro_icb_cmd_read = 1'b0;
  assign qspi0_ro_icb_cmd_wdata = 64'h0;
  assign qspi0_ro_icb_cmd_wmask = 8'h0;
  assign qspi0_ro_icb_rsp_ready = 1'b0;

  assign dm_icb_cmd_valid = 1'b0;
  assign dm_icb_cmd_addr = 32'h0;
  assign dm_icb_cmd_read = 1'b0;
  assign dm_icb_cmd_wdata = 64'h0;
  assign dm_icb_cmd_wmask = 8'h0;
  assign dm_icb_rsp_ready = 1'b0;


//32 bits width icb
  wire                     expl_n2w_axi_icb_cmd_valid;
  wire                     expl_n2w_axi_icb_cmd_ready;
  wire [32-1:0]            expl_n2w_axi_icb_cmd_addr;
  wire                     expl_n2w_axi_icb_cmd_read;
  wire [32-1:0]            expl_n2w_axi_icb_cmd_wdata;
  wire [4 -1:0]            expl_n2w_axi_icb_cmd_wmask;

  wire                     expl_n2w_axi_icb_rsp_valid;
  wire                     expl_n2w_axi_icb_rsp_ready;
  wire [32-1:0]            expl_n2w_axi_icb_rsp_rdata;
  wire                     expl_n2w_axi_icb_rsp_err;

  assign expl_n2w_axi_icb_cmd_valid = mem_icb_cmd_valid;
  assign mem_icb_cmd_ready = expl_n2w_axi_icb_cmd_ready;
  assign expl_n2w_axi_icb_cmd_addr = mem_icb_cmd_addr;
  assign expl_n2w_axi_icb_cmd_read = mem_icb_cmd_read;
  assign expl_n2w_axi_icb_cmd_wdata = mem_icb_cmd_wdata;
  assign expl_n2w_axi_icb_cmd_wmask = mem_icb_cmd_wmask;

  assign mem_icb_rsp_valid = expl_n2w_axi_icb_rsp_valid;
  assign expl_n2w_axi_icb_rsp_ready = mem_icb_rsp_ready;
  assign mem_icb_rsp_rdata = expl_n2w_axi_icb_rsp_rdata;
  assign mem_icb_rsp_err = expl_n2w_axi_icb_rsp_err;
// 64 bits width icb
  wire                     expl_axi_icb_cmd_valid;
  wire                     expl_axi_icb_cmd_ready;
  wire [32-1:0]            expl_axi_icb_cmd_addr; 
  wire                     expl_axi_icb_cmd_read;
  wire [64-1:0]            expl_axi_icb_cmd_wdata;
  wire [8 -1:0]            expl_axi_icb_cmd_wmask;
  
  wire                     expl_axi_icb_rsp_valid;
  wire                     expl_axi_icb_rsp_ready;
  wire [64-1:0]            expl_axi_icb_rsp_rdata;
  wire                     expl_axi_icb_rsp_err;

  // * Here is an example AXI Peripheral
  wire expl_axi_arvalid;
  wire expl_axi_arready;
  wire [`E203_ADDR_SIZE-1:0] expl_axi_araddr;
  wire [3:0] expl_axi_arcache;
  wire [2:0] expl_axi_arprot;
  wire [1:0] expl_axi_arlock;
  wire [1:0] expl_axi_arburst;
  wire [3:0] expl_axi_arlen;
  wire [2:0] expl_axi_arsize;

  wire expl_axi_awvalid;
  wire expl_axi_awready;
  wire [`E203_ADDR_SIZE-1:0] expl_axi_awaddr;
  wire [3:0] expl_axi_awcache;
  wire [2:0] expl_axi_awprot;
  wire [1:0] expl_axi_awlock;
  wire [1:0] expl_axi_awburst;
  wire [3:0] expl_axi_awlen;
  wire [2:0] expl_axi_awsize;

  wire expl_axi_rvalid;
  wire expl_axi_rready;
  wire [64-1:0] expl_axi_rdata;
  // wire [`E203_XLEN-1:0] expl_axi_rdata;
  wire [1:0] expl_axi_rresp;
  wire expl_axi_rlast;

  wire expl_axi_wvalid;
  wire expl_axi_wready;
  // wire [`E203_XLEN-1:0] expl_axi_wdata;
  // wire [(`E203_XLEN/8)-1:0] expl_axi_wstrb;
  wire [64-1:0] expl_axi_wdata;
  wire [(64/8)-1:0] expl_axi_wstrb;
  wire expl_axi_wlast;

  wire expl_axi_bvalid;
  wire expl_axi_bready;
  wire [1:0] expl_axi_bresp;

/////////////////////////////////////////////////////////////////////////////   
// Author: Miaoheng,2023/3/29
//

////////////////////////////////////////////////////////////////////////////
  sirv_gnrl_icb_n2w # (
  .FIFO_OUTS_NUM   (`E203_ITCM_OUTS_NUM),
  .FIFO_CUT_READY  (0),
  .USR_W      (1),
  .AW         (`E203_AXI_ADDR_WIDTH),
  .X_W        (32),
  .Y_W        (`E203_AXI_DATA_WIDTH) 
  ) u_subsys_icb_mems2axi_n2w(
  .i_icb_cmd_valid        (expl_n2w_axi_icb_cmd_valid ),  
  .i_icb_cmd_ready        (expl_n2w_axi_icb_cmd_ready ),
  .i_icb_cmd_read         (expl_n2w_axi_icb_cmd_read  ),
  .i_icb_cmd_addr         (expl_n2w_axi_icb_cmd_addr  ),
  .i_icb_cmd_wdata        (expl_n2w_axi_icb_cmd_wdata ),
  .i_icb_cmd_wmask        (expl_n2w_axi_icb_cmd_wmask ),
  .i_icb_cmd_burst        (2'b0)                   ,
  .i_icb_cmd_beat         (2'b0)                   ,
  .i_icb_cmd_lock         (1'b0),
  .i_icb_cmd_excl         (1'b0),
  .i_icb_cmd_size         (2'b0),
  .i_icb_cmd_usr          (1'b0),
   
  .i_icb_rsp_valid        (expl_n2w_axi_icb_rsp_valid ),
  .i_icb_rsp_ready        (expl_n2w_axi_icb_rsp_ready ),
  .i_icb_rsp_err          (expl_n2w_axi_icb_rsp_err)   ,
  .i_icb_rsp_excl_ok      ()   ,
  .i_icb_rsp_rdata        (expl_n2w_axi_icb_rsp_rdata ),
  .i_icb_rsp_usr          (),
                                                
  .o_icb_cmd_valid        (expl_axi_icb_cmd_valid ),  
  .o_icb_cmd_ready        (expl_axi_icb_cmd_ready ),
  .o_icb_cmd_read         (expl_axi_icb_cmd_read ) ,
  .o_icb_cmd_addr         (expl_axi_icb_cmd_addr ) ,
  .o_icb_cmd_wdata        (expl_axi_icb_cmd_wdata ),
  .o_icb_cmd_wmask        (expl_axi_icb_cmd_wmask) ,
  .o_icb_cmd_burst        ()                   ,
  .o_icb_cmd_beat         ()                   ,
  .o_icb_cmd_lock         (),
  .o_icb_cmd_excl         (),
  .o_icb_cmd_size         (),
  .o_icb_cmd_usr          (),
   
  .o_icb_rsp_valid        (expl_axi_icb_rsp_valid ),
  .o_icb_rsp_ready        (expl_axi_icb_rsp_ready ),
  .o_icb_rsp_err          (expl_axi_icb_rsp_err)   ,
  .o_icb_rsp_excl_ok      (1'b0)   ,
  .o_icb_rsp_rdata        (expl_axi_icb_rsp_rdata ),
  .o_icb_rsp_usr          (1'b0),

  .clk                    (clk   )                  ,
  .rst_n                  (rst_n )                 
  );
// arid and awid are not generated by icb
// if arid or awid is in state z,we can not get response from axi slave,so we need to generate them later
// rid and bid are not used by icb2axi
// because we only have one master and one slave, so we do not care about rid and bid
sirv_gnrl_icb2axi # (
  .AXI_FIFO_DP (2), // We just add ping-pong buffer here to avoid any potential timing loops
                    //   User can change it to 0 if dont care
  .AXI_FIFO_CUT_READY (1), // This is to cut the back-pressure signal if you set as 1
  .AW   (32),
   .FIFO_OUTS_NUM(1),// We only allow 4 oustandings at most for mem, user can configure it to any value
  .FIFO_CUT_READY(1),
  .DW   (64) 
) u_expl_axi_icb2axi(
    .i_icb_cmd_valid (expl_axi_icb_cmd_valid),
    .i_icb_cmd_ready (expl_axi_icb_cmd_ready),
    .i_icb_cmd_addr  (expl_axi_icb_cmd_addr ),
    .i_icb_cmd_read  (expl_axi_icb_cmd_read ),
    .i_icb_cmd_wdata (expl_axi_icb_cmd_wdata),
    .i_icb_cmd_wmask (expl_axi_icb_cmd_wmask),
    .i_icb_cmd_size  (),
    
    .i_icb_rsp_valid (expl_axi_icb_rsp_valid),
    .i_icb_rsp_ready (expl_axi_icb_rsp_ready),
    .i_icb_rsp_rdata (expl_axi_icb_rsp_rdata),
    .i_icb_rsp_err   (expl_axi_icb_rsp_err),

    .o_axi_arvalid   (expl_axi_arvalid),
    .o_axi_arready   (expl_axi_arready),
    .o_axi_araddr    (expl_axi_araddr ),
    .o_axi_arcache   (expl_axi_arcache),
    .o_axi_arprot    (expl_axi_arprot ),
    .o_axi_arlock    (expl_axi_arlock ),
    .o_axi_arburst   (expl_axi_arburst),
    .o_axi_arlen     (expl_axi_arlen  ),
    .o_axi_arsize    (expl_axi_arsize ),
                      
    .o_axi_awvalid   (expl_axi_awvalid),
    .o_axi_awready   (expl_axi_awready),
    .o_axi_awaddr    (expl_axi_awaddr ),
    .o_axi_awcache   (expl_axi_awcache),
    .o_axi_awprot    (expl_axi_awprot ),
    .o_axi_awlock    (expl_axi_awlock ),
    .o_axi_awburst   (expl_axi_awburst),
    .o_axi_awlen     (expl_axi_awlen  ),
    .o_axi_awsize    (expl_axi_awsize ),
                     
    .o_axi_rvalid    (expl_axi_rvalid ),
    .o_axi_rready    (expl_axi_rready ),
    .o_axi_rdata     (expl_axi_rdata  ),
    .o_axi_rresp     (expl_axi_rresp  ),
    .o_axi_rlast     (expl_axi_rlast  ),
                    
    .o_axi_wvalid    (expl_axi_wvalid ),
    .o_axi_wready    (expl_axi_wready ),
    .o_axi_wdata     (expl_axi_wdata  ),
    .o_axi_wstrb     (expl_axi_wstrb  ),
    .o_axi_wlast     (expl_axi_wlast  ),
                   
    .o_axi_bvalid    (expl_axi_bvalid ),
    .o_axi_bready    (expl_axi_bready ),
    .o_axi_bresp     (expl_axi_bresp  ),

    .clk           (clk  ),
    .rst_n         (bus_rst_n) 
  );

  assign  axi_arvalid = expl_axi_arvalid;
  assign  expl_axi_arready = axi_arready;
  assign  axi_araddr = expl_axi_araddr;
  assign  axi_arcache   = 'd0;
  assign  axi_arprot    = 'd0;
  assign  axi_arlock    = 'd0;
  assign  axi_arburst   = 'd1;
  assign  axi_arlen     = 'd0;
  assign  axi_arid      = 'd0;               // force arid to 0
  // force arsize <= 3'b010, because some devices in iEDA only support 32-bit access, i.e spi_flash
  assign  axi_arsize = (expl_axi_arsize<3'b010)?expl_axi_arsize:3'b010;

  assign  axi_awvalid = expl_axi_awvalid;
  assign  expl_axi_awready = axi_awready;
  assign  axi_awaddr = expl_axi_awaddr;
  assign  axi_awcache   = 'd0;
  assign  axi_awprot    = 'd0;
  assign  axi_awlock    = 'd0;
  assign  axi_awburst   = 'd1;
  assign  axi_awlen     = 'd0;
  assign  axi_awid      = 'd0;               // force awid to 0
  // force awsize <= 3'b010, , because some devices in iEDA only support 32-bit access, i.e spi_flash
  assign  axi_awsize = (expl_axi_awsize<3'b010)?expl_axi_awsize:3'b010;

  assign  expl_axi_rvalid = axi_rvalid;
  assign  axi_rready = expl_axi_rready;
  assign  expl_axi_rdata = axi_rdata;
  assign  expl_axi_rresp = axi_rresp;
  assign  expl_axi_rlast = axi_rlast;

  assign  axi_wvalid = expl_axi_wvalid;
  assign  expl_axi_wready = axi_wready;
  assign  axi_wdata = expl_axi_wdata;
  assign  axi_wstrb = expl_axi_wstrb;
  assign  axi_wlast = expl_axi_wlast;

  assign  expl_axi_bvalid = axi_bvalid;
  assign  axi_bready = expl_axi_bready;
  assign  expl_axi_bresp = axi_bresp;


endmodule

