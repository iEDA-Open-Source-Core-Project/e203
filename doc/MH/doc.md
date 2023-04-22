# 蜂鸟e203内部寄存器：

## sirv_sim_ram：

### 功能：

- 模拟SRAM；

- 根据输入信号`cs`和`we`生成写使能信号`wen`和读使能信号`ren`。当读使能信号`ren`高电平时，时钟逻辑块在时钟信号`clk`上升沿时更新地址寄存器`addr_r`；

- 该模块还有一个生成块，用于实现内存数组`mem_r`。生成块使用循环创建`MW`个内存块，每个内存块宽度为`DW`位。每个内存块都是一个单独的`always`块，当写使能信号`wen`高电平时更新相应的内存数组`mem_r`的部分。  

- 该模块还有另一个生成块，可将输出`dout`中未初始化的位强制设置为零。这由`FORCE_X2ZERO`参数控制。
  
  - 如果`FORCE_X2ZERO`设置为1，则生成块创建另一个循环，遍历输出`dout`中的所有位，并将任何未初始化的位设置为零。
  
  - 否则，生成块只是将输出`dout`分配给由`addr_r`指定的内存数组`mem_r`的内容。  

### 参数：

| Name          | Default | Function                        |
| ------------- | ------- | ------------------------------- |
| FORCE_X2ZERO： | 0       | 有效则将输出的不定态变为0；                  |
| DP：           | 512     | sram内部寄存器数量                     |
| DW：           | 32      | data width, sram内部寄存器位宽         |
| AW：           | 32      | addr width,数据地址宽度               |
| MW：           | 4       | mask width，独热码，用于表示对应每`bytes`掩码 |

### 信号接口：

| Name | Function                                        |
| ---- | ----------------------------------------------- |
| clk  | 时钟信号                                            |
| din  | 输入数据                                            |
| addr | 输入数据的地址                                         |
| cs   | 有效才可以进行读写                                       |
| we   | write enable；有效->write，无效->read；                |
| wem  | wirte enable mask，默认4bits对应写入数据4byte，写入掩码每一位对应； |
| dout | 输出数据                                            |

## sirv_gnrl_ram：

### 功能：

+ 该模块内部实例化了一个名为`sirv_sim_ram`的模块，该模块是`RAM` 的仿真模型。

+ 实例化是基于`ifdef FPGA_SOURCE`宏定义进行条件判断的。如果定义了此宏定义，则使用FPGA源，否则使用仿真模型。
  
  + FPGA源：将`dout`数据正常输出；
  
  + 仿真模型：将`dout`数据中的不定太`x`强制变为`0`；

### 参数：

| Name          | Default | Function                        |
| ------------- | ------- | ------------------------------- |
| FORCE_X2ZERO： | 1       | 有效则将输出的不定态变为0；                  |
| DP：           | 32      | sram内部寄存器数量                     |
| DW：           | 32      | data width, sram内部寄存器位宽         |
| AW：           | 15      | addr width,数据地址宽度               |
| MW：           | 4       | mask width，独热码，用于表示对应每`bytes`掩码 |

### 信号接口：

| Name  | Function                                        |
| ----- | ----------------------------------------------- |
| clk   | 时钟信号                                            |
| rst_n | 复位信号，低电平有效，**但此处并未使用**                          |
| sd    | 并未使用                                            |
| ds    | 并未使用                                            |
| ls    | 并未使用                                            |
| din   | 输入数据                                            |
| addr  | 输入数据的地址                                         |
| cs    | 有效才可以进行读写                                       |
| we    | write enable；有效->write，无效->read；                |
| wem   | wirte enable mask，默认4bits对应写入数据4byte，写入掩码每一位对应； |
| dout  | 输出数据                                            |

## 常用寄存器

![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454880.png)

# E203架构：

e203目录树：
![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454707.png)

## 蜂鸟e203：

+ 2级流水线处理器核，流水线的按序主体是位于第一级的“取指”和位于第二级的“执行”和“写回”；

+ 支持`RV32IEMAC`指令集；

+ 机器模式；

+ CLINT：计时器中断、软件中断；

+ PLIC：外部中断， Platform Level Interrupt Controller；用于多个外部中断源的优先级仲裁和派发；

+ 自定义CSR：mcounterstop![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454984.png)

+ SoC总线：ICB-Internal Chip Bus，内核+Soc总线，详细请参考文档《e203 icb总线分析》《e203 icb总线介绍》；

+ SOC框图：
1. ![overview_fig1](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619152.jpeg)

