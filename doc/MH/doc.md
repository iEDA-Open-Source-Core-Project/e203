# 蜂鸟e203:
## 寄存器：
### sirv_sim_ram：
- 功能：仿真SRAM，将x不定态->0
- 信号参数：
    - FORCE_X2ZERO：有效->输出不定态变为0；
    - DP：
    - DW：din width；
    - AW：addr width；
    - MW：mask width；`
- 信号接口：
    - wem：wirte enable mask，默认4bits对应写入数据4byte，写入掩码每一位对应；
    - cs：有效才可以进行读写；
    - we：write enable；有效->write，无效->read；
### sirv_gnrl_ram：ram顶层
- sd、ds、ls，无用信号；
- sirv_gnrl_dfflr：通过always块编写寄存器逻辑；
-   ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454880.png)
- sirv_gnrl_icb_n2w：位宽转换模块 将lsu32位换为64位；
- sirv_gnrl_icb_arbt：ICB总线仲裁模块；
- sirv_gnrl_fifo：通过配置DP大小，从而得到不同深度的fifo；
    - 0：单口ram；
    - 1：ready信号与下一级ready信号相关，需要使用CUT_ready控制->1可以切断反压信号，两个周期传递一次数据；
    - 大于1：fifo，CUT_READY无实际意义；
    - 注意：在蜂鸟中，DP只有1或者2，也就是说要么是控制ready信号，反压；要么是一个深度为2的fifo；
### buf
+ sirv_gnrl_pipe_stage：DP=0，o_dat=i_dat；
-  相当于将输入信号打一拍；
### sirv_sram_icb_ctrl：
-   定义：The icb_ecc_ctrl module control the ICB access requests to SRAM ；
    -   内部定义一个bypbuf（含有fifo的bypass buffer），悬空一级流水线，以减少反压ready信号（通过将输入、输出信号拼接成总线信号传输）；
-   参数：
    -   sram_ctrl_active：高电平sram工作；
    -   tcm_cgstop：来自csr mcgstop（0xBFE）控制，蜂鸟自定义，主要用于禁用在debug 中 ITCM中的SRAM门控时钟；

## 模块介绍：
1. ECC：Error Checking and Correction 
    1.  保护SRAM，可以对1位错误纠正，2位错误上报系统；
    2.  蜂鸟中对ITCM、DTCM中SRAM进行保护；

# 架构：
-   e203目录树：
![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454707.png)

### e203 core：
1.  2级流水线处理器核；
2. 支持RV32IEMAC指令集；
3.  机器模式；
    1.  CLINT：计时器中断、软件中断；
    2.  PLIC：外部中断， Platform Level Interrupt Controller；用于多个外部中断源的优先级仲裁和派发；
        1.  是一个存储器地址映射（Memory Address Mapped）的模块，挂载在处理器核为其实现的专用总线接口上；
    3.  地址非对齐（Address Misalign）：与Rocket Core 采用软件支持，AGU 通过对生成 出的访存地址进行判断，如果其地址非对齐，则产生异常标志；
    4.  自定义CSR：mcounterstop
	    1. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454984.png)
4.  SoC总线：ICB-Internal Chip Bus，内核+Soc总线；
    1.  AXI相关特点：
        1.  简单，仅有两个独立通道-读写共用**地址通道**，公用结果**返回通道**；
        2.  地址、数据分离；
        3.  地址区间寻址，支持任意的主从数目；
        4.  支持地址非对齐的数据访问，字节掩码（Write Mask）控制写操作；
        5.  支持多个_**滞外交易**_（Multiple Outstanding Transaction）
    2.  AHB相关特点：
        1.  每个读/写都会在**地址通道**上产生地址；
        2.  不支持乱序返回、乱序完成，返回通道数据顺序返回结果；
    3.  协议信号：![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071454873.png)
    4.  时序：详细请参考《蜂鸟E203开源Soc介绍》第四章
        1.  写操作同一周期返回结果；
        2.  读操作下一周期返回结果
5.  SOC框图：
    1.  ![overview_fig1](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619152.jpeg)
    2.  ![core_fig1](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619194.jpeg)
    3.  ![core_fig2](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619225.jpeg)
## IFU：
![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455798.png)
1.  分支预测：静态，向后跳转为真；
-   e203_exu_oitf：Outstanding Instructions Track FIFO
    -   功能：检测出与长指令的RAW和WAW相关性；
    -   fifo，深度为2表项，存储已派遣且尚未写回的长指令信息；
    -   流水线的派遣（Dispatch ）点，每次派遣一个长指令，则会在 OITF 中分配一个表项（Entry），在这个表项中会存储该长指令的源操作数寄存器索引和结果寄存器索引；
-   bpu：静态，向后跳转，向前不跳；
    -   跳转：默认JAL/JALR跳转，b*** 只有立即数最高位为1（负数，向后跳转）
    -   JALR特殊处理：
        -   X0：；
        -   X1：；
        -   其他：；
### IFU取指：
1.  将预测地址低16位写入 ifuitcm 中取指，将会在下个时钟上升沿得到 64 bits数据；
    1.  这里如果是32位指令，addr需要四字节掩码对齐；如果压缩指令，就会直接取最低16位，其余部分存入缓存中；
    2.  其中内部含有一个缓存Buffer，参考蜂鸟7.3.5访问ITCM和BIU；
2.  疑问：
    1.  若将AXI以外设接入，取指都是经过ITCM，但ITCM大小有限，遇到ITCM之外的指令呢？
        1.  那么取指是不经过ITCM接口，而是用过ifu2biu接口，通过BLU模块访问MEM；
    2.  ITCM中保存指令是通过上电Flash冲刷保存数据，但其中保存数据以是固定的。
##### ift2icb;
1.  ifu2biu_icb_cmd_valid：
    1.  ifu_icb_cmd_valid：
    2.  ifu_icb_cmd2biu：_当有ITCM时，0x8000处地址都在ITCM寻找，其余地址触发ICB总线_
## EXU：
![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455363.png)
### OITF：
-   Outstanding Instructions Track FIFO，深度为2表项的FIFO；
- ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455529.png)
## WB：
-   ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455114.png)
    -   只要前序指令没发生“分支预测错误”、“中断”、“异常”就成功交付；
-  ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455385.png)
### MEM：
-   AGU：Address Generation Unit
    -   Load、store、“A“扩展指令的地址生成，以及”A“扩展指令的微操作拆分和执行；
    -   整个存储器访问指令执行的一个小环节！！！！
    -   含**有ICB接口**
-   LSU：Load Store Unit ---参考11.4.3 P191
    -   ICB总线 ：输入AGU、EAI；输出：BIU、DTCM、ITCM；
    -   学习知识点：ICB汇合、ICB分发--第12章
    -   ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071624099.png)
-  ![image.png](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071629802.png)

-  ITCM：
    -   sram接口信号：ds、sd低电平，ls为cpu发出信号，目前还不知道功能（cpu->ITF-- ICB Interface from Ifetch应该为clk_ctrl）；
    -   ICB总线接口：
        -   一组输入：数据宽度32位，LSU访问，用于上电存储数据；
        -   两组输入：数据宽度 64 位的 IFU 专用ICB 接口，数据宽度 32 位的外部直接访问（外部接口，便于其他外设访问）；
        -   三组总线汇总为一组ICB总线，优先级：LSU > 外部接口> IFU；
    -   64位单口SRAM，可配置大小（LSU、ITCM位宽位32位，需要数据转换）；
    -   模块原理：
        -   先LSU、ITCM外设 数据位宽通过实例化 **sirv_gnrl_icb_n2W** 扩展到64位（ext2itcm -> ext）；
        -   然后将二者将其控制信号拼接为位宽*2的信号（{ext，lsu} ->arbt_bus），通过实例化 **sirv_gnrl_icb_arbt** 仲裁（主要是仲裁LSU与ext优先级，arbt_bus -> arbt）；
        -   然后将仲裁arbt信号与ifu选择通过优先级（IF > LSU > 外设）控制，生成icb接口信号；
        -   通过实例化 **sirv_sram_icb_ctrl** 模块将icb接口信号转换为sram接口信号以及cmd、rsp反馈信号；
            -   内部实例化 sirv_gnrl_bypbuf 模块，将cmd 输入信号缓存一周期，防止ready反压；
            -   实例化 sirv_1cyc_sram_ctral 模块，将缓存icb总线信号处理生成相对应sram信号以及反馈信号；
    -   ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071455594.png)
    -  ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456006.png)
-   DTCM：
    - ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456642.png)
    -   32位单口SRAM；
    -   两组ICB输入总线，LSU、外部直接访问接口，同理汇总为一条总线，LSU>外部接口；
-   "A"扩展指令处理：在多线程情形下访问存储器的原子（Atomic）操作或者同步操作
    -   Load-Reserved和Store-Conditonal：LSU设置互斥检测器（EXclusive Monitor）；
    -   AMO（Atomic Memory Operation）指令；
-   Fence指令：
    -   RISC-V架构采用松散存储器模型，松散存储器模型对于访问不同地址的存储器读写指令的执行顺序不作要求，除非使用明确的存储器屏障指令（Fence、Fence.I：用于强行界定存储器访问的顺序）；
        -   在程序中，如果添加了 Fence 指令，则 Fence 指令能够保证“在 Fence 之前所有指令造成的访存结果”必须比“在 Fence 之后所有指令造成的访存结果”先被观测到。
        -   在程序中，如果添加了 Fence .I 令，则“在 Fence.I 之后所有指令的取指令操作” 定能够观测到“在 Fence.I 之前所有指令造成的访存结果”；
    -   处理：蜂鸟——fence当成 fence iorw，iorw指令实现；在流水线派遣点，必须等待所有已经滞外的指令执行完毕；
## ICB：
-  ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456722.png)
    -   fifo：支持滞外交易，主要用于仲裁输出反馈信号；
    - ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456594.png)
    - ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456228.png)
### ICB2AXI:
+ 功能：将32位ICB总线转换为AXI总线；
-  注意：
	- ICB不支持brust；
	- 转换后的AXI总线不包含每个通道的**id**信号；
## SoC：
### 1. Soc总线图：
![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456146.png)
### 2. Soc总线微架构图：
![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456881.png)
## EAI：16章
-  ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456625.png)
-   **滞外指令**：Custom指令从被发送至协处理器到协处理器反馈并退役之间的时间；（不超过4条）
-   读写存储器优先级：协处理器>主处理器指令

# Code：
1.  **ICB在ALU模块中处理wdata与wmask**；
    1.  优点：通过与非逻辑将数据与控制信号绑定；
    2.  不懂：addr怎么设定的？？？应该是4bits，每一位代表8位；
	![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071456706.png)
2.  `vsim/bin/run.Makefile` 是蜂鸟E203项目中的一个辅助脚本，用于生成 `Makefile` 文件并执行仿真。这个脚本会根据当前的仿真设置，自动生成 `Makefile` 文件。`Makefile` 文件包含了编译、仿真和波形查看等多个目标，用于方便地管理仿真过程。
    你可以在蜂鸟E203项目的 `vsim/bin` 目录下找到 `run.Makefile` 脚本，并执行以下命令来生成 `Makefile` 文件：
    + ./run.Makefile
    执行该命令后，`run.Makefile` 脚本会读取当前的仿真设置，并自动生成 `Makefile` 文件。生成的 `Makefile` 文件将包含多个目标，例如：
    -   `compile`: 编译 Verilog 源文件
    -   `sim`: 执行仿真
    -   `wave`: 查看波形
    你可以在终端中使用 `make` 命令来执行这些目标，例如：
    + make compile  # 编译 Verilog 源文件  
    + make sim      # 执行仿真  
    + make wave     # 查看波形
    需要注意的是，执行这些目标之前，你需要确认自己的仿真设置已经正确配置，并且所有依赖的工具和库已经正确安装。

# 二、TODO：

## 1、 e203--合并文件脚本
	《e203合并文件脚本》

## 2、e203/BLU添加axi外设接口:
`《e203 ICB转换AXI》`
## 3、 iverilog-soc修改：
`《e203 接入iEDA方式分析》`
1.  修改外设；
2.  将ITCM、DTCM注释以及删除一些无用外设，修改e203启动时内存映射位置：0x8000_0000 -> 0x3000_0000;
3.  将e203接入iverilog-soc，但遇到问题；
    1.  E203支持brust=01传输；![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619513.png)
4.  正确AXI4总线波形图：
    1.  ar、r通道：![image-20230402105442133](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619564.png)
    2.  aw、w、b通道：![image-20230402105404191.png](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071619606.png)


# 三、BUG：
1.  测试时，spi宏定义未找到：
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
