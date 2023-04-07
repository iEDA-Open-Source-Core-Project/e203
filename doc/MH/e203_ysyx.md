
# 一、蜂鸟e203

# 二、TODO：

## 1、 e203--合并文件脚本

1. 介绍：
   1. 功能：将E203的soc(包含头文件)合并到e203_soc_top.v，tb（包含头文件）合并为tb_top.v；
      - 注意：tb仅用于在e203项目中测试e203_soc_top.v的正确性；
   2. 脚本路径：`vsim/mergefile_nice.py`;
   3. 修改 `vsim/Makefile`：将 `make install`下复制 e203_soc代码部分替代为执行mergefile_nice.py脚本；
   4. ![e203目录树](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304012210865.png)

## 2、e203/BLU添加axi外设接口:

### 1. TODO：

    将e203 添加64位AXI4总线接口，并将其放在top接口，与ysyx_soc对接：

1. 结构图：
   1. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304012218357.png)
   2. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304012219357.png)
2. 注意：
   1. ysyx-soc中地址范围太大，e203无法满足：首先e203_biu.v中将ITCM、DTCM、ppi、fio拉低，使其访问mem（mem优先级最低）；其中系统存储总线不需要太大的地址映射，故其他模块删除，只留下一个icb2axi接口；
   2. 在蜂鸟内部icb2axi并没有**id**信号，由于这里master与slave是一对一，所以强制每个通道的id信号为0，防止后面接入soc，id为高阻态；

### 2. 32位ICB总线转64位AXI4总线

1. 步骤：
   1. e203_subsys_mems.v：将原先32位icb2axi模块注释，然后实例化模块sirv_gnrl_icb_n2w ，将icb总线的数据位宽扩宽为 64bits；
   2. 实例化icb2axi模块，将64位icb总线转换为64位AXI4总线 --- 通过在E203测试环境中，其中axi接口使用E203内部axi_slave，通过测试；
      1. 注意：axi_slave模块：只含有axi总线接口，内部无数据返回，用来验证模块间连接的正确性；
   3. 将AXI总线接口放在顶层接口 --- 同理步骤2，通过在E203测试环境中，在外层搭建一个测试模块(e203_soc_axi_top.v)，其中在顶层axi接口使用E203内部axi_slave，通过测试；
2. E203_SOC测试：
   1. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304012229303.png)
   2. 蜂鸟E203回归测试：![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304012229402.png)

### 3. 32位ICB总线转32位AXI4总线：

1. 步骤：
   1. e203_subsys_mems.v：32位icb2axi模块直接与模块传输信号对接，得到总线信号转换；
   2. 将AXI4接口拉到最顶层，连接ysyx-soc；
2. 测试：
   1. 添加hello-riscv32-mycpu.flash到iverilog-soc/prog目录中；
   2. 修改Makefile中link-hello软链接目标，使其读取添加的flash数据；
   3. 通过ysyx-soc测试，可以正确打印hello：![image.png](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304062208767.png)

## 3、 iverilog-soc修改：

1. 修改外设；
2. 将ITCM、DTCM注释以及删除一些无用外设，修改e203启动时内存映射位置：0x8000_0000 -> 0x3000_0000;
3. 将e203接入iverilog-soc，但遇到问题；
   1. E203支持brust=01传输；![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071447383.png)
4. 正确AXI4总线波形图：
   1. ar、r通道：![image-20230402105442133](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304061904940.png)
   2. aw、w、b通道：![image-20230402105404191.png](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304071449786.png)

# 三、BUG：

1. 测试时，spi宏定义未找到：![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304021029699.png)

   1. 修改：将filelist/perip.f中文件替换；![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304021031652.png)
2. 介入iverilog-soc时，ar通道发出数据请求，信号握手，但等不到r通道返回数据：![image-20230402110619372](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304061904076.png)

   1. 解决：每个通道id为高阻态，导致slave无法返回数据；