2. ![core_fig1](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619194.jpeg)

3. ![core_fig2](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619225.jpeg)

## IFU：

### 分支预测：

![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455798.png)

1. 分支预测算法为静态预测，向后跳转则预测为需要跳，否则预测为不需要跳；

2. 主要模块：
   
   1. e203_exu_oitf：Outstanding Instructions Track FIFO
      
      1. 功能：检测出与长指令的RAW和WAW相关性；
      
      2. fifo，深度为2表项，存储已派遣且尚未写回的长指令信息；
      
      3. 流水线的派遣（Dispatch ）点，每次派遣一个长指令，则会在 OITF 中分配一个表项（Entry），在这个表项中会存储该长指令的源操作数寄存器索引和结果寄存器索引；
   
   2. bpu：分支预测模块；
      
      1. 跳转方向：默认`Jal/Jalr`跳转，条件跳转指令只有立即数最高位为1（也就是立即数为负数，表示PC向后跳转）；
      
      2. 其中对`Jalr`特殊处理（通过判断目的寄存器大小，进行加速处理）：
         
         1. X0：取值为0；
         
         2. X1：是`ret`指令，因为`Jalr`指令大部分都是访问行X1,这里单独从寄存器组取值（这得益于蜂鸟为两级流水线架构，不必考虑流水线中含有未写回寄存器的指令；即使有也就下周期判断出跳转目标为错误，代价较小）；
         
         3. 其他：正常从寄存器组读取；

### IFU取指：

将预测地址低16位写入 `ifuitcm` 中取指，将会在下个时钟上升沿得到 64 bits数据；

1. 这里如果是32位指令，`addr`需要四字节掩码对齐；如果压缩指令，就会直接取最低16位，其余部分存入缓存中；
2. 其中内部含有一个缓存`Buffer`，参考《蜂鸟7.3.5 访问`ITCM`和`BIU`》；
3. 遇到ITCM之外的指令，通过`ifu2biu`接口，通过`BLU`模块访问`MEM`；
   1. ITCM中保存指令是通过上电Flash冲刷保存数据，但其中保存数据以是固定的（相当于地址映射：将`MEM`中一段内存放入`ITCM`中，同时也需要考虑`Load/Store`类型访问该段地址，因此此处还有`IFU`接口；）
   2. 大小为：1KB，0x8000处地址都在ITCM寻找，其余地址触发ICB总线；
   3. ITCM设计适用于低功耗小型处理器；

## ITCM：

**请先参考《e203 icb总线介绍》，了解ICB总线原理及其内部模块介绍**

        `IFU`有专门访问`ITCM`的数据通道(64位宽),同时 `ITCM` 也能够被 `load 、 store` 指令访问到用于存储数据,因此 `ITCM` 本身也是 `Memory`子系统的重要一部分。主体由一块数据宽度为`64`比特的单口` SRAM`组成 。`ITCM`的大小和基地址 (位于全局地址空间中的起始地址)可以通过 `config.v` 中的宏定义参数配置。

### 信号接口：

| Name  | Width            | Function                                        |
| ----- | ---------------- | ----------------------------------------------- |
| clk   | 1                | 时钟信号                                            |
| rst_n | 1                | 复位信号，低电平有效，**但此处并未使用**                          |
| sd    | 1                | `e203_cpu`设置为0                                  |
| ds    | 1                | `e203_cpu`内部设置为0                                |
| ls    | 1                | `e203_cpu`发出控制信号                                |
| din   | E203_ITCM_RAM_DW | 输入数据                                            |
| addr  | E203_ITCM_RAM_AW | 输入数据的地址                                         |
| cs    | 1                | 有效才可以进行读写                                       |
| we    | 1                | write enable；有效->write，无效->read；                |
| wem   | E203_ITCM_RAM_MW | wirte enable mask，默认4bits对应写入数据4byte，写入掩码每一位对应； |
| dout  | E203_ITCM_RAM_DW | 输出数据                                            |

### 模块简介

大小为64KB,内存地址范围为 `0x8000_0000 - 0x8000_ffff`；

ICB总线接口：

- 第一组`ICB`总线输入：数据宽度32位，LSU访问，用于上电存储数据；
- 另外两组`ICB`总线输入：数据宽度 64 位的 IFU 专用ICB 接口，数据宽度 32 位的外部直接访问（外部接口，便于其他外设访问）；
- 三组总线汇总为一组ICB总线，通过实例化`sirv_gnrl_icb_arbt`裁决输出给`ITCM`一组`ICB`信号；
- 优先级：LSU > 外部接口> IFU；

