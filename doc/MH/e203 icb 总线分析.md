## 时序图
> 参考《手把手教你设计 RISC-V 处理器》


## 地址范围判断
在我参加`一生一芯` 时，也需要对总线的地址范围进行判断来确定哪一部分是需要进行 `Cache` 缓存的。我当时是这样写的
```verilog
assign in_area = addr>=low && addr<high
```
这样写确实可以满足需求，消耗的逻辑元件也会比较多，至少从明面上来看会有两个比较器

**E203 ICB 总线的地址范围判断**

`E203` 将几大总线的地址范围全都在 `config.v` 文件里通过宏定义的方式标出来了。下面我用 `PPI` 总线来举例。
```verilog
// `E203_CFG_ADDR_SIZE 为 32
//   * PPI       : 0x1000 0000 -- 0x1FFF FFFF
`define E203_CFG_PPI_ADDR_BASE  `E203_CFG_ADDR_SIZE'h1000_0000
// (32-1:32-4)-->(31:28) 即地址高 4 位 --> (32'h1000_0000 : 32'h1fff_ffff) 分配给PPI
`define E203_CFG_PPI_BASE_REGION  `E203_CFG_ADDR_SIZE-1:`E203_CFG_ADDR_SIZE-4
```

具体使用方法如下：
```verilog
 // ppi_region_indic 等于 E203_CFG_PPI_ADDR_BASE
 // E203_PPI_BASE_REGION 等于 E203_CFG_PPI_BASE_REGION
  wire buf_icb_cmd_ppi = ppi_icb_enable & (buf_icb_cmd_addr[`E203_PPI_BASE_REGION] ==  ppi_region_indic[`E203_PPI_BASE_REGION]);
```

乍一看可能会很茫然，但其实原理很简单，就是通过比较地址的高 4 位来确定是否在范围内，通过高位来限制范围。
![](https://cdn.jsdelivr.net/gh/leesum1/doc/img/icb%E5%9C%B0%E5%9D%80%E5%88%A4%E6%96%AD.drawio1.png)
这样做无疑减少了逻辑器件的消耗，但是是粗细粒度的控制。这种范围控制方式有点类似于计算机网络中子网掩码的概念（原理上应该是一样的）。


知道原理后，再去看 `icb` 总线扩展模块 `rtl/e203/fab/sirv_icb1to16_bus.v`，就不会像开始那样一脸茫然了。我截了一部分来分析原理
![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202304181517305.png)
这是一个将一个 `icb` 总线扩展为 16 个 `icb` 总线的模块，仲裁方式是固定优先级，具体实现方式我也没有深究，在这里仅仅分析一些地址的划分。地址划分主要与两个配置参数有关 `BASE_ADDR` `BASE_REGION_LSB`，以 `AON` 为例：
```verilog
  //  * AON       : 0x1000 0000 -- 0x1000 7FFF
  .O0_BASE_ADDR       (32'h1000_0000),       
  .O0_BASE_REGION_LSB (15),
```

`O0_BASE_ADDR` 确定起始地址
`O0_BASE_REGION_LSB` 确定地址范围所需要的位数，从低位开始
将 `0x1000 0000 -- 0x1000 7FFF` 转换为 2 进制后如下图所示，就可以按照上面所说，通过比较高位蓝色的部分来确定地址范围了。
![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202304181529359.png)
