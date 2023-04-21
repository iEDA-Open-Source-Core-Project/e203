# ICB总线介绍：

## ICB起源：

针对蜂鸟E203处理器而言，其作者总结工业界各种优缺点，并在此基础上研制出适配蜂鸟E203处理器的总线ICB（Internal Chip Bus）。

| Bus Name | 优点                                                                    | 缺点                                                                                                                                                                                                 |
|:--------:|:---------------------------------------------------------------------:|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------:|
| AXI      | 应用最为广泛的高性能总线；拥有5个通道，分离的读/写通道能够提高吞吐率                                   | Master自行维护读和写的顺序，控制相对复杂，使用不当会造成各种死锁；五个通道导致硬件开销过大；会给用户造成负担(需要将 AXI 转换成 AHB 或者其他总线用于低功耗的 SoC )                                                                                                       |
| AHB      | 目前应用最为广泛 的高性能低功耗总线,                                                   | AHB 总线有若干非常明显的局限性,首先其无法像 AXI 总线那样容易地添加流水线级数,其次 AHB 总线无法支持多个滞外交易(Multiple Outstanding Transaction ),再次其握手协议非常别扭 。将 AHB 总线转换成其他 Valid-Ready 握手类型的协议(譬如 AXI 和 TileLink 等握手总线接口〉颇不容易,跨时钟域或者整数倍时钟域更加困难。 |
| APB      | 一种低速设备总线                                                              | 吞吐率比较低,不适合作为主总线使用                                                                                                                                                                                  |
| TileLink | 伯克利大学定义的 一种高速片上总线协议,它诞生的初衷主要是为了定义一种标准的支持缓存一致性( Cache Coherence )的协议 。 | TileLink 总线 主要在伯克利大 学 的项目中使用,其应用并不广泛,文档也不是特别丰富 , 并且 Ti leLink 总线协议比较复杂                                                                                                                             |

## ICB简介：

ICB总线不仅在蜂鸟E203处理器核内部使用，同时也在SoC中的总线使用。ICB总线设计的初衷是为了尽可能结合AXI总线和AXB总线的优点，兼具高速性和易用性，它具有如下特性：

![image-20230421215714574](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212158499.png)

+ 相比 AXI 和址IB 而言, ICB 的协议控制更加简单,仅有两个独立的通道，读和写操作共用地址通道,共用结果返回通道。
+ 与 AXI 总线 一样,采用分离的地址和数据阶段。
+ 与 AXI 总线一样,采用地址区间寻址,支持任意的主从数目,譬如一主一从、一主多从、多主 一 从、 多主多从等拓扑结构 。
+ 与 ARB 总线 一样,每个读或者 写 操作都会在地址通道上产生地址,而非像 AXI 中只产生起始地址。
+ 与 AXI 总线 一样,支持地址非对齐的数据访问,使用字节掩码( Write Mask )来控制部分写操作 。
+ 与 AXI 总线 一样,支持 多 个滞外交易( Multiple Outstanding Transaction )。
+ 与 ARB 总线 一样,不支持乱序返回乱序完成,反馈通道必须按顺序返回结果 。
+ 与 AXI 总线一样,非常易于添加流水线级数以获得高频的时序 。
+ 协议非常简单,易于桥接转换成其他总线类型,譬如 AXI 、ARB 、APB 或者 TileLink等总线 。

### ICB总线协议信号：

ICB总线包含2个通道：

+ 命令通道(Command Channel)：主设备向从设备发起读写请求；

+ 返回通道(Response Channel)：从设备向主设备返回读写结果；

![image-20230421215948278](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212200960.png)

## ICB总线协议时序：

### 写操作同一周期返回结果：

![image-20230421220105771](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212201744.png)

+ 主设备通过 ICB 的命令通道向从设备发送写操作请求( icb cmd read 为低〉,从设备
  立即接收该请求( icb_crud_ready 为高〉 。

+ 从设备在同 一个周期返回反馈且结果正确( icb_rsp_e盯为低〉,主设备立即接收该结
  果( icb _rsp_ready 为高〉 。

### 读操作下一周期返回结果：

![image-20230421220124833](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212202073.png)

+ 主设备通过 ICB 的命令通道向从设备发送读操作请求( icb cmd read 为高〉,从设备立即接收该请求( icb cmd_ready 为高) 。

+ 从设备在下一个周期返回反馈且结果正确( icb _rsp _err 为低), 主设备立即接收该结果( icb_rsp_ready 为高) 。

### 连续4个写操作均4个周期返回结果：

![image-20230421220144828](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212202849.png)

+ 主设备通过 ICB 的命令通道向从设备连续发送 4 个写操作请 求( icb cmd read 为低),
  从设备均立即接收请求 ( icb_cmd _ready 为高〉。

+ 从设备在 4 个周期后连续返回 4 个写结果,其中前 3 个结果正确 C icb_rsp_err 为低), 第4 个结果错误 Cicb_rsp_eη 为高 ),主设备均立即接收此 4 个结果 C icb_rsp_ready 为高) 。

### 读写操作混合发生：

![image-20230421220253238](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212202907.png)

+ 主设备通过 ICB 的命令通道向从设备相继发送两个读和 一个写操作请求 。

+ 从设备立即接收了第 l 个和第 3 个请求。

+ 但是第 2 个请求的第 1 个周期并没有被从设备立即接受( icb cmd ready 为低〉,因
  此主设备一直将地址控制和写数据信号保持不变,直到下 一周 期该请求被从设备接
  受( icb_ cmd ready 为 高〉。

+ 从设备对于第 l 个和第 2 个请求都是在同一个周期就返回结果,且被主设备立即接受 。
  但是从设备对于第 3 个请求则是在下一个周期才返回结果,并且主设备还没有立即
  接受( icb_rsp_ready 为低〉,因此从设备 一直将返回信号保持不变,直到下一周期该
  返回结果被主设备接受。

# ICB总线的硬件实现：

## 一主多从

![image-20230421220310503](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212203986.png)

ICB 总线可以通过一个“ ICB 分发”模块实现一个主设备到多个从设备的连接。

+ 该模块有 1 个输入 ICB ,命名为ln总线;有 3 个输出 ICB ,分别命名为Out0 、Out1 和 Out2 总线。
+ 该模块并没有引入任何的周期延迟,即输入 ICB 和输出 ICB 在1个周期内穿通 。
+ 该模块 的 In 总线命令通道有 1 个附属输入信号 , 用来指示该请求应该被分发到哪个输出 ICB 总 线 。 该附属信号可以在顶层通过地址区间的比较判断生成所得 。
+ 根据附属信号中的指示信息, In 总线的命令通道被分发给 Out0、Out1或者 Out2 输出 ICB 的命令通道 。 每个周期如果握手成功,则分发一个交易( Transaction ),同时将“分发信息”压入 FIFO 中 。
+ 由于 ICB 支 持 多 个滞外交易, OutO 、 Outl 或者 Out2 输出 ICB 通过反馈通道返回的结果可能需要多个周期才能返回,并且各自返回的时间点可能先后不一,因此需要被仲裁。 此时可以从 FIFO 中 按顺序弹出之前被压入的“分发信息”作为仲裁标准。该 FIFO 的深度决定了该模块能够支持的多个滞外交易的个数,同时由于 FIF O 先入先出的顺序性,能够保证输入 ICB 严格按照发出的顺序接收到相应的返回结果。
+ 有一种极端情况,那就是当 FIFO 为 空时,意味着没有滞外交易,并且当前分发的ICB 交易可以被从设备在同 一个周期内立即返回结果,那么该交易的分发信息无须被压入 FIFO ,而 是将其旁路使用该分发信息直接用于反馈通道选择的选通信号。

## 多主一从

![image-20230421220847288](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212208535.png)

ICB 总线可以通过一个“ ICB 汇合”模块实现多个主设备到 一个从设备的连接。

+ 该模块有 3 个输入 ICB , 分别命名为 In0、In1 和 In2 总线;有 l 个输出 ICB ,命名为 Out 总线 。
+ 该模块并没有引入任何的周期延迟,即输入 ICB 和输出 ICB 在 l 个周期内穿通。
+ 该模块多个输入 ICB 的命令通道需要被仲裁,可以使用轮询的仲裁机制,也可以选择优先级选择的机制。以优先级选择机制为例,可以分配 In0 总线的优先级最高、 In1 其次、 In2 再次,通过优先级选择之后作为输出 ICB 的命令通道。每个周期如果握手成功 ,则仲裁发送一个交易,同时将“仲裁信息”压入 FIFO 中。
+ 由于输出 ICB 通过反馈通道返回的结果一定是按顺序返回的（ICB 协议规定）,因此无需担心其顺序性 。但是返回的结果需要判别,并分发给对应的输入 ICB 总线,此时可以从 FIFO 中按顺序弹出之前被压入的“仲裁信息”作为分发的依据。因此该 FIFO的深度决定了该模块能够支持的多个滞外交易的个数,同时由于 FIFO 先入先出的顺序性 , 能够保证各个不同的输入 ICB 严格按照发出的顺序接收到相应的返回结果。
+ 有一种极端情况,那就是当 FIFO 为空时,意味着没有滞外交易,并且当前仲裁的ICB 交易可以被从设备在同一个周期内立即返回结果。那么该交易的仲裁信息无须被压入 FIFO ,而是将其旁路使用该仲裁信息,直接用于反馈通道分发的选通信号。

## 多主多从

通过使用“一主多从”和“多主一从”模块的有效组合,便可以组装成为不同形式的“多主多从”模块。

### 简单的多主多从

通过将“多主 一 从”和“一主多从”模块,直接对接,便可达到多主多从的效果。但是其缺陷是所有的主 ICB 总线均需要通过中间一条公用的 ICB 总线,吞吐率受限。

![image-20230421221529577](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212215000.png)

### 交叉开关的多主多从结构

通过使用多个“一主多从”和“多主一从”模块交织组装成为“ 多主多 从”的交叉开关( Crossbar )结构 。该结构使得每个主接口和从接口之间均有专用的通道,但是其缺陷是面积开销很大,并且设计不当容易造成死锁 。

![image-20230421221545543](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212215333.png)

# ICB总线模块介绍：

## `sirv_gnrl_icb_arbt`

### 参数化配置：

| Name            | Default | Function                                                                               |
| --------------- | ------- | -------------------------------------------------------------------------------------- |
| AW              | 32      | addr width                                                                             |
| DW              | 64      | data width                                                                             |
| USR_W           | 1       | ICB总线`usr`信号位宽                                                                         |
| ARBT_SCHEME     | 0       | 0: priority based，按照输入valid顺序优先级，输出第一个有效值; 1: rrobin，使用`u_sirv_gnrl_rrobin`模块，但未开源其代码； |
| FIFO_OUTS_NUM   | 1       | FIFO深度，也是`The number of outstanding transactions supported`                            |
| FIFO_CUT_READY  | 0       | 数据反压控制信号；                                                                              |
| ARBT_NUM        | 4       | 裁决信号的数量；                                                                               |
| ALLOW_OCYCL_RSP | 1       | 是否允许`rsp 0 cycle`返回数据；                                                                 |
| ARBT_PTR_W      | 2       | 为端口`id`的位宽（裁决信号为4,裁决端口则为2）；                                                            |

### 端口：

| Name          | Function              | Width                     |
| ------------- | --------------------- | ------------------------- |
| o_icb_cmd     | 输出裁决后的ICB总线`cmd`通道信号  | ICB总线cmd通道位宽              |
| o_icb_rsp     | 输出裁决后的ICB总线`rsp`通道信号  | ICB总线rsp通道位宽              |
| i_bus_icb_cmd | 输入需要裁决的ICB总线`cmd`通道信号 | ICB总线cmd通道位宽 * `ARBT_NUM` |
| i_bus_icb_rsp | 输入需要裁决的ICB总线`rsp`通道信号 | ICB总线rsp通道位宽 * `ARBT_NUM` |

![Pasted image 20230421165205](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212129842.png)

### 功能及其使用：

1. 将需要裁决多个的`ICB`总线进行拼接，从而得到位宽为`ARBT_NUM *ICB总线`的一组`bus`，节省端口信号，并在模块内部将每个需要`ICB`总线信号分开；

2. 按照参数化配置是否支持`FIFO`缓存以及数据反压控制等，的优先级模式`ARBT_SCHEME`，生成相对应的独热码选择信号`i_bus_icb_cmd_sel`；

3. 最终通过选择生成裁决后的一组`ICB`总线；

### 补充

#### ARBT_SCHEME=0

这里内部选择信号生成写的非常有意思

```
    if(ARBT_SCHEME == 0) begin:priorty_arbt//{
      wire arbt_ena = 1'b0;//No use
      for(i = 0; i < ARBT_NUM; i = i+1)//{
      begin:priroty_grt_vec_gen
        if(i==0) begin: i_is_0
          assign i_bus_icb_cmd_grt_vec[i] =  1'b1;
        end
        else begin:i_is_not_0
          assign i_bus_icb_cmd_grt_vec[i] =  ~(|i_bus_icb_cmd_valid[i-1:0]);
        end
        assign i_bus_icb_cmd_sel[i] = i_bus_icb_cmd_grt_vec[i] & i_bus_icb_cmd_valid[i];
      end//}
    end//}
```

这里通过选择低位有效裁决输出，按照我写法可能会使用多个`Mux`嵌套使用输出最终结果，而蜂鸟作者选择通过通过上述代码生成独热码选择信号，比如：若输入`i_bus_icb_cmd_valid=4'b1001`，则对应`i_bus_icb_cmd_sel=4'b0001`；

```
        sel_o_icb_cmd_read  = sel_o_icb_cmd_read  | ({1    {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_read [j]);
        sel_o_icb_cmd_addr  = sel_o_icb_cmd_addr  | ({AW   {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_addr [j]);
        sel_o_icb_cmd_wdata = sel_o_icb_cmd_wdata | ({DW   {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_wdata[j]);
        sel_o_icb_cmd_wmask = sel_o_icb_cmd_wmask | ({DW/8 {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_wmask[j]);
        sel_o_icb_cmd_burst = sel_o_icb_cmd_burst | ({2    {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_burst[j]);
        sel_o_icb_cmd_beat  = sel_o_icb_cmd_beat  | ({2    {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_beat [j]);
        sel_o_icb_cmd_lock  = sel_o_icb_cmd_lock  | ({1    {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_lock [j]);
        sel_o_icb_cmd_excl  = sel_o_icb_cmd_excl  | ({1    {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_excl [j]);
        sel_o_icb_cmd_size  = sel_o_icb_cmd_size  | ({2    {i_bus_icb_cmd_sel[j]}} & i_icb_cmd_size [j]);
        sel_o_icb_cmd_usr   = sel_o_icb_cmd_usr   | ({USR_W{i_bus_icb_cmd_sel[j]}} & i_icb_cmd_usr  [j]);
```

然后通过`always`块通过将选择信号与数据进行与运算输出；

#### `sirv_gnrl_rrobin`

该模块是一个 `round-robin` 调度器，用于从多个请求中选择一个请求进行服务。它有五个输入端口：`grt_vec，req_vec，arbt_ena，clk 和 rst_n`。其中，`grt_vec` 是一个向量，用于指示哪些请求是优先级最高的；`req_vec`是一个向量，用于指示哪些请求是有效的；`arbt_ena` 是一个使能信号，用于启用调度器；`clk` 是时钟信号；`rst_n`是异步复位信号。

## `sirv_gnrl_icb_n2w`

### 参数化配置：

| Name           | Default | Function                                                      |
| -------------- | ------- | ------------------------------------------------------------- |
| AW             | 32      | addr width                                                    |
| USR_W          | 1       | `ICB`总线`usr`信号位宽                                              |
| FIFO_OUTS_NUM  | 8       | `FIFO`深度，也是`The number of outstanding transactions supported` |
| FIFO_CUT_READY | 0       | 数据反压控制信号；                                                     |
| X_W            | 32      | 需要转换`ICB`总线数据位宽                                               |
| Y_W            | 64      | 转换后`ICB`总线数据位宽                                                |

### 端口：

| Name      | Function                | Width              |
| --------- | ----------------------- | ------------------ |
| o_icb_cmd | 输出扩展后的ICB总线`cmd`通道信号    | ICB总线cmd通道位宽（Y_W）  |
| o_icb_rsp | 输出扩展后的ICB总线`rsp`通道信号    | ICB总线rsp通道位宽（Y_W）  |
| i_icb_cmd | 输入需要扩展位宽的ICB总线`cmd`通道信号 | ICB总线cmd通道位宽 （X_W） |
| i_icb_rsp | 输入需要扩展位宽的ICB总线`rsp`通道信号 | ICB总线rsp通道位宽（X_W）  |

![image-20230421200457808](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212129899.png)

### 功能及其使用：

​        首先根据`ICB`总线约定，当`cmd`通道发出请求时（`icb_cmd_valid`有效），若`rsp`通道接受到数据，则会返回`icb_cmd_ready`信号，表示`cmd`通道已经成功传递给`rsp`通道数据。`rsp`通道数据完成后，会将`icb_rsp_valid`拉高有效，准备将其数据返还给`cmd`通道；只有`cmd`通道可以接受数据，才会返回给`rsp`通道信号`icb_rsp_ready`。

​        该模块的主要功能是将输入数据从`i_icb_cmd_*端口`传输到`o_icb_cmd_*端口`，并将输出数据从`o_icb_rsp_*端口`传输到`i_icb_rsp_*端口`。在传输数据之前，它将数据存储在一个`FIFO`中，以便在输出端口准备好接收数据时进行传输。此外，它还执行一些数据转换，如将`i_icb_cmd_wdata`复制到`o_icb_cmd_wdata`的高位和低位，以及根据`i_icb_cmd_addr`的第2位（`cmd_y_lo_hi`）将`i_icb_cmd_wmask`复制到`o_icb_cmd_wmask`的高位或低位。

​        该模块使用了一些`Verilog`的特性，如`generate`块和条件赋值。`generate`块允许根据参数的值生成不同的硬件结构。条件赋值允许根据条件选择不同的赋值语句。

```
    else begin: fifo_dp_gt_1//{
      sirv_gnrl_fifo # (
        .CUT_READY (FIFO_CUT_READY),
        .MSKO      (0),
        .DP  (FIFO_OUTS_NUM),
        .DW  (1)
      ) u_sirv_gnrl_n2w_fifo (
        .i_vld(n2w_fifo_i_valid),
        .i_rdy(n2w_fifo_i_ready),
        .i_dat(cmd_y_lo_hi ),
        .o_vld(n2w_fifo_o_valid),
        .o_rdy(n2w_fifo_o_ready),  
        .o_dat(rsp_y_lo_hi ),  

        .clk  (clk),
        .rst_n(rst_n)
      );
    end//}
```

```
generate
    if(X_W == 32) begin: x_w_32//{
      if(Y_W == 64) begin: y_w_64//{
        assign cmd_y_lo_hi = i_icb_cmd_addr[2]; 
      end//}
    end//}
  endgenerate
```

```
  assign i_icb_rsp_rdata = rsp_y_lo_hi ?  o_icb_rsp_rdata[Y_W-1:X_W] : o_icb_rsp_rdata[X_W-1:0] ;
```

​        而内部`FIFO`模块（实例化`sirv_gnrl_pipe_stage`）并不是用`FIFO`保存`ICB总线`所有数据，而是只保存每组`ICB`总线的`cmd_y_lo_hi`信号。因为此模块若遇到`ICB`总线`cmd`通道连续传输多次数据，`rsp`通道需要等待一段时间才可以传输数据的情况，若无`FIFO`缓存，则无法返回rsp通道中`i_icb_rsp_rdata`正确数据。

​        默认模块功能为将一个32位ICB总线扩展为64位，并支持深度为8的FIFO缓存；通过参数化配置后，得到可以将数据位宽为`X_W`的ICB总线扩展为`Y_W`的ICB总线的模块，并支持深度为`FIFO_OUTS_NUM`的`FIFO`缓存；

## `sirv_gnrl_icb2axi`

### 参数化配置：

| Name               | Default | Function                                                                                                                                                                                            |
| ------------------ | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AXI_FIFO_DP        | 0       | *This is to optionally add the pipeline stage for AXI bus, if the depth is 0, then means pass through, not add pipeline; if the depth is 2, then means added one ping-pong buffer stage addr width* |
| AXI_FIFO_CUT_READY | 1       | *This is to cut the back-pressure signal if you set as 1*                                                                                                                                           |
| AW                 | 32      | Addr width                                                                                                                                                                                          |
| FIFO_OUTS_NUM      | 8       | `FIFO`深度，也是`The number of outstanding transactions supported`                                                                                                                                       |
| FIFO_CUT_READY     | 0       | 数据反压控制信号；                                                                                                                                                                                           |
| DW                 | 64      | 转换后`AXI`总线数据位宽                                                                                                                                                                                      |

### 端口：

| Name        | Function         | Width            |
| ----------- | ---------------- | ---------------- |
| i_icb_cmd_* | 输入ICB总线`cmd`通道信号 | ICB总线cmd通道位宽（AW） |
| i_icb_rsp_* | 输入ICB总线`rsp`通道信号 | ICB总线rsp通道位宽（AW） |
| o_axi_ar*   | 输出AXI总线`ar`通道信号  | AXI总线ar通道位宽 （DW） |
| o_axi_aw*   | 输出AXI总线`aw`通道信号  | AXI总线aw通道位宽（DW）  |
| o_axi_r*    | 输出AXI总线`r`通道信号   | AXI总线r通道位宽（DW）   |
| o_axi_w*    | 输出AXI总线`w`通道信号   | AXI总线w通道位宽（DW）   |
| o_axi_b*    | 输出AXI总线`b`通道信号   | AXI总线b通道位宽（DW）   |

![image-20230421212236486](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2202304212129508.png)

### 功能及其使用：

​        此模块可以将ICB总线转换为AXI总线。它有许多输入和输出端口，输入包括ICB命令通道的有效性、读取标志、地址、写入数据、写入掩码和大小，以及时钟和复位信号。输出包括ICB响应通道的有效性、错误、读取数据和AXI总线的读取和写入通道的有效性、地址、数据、响应和其他控制信号。

       如果ICB命令通道是读取，则只需要将其传递到AXI读取通道。如果ICB命令通道是写入，则需要将其传递到AXI写入通道和数据通道。在所有情况下，需要检查FIFO是否已满。如果FIFO已满，则不能写入数据。

        它还包括一个FIFO缓冲区，用于存储ICB命令通道的读取标志，如果FIFO已满，则不能写入数据。如果FIFO为空，则不能读取数据；还有一些参数用于控制模块的行为，例如是否添加AXI总线的流水线阶段、FIFO缓冲区的深度等；还包括一些逻辑，用于将ICB命令通道转换为AXI地址、读写数据通道，并将AXI响应通道转换为ICB响应通道。

​        其中`sirv_gnrl_axi_buffer`模块根据参数`AXI_FIFO_DP`设置，从而得到不同功能`buf`

+ `AXI_FIFO_DP=0`：正常输入、输出，无`buffer`；
+ `AXI_FIFO_DP=2`：`ping-pang buffer`，深度为2，并且可以切断信号反压；