模块原理：

- 先`LSU、ITCM`外设`ICB`总线数据位宽通过实例化 `sirv_gnrl_icb_n2w` 扩展到64位；

- 通过实例化 `sirv_gnrl_icb_arbt` 仲裁，生成一组`icb`总线接口信号；

- 通过实例化 `sirv_sram_icb_ctrl` 模块将`icb`总线接口信号转换为`sram`接口信号以及`cmd、rsp`反馈信号；
  
  - 内部实例化 `sirv_gnrl_bypbuf` 模块，将`cmd`通道内输入信号缓存一周期，防止`ready`信号反压；
  - 实例化 `sirv_1cyc_sram_ctrl` 模块，将缓存`icb`总线信号处理生成相对应`sram`信号以及反馈信号；

- ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456006.png)

## DTCM：

### 信号接口：

| Name  | Width            | Function                                        |
| ----- | ---------------- | ----------------------------------------------- |
| clk   | 1                | 时钟信号                                            |
| rst_n | 1                | 复位信号，低电平有效，**但此处并未使用**                          |
| sd    | 1                | `e203_cpu`设置为0                                  |
| ds    | 1                | `e203_cpu`内部设置为0                                |
| ls    | 1                | `e203_cpu`发出控制信号                                |
| din   | E203_ITCM_RAM_DW | 输入数据                                            |
| addr  | E203_ITCM_RAM_AW | 输入数据的地址                                         |
| cs    | 1                | 有效才可以进行读写                                       |
| we    | 1                | write enable；有效->write，无效->read；                |
| wem   | E203_ITCM_RAM_MW | wirte enable mask，默认4bits对应写入数据4byte，写入掩码每一位对应； |
| dout  | E203_ITCM_RAM_DW | 输出数据                                            |

### 模块简介

+ `DTCM` 的存储器主体由一块数据宽度为32位的单口`SRAM`组成 。`DTCM`的大小和基地址（位于全局地址空间中的起始地址）可以通过 `config.v` 中的宏定义参数配置 。其大小为`64K`,内存范围为 `0x9000_0000 - 0x9000_ffff`。

+ `DTCM`有两组输入 `ICB`总线接口 ,分别来自于 `LSU` 和外部直接访问接口（`DTCM
  External ICB Interface`）。 `DTCM`外部直接访问接口是专门为`DTCM` 配备的外部接口,便于 `Soc` 的其他模块直接访问蜂鸟 `E203` 处理器核的 `DTCM` 。

+ 两组输入 `ICB` 总线经过一个“ `ICB` 汇合”模块将其汇合成为一组 `ICB`总线,采用的仲裁机制是优先级仲裁, `LSU`总线具有更高的优先级 。

+ 经过汇合之后的 `ICB` 总线的命令通道进行简单处理后作为访问 `DTCM SRAM`的接口 。 同时将此操作的来源信息寄存,并用寄存后的信息指示 `SRAM` 返回的数据分发给 `LSU` 和 `DTCM` 外部直接访问接口的反馈通道。

![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456642.png)

## ICB总线：

**详细请参考《e203 icb总线分析》《e203 icb总线简介》**

# SoC：

## Soc架构：

+ ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456146.png)
+ Soc总线微架构图：![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456881.png)

# 蜂鸟e203 测试环境

`vsim/bin/run.Makefile` 是蜂鸟E203项目中的一个辅助脚本，用于生成 `Makefile` 文件并执行仿真。这个脚本会根据当前的仿真设置，自动生成 `Makefile` 文件。`Makefile` 文件包含了编译、仿真和波形查看等多个目标，用于方便地管理仿真过程。
你可以在蜂鸟E203项目的 `vsim/bin` 目录下找到 `run.Makefile` 脚本，并执行以下命令来生成 `Makefile` 文件：

+ ./run.Makefile
  执行该命令后，`run.Makefile` 脚本会读取当前的仿真设置，并自动生成 `Makefile` 文件。生成的 `Makefile` 文件将包含多个目标，例如：
- `compile`: 编译 Verilog 源文件
- `sim`: 执行仿真
- `wave`: 查看波形
  你可以在终端中使用 `make` 命令来执行这些目标，例如：

```
make compile # 编译 Verilog 源文件

make sim     # 执行仿真

make wave     # 查看波形
```

需要注意的是，执行这些目标之前，你需要确认自己的仿真设置已经正确配置，并且所有依赖的工具和库已经正确安装。

# TODO：

## e203--合并文件脚本

请参考《e203 接入 iEDA 方式分析》《e203 启动方式分析》

# BUG：

1. 测试时，spi宏定义未找到：
   
   1. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619668.png)
   
   2. 修改：将filelist/perip.f中文件替换；
      
      ```diff
      diff --git a/filelist/perip.f b/filelist/perip.f
      index 3d68888..85c9816 100644
      --- a/filelist/perip.f
      +++ b/filelist/perip.f
      @@ -1,20 +1,8 @@
      ../perip/uart/rtl/uart_apb.v
      -../perip/spiFlash/N25Q128A13E_VG12/code/N25Qxxx.v
      ../perip/uart/tb/tty.v
      -../perip/uart/rtl/uart16550/raminfr.v
      -../perip/uart/rtl/uart16550/timescale.v
      -../perip/uart/rtl/uart16550/uart_defines.v
      -../perip/uart/rtl/uart16550/uart_receiver.v
      -../perip/uart/rtl/uart16550/uart_regs.v
      -../perip/uart/rtl/uart16550/uart_rfifo.v
      -../perip/uart/rtl/uart16550/uart_sync_flops.v
      -../perip/uart/rtl/uart16550/uart_tfifo.v
      -../perip/uart/rtl/uart16550/uart_transmitter.v
      -../perip/spi/rtl/spi_defines.v
      ../perip/spi/rtl/spi_clgen.v
      ../perip/spi/rtl/spi_shift.v
      ../perip/spi/rtl/spi_top.v
      ../perip/spi/rtl/spi_flash.v
      -../perip/chiplink/chiplink.v
      -../perip/chiplink/simmem.v
      -../perip/chiplink/top.v
      +../perip/spi/rtl/spi_defines.v
      +../perip/spiFlash/tb/spi_flash_tb.v
      ```

2. rtt忽略CLINT信号：
   
   - 运行时间大概15h左右,但还未显示消息框(msh)
   
   - BUG: RTT没有触发时钟中断，导致无法触发输出；
   
   - 原因：总线优先级搞错，把clint当成外部接口信号，在`e203_biu.v`屏蔽了，相当于时钟中断一直无法触发，导致无法输出时钟中断；
     ![imagepng](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304101507490.png)
   
   - 将clint信号正常输入就行；

# 测试：

1. 请参考`iverilog-soc`中`README`文件，测试`iverilog-soc`环境的正确性；

2. 在蜂鸟e203目录下，合并文件以及复制到`iverilog-soc/cpu`目录，可参看《e203 合并文件脚本》：

```
cd vsim
make clean
make ysyx               // 合并e203内所有.v文件
// 合并ysyx_210000.v 和e203文件，并复制到iverilog-soc。
// 注意需要您修改iverilog所对应的目录
```

3. 参看`iverilog-soc`中`README`，在`run`目录中执行
   
   ```
   make update-filelist 
   ```
   
   更新`iverilog-soc/filelist`，其中更新脚本存在问题，需要在修改`filelist/perip.f`，则可正确执行。
   
   ```
   diff --git a/filelist/perip.f b/filelist/perip.f
   index 9d6dc52..f279677 100644
   --- a/filelist/perip.f
   +++ b/filelist/perip.f
   @@ -6,3 +6,16 @@
    ../perip/spi/rtl/spi_top.v
    ../perip/uart/rtl/uart_apb.v
    ../perip/uart/tb/tty.v
   +../perip/chiplink/chiplink.v  
   +../perip/uart/rtl/uart16550/raminfr.v                                                                                                                                            
   +../perip/uart/rtl/uart16550/timescale.v                                                                                                                                          
   +../perip/uart/rtl/uart16550/uart_defines.v                                                                                                                                       
   +../perip/uart/rtl/uart16550/uart_receiver.v                                                                                                                                      
   +../perip/uart/rtl/uart16550/uart_regs.v                                                                                                                                          
   +../perip/uart/rtl/uart16550/uart_rfifo.v                                                                                                                                         
   +../perip/uart/rtl/uart16550/uart_sync_flops.v                                                                                                                                    
   +../perip/uart/rtl/uart16550/uart_tfifo.v                                                                                                                                         
   +../perip/uart/rtl/uart16550/uart_transmitter.v                                                                                                                                             
   +../perip/spiFlash/N25Q128A13E_VG12/code/N25Qxxx.v       
   +../perip/chiplink/simmem.v                                                                                                                                                       
   +../perip/chiplink/top.v 
   ```

4. 现在可以测试`iverilog-soc`测试了；

## 测试结果：

请查看《test》
