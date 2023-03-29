## e203 总体架构分析
>[1. Overview — Hummingbirdv2 E203 Core and SoC 0.2.1 documentation](https://doc.nucleisys.com/hbirdv2/overview/overview.html)


![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303271027543.png)
蜂鸟 e203 的存储架构被分为了三个部分
+ 片内 ITCM
+ 片内 DTCM
+ 挂载在 BIU 上的 FLASH 

参考 **e203 启动方式分析** 就可以知道，`e203` 是如何加载程序的。关于在 `手把手教你设计CPU` 中关于取指令的描述。
1. 根据地址划分选择访问 `ITCM` 或 `FLASH`
2. 假设绝大多数的访问都发生在 `ITCM` 
其中取指令可以在，`ITCM` 和 `FLASH` 中发生。

## iEDA 框架分析
![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303262243041.png)

1. RCG 为处理器核心提供时钟和复位
2. `处理器核` 通过一组 axi4 接口连接到 `IEDA` 的 `Crossbar`
3. `Crossbar` 内部将 `AXI` 的访问分发到各个外设设备


## 接入方式分析
![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303271120156.png)

将 `iEDA` 中 `CrossBar` 部分作为一个整体，如上图所示。假设这个整体为 `A`，则可以将 `A` 视为一个具有 `AXI4` 接口的外设。


![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303271129065.png)

1. 如上图所示，`e203` 的 `ifu` 和 `lsu` 两个流水线结构通过自定义 `ICB` 总线连接到 `BIU` 上 (`BIU` 就类似于 `iEDA` 中的 `CrossBar` ) 
2. 将 `A` 作为一个外设接入到 `BIU` 并为其在 `BIU` 上分配空间，就像 `E203` 的其他外设一样。 

**主要工作**
1. 实现 `AXI4` 和 `ICB` 的转接
2. 重新在 `BIU` 中划分地址空间



## 地址空间划分

**iEDA内部地址**

![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303271855557.png)

| 设备               | 地址空间                  |
| ------------------ | ------------------------- |
| Reserve            | `0x0000_0000~0x01ff_ffff` |
| CLINT              | `0x0200_0000~0x0200_ffff` |
| Reserve            | `0x0201_0000~0x0fff_ffff` |
| UART16550          | `0x1000_0000~0x1000_0fff` |
| SPI                | `0x1000_1000~0x1000_1fff` |
| VGA                | `0x1000_2000~0x1000_2fff` |
| PS2                | `0x1000_3000~0x1000_3fff` |
| Ethernet           | `0x1000_4000~0x1000_4fff` |
| Reserve            | `0x1000_5000~0x1bff_ffff` |
| Frame Buffer       | `0x1c00_0000~0x2fff_ffff` |
| SPI-flash XIP Mode | `0x3000_0000~0x3fff_ffff` |
| ChipLink MMIO      | `0x4000_0000~0x7fff_ffff` |
| MEM                | `0x8000_0000~0xfbff_ffff` |
| SDRAM              | `0xfc00_0000~0xffff_ffff` |


其中 `Clint` 设备需要处理器核自己实现，因此将 0x000_0000 ---> 0x0fff_ffff 留给 e203 使用，总共还有 256MB 的地址空间可以使用

**E203 内部地址**
>[3. Hummingbirdv2 SoC Peripherals — Hummingbirdv2 E203 Core and SoC 0.2.1 documentation](https://doc.nucleisys.com/hbirdv2/soc_peripherals/ips.html#overview)


![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303271931515.png)
虽然对原 SoC 的总线进行了修改,但是所有外设的总线地址分配表仍然完全与
kon原始的 Freedom E310 SoC 一致
![image.png](https://cdn.jsdelivr.net/gh/leesum1/doc/img/202303271933982.png)

```
  // The total address range for the PPI is from/to
  //  **************0x1000 0000 -- 0x1FFF FFFF
  // There are several slaves for PPI bus, including:
  //  * AON       : 0x1000 0000 -- 0x1000 7FFF
  //  * HCLKGEN   : 0x1000 8000 -- 0x1000 8FFF
  //  * GPIOA     : 0x1001 2000 -- 0x1001 2FFF
  //  * UART0     : 0x1001 3000 -- 0x1001 3FFF
  //  * QSPI0     : 0x1001 4000 -- 0x1001 4FFF
  //  * PWM       : 0x1001 5000 -- 0x1001 5FFF
  //  * UART1     : 0x1002 3000 -- 0x1002 3FFF
  //  * QSPI1     : 0x1002 4000 -- 0x1002 4FFF
  //  * I2C0      : 0x1002 5000 -- 0x1002 5FFF
  //  * UART2     : 0x1003 3000 -- 0x1003 3FFF
  //  * QSPI2     : 0x1003 4000 -- 0x1003 4FFF
  //  * I2C1      : 0x1003 5000 -- 0x1003 5FFF
  //  * GPIOB     : 0x1004 0000 -- 0x1004 0FFF
  //  * Example-AXI      : 0x1004 1000 -- 0x1004 1FFF
  //  * Reserved         : 0x1004 2000 -- 0x1004 2FFF
  //  * SysPer    : 0x1100 0000 -- 0x11FF FFFF


  // There are several slaves for Mem bus, including:
  //  * DM        : 0x0000 0000 -- 0x0000 0FFF
  //  * MROM      : 0x0000 1000 -- 0x0000 1FFF
  //  * QSPI0-RO  : 0x2000 0000 -- 0x3FFF FFFF
  //  * SysMem    : 0x8000 0000 -- 0xFFFF FFFF
  
  // There are several slaves in the e203 core
  //  * PLIC      : 0X0C00 0000 -- 0X0CFF FFFF
  //  * CLINT     : 0X0200 0000 -- 0X0200 FFFF
  //  * ITCM      : 0X8000 0000 -- 
  //  * DTCM      : 0X9000 0000 --
  //  * FIO       : 0Xf000 0000 --

  
```
`E203` 具体来说有三条总线
1. E203 Core 总线
2. Mem Bus 总线
3. PPI 总线 （私有设备总线）

并且 `E203 Core` 核内总线上挂载的设备的地址范围和
`Mem Bus` 上挂载的设备的地址范围重合。`E203` 在核内有一个地址判断，首先判断是不是 `核内设备` ，然后再判断其他总线。具体来说，就是 `核内总线` 优先级大于 `Mem Bus` 和 `PPI bus` 。

**E203 核内总线**
设备直接固化在 `E203` 核心内
1. ITCM
2. DTCM
3. PLIC
4. CLINT
5. FAST IO

`IFU` 能访问的只有 `ITCM` ，`LSU` 可以访问全部设备

**Mem Bus 总线**

`Mem Bus` 很有意思，在 `Mem Bus` 上挂载的设备 `IFU` 和 `LSU` 都可以访问。并且 `QSPI-Flash` 同时挂载在 `Mem Bus` 和 `PPI Bus` 上面。  

![](https://cdn.jsdelivr.net/gh/leesum1/doc/img/2023-03-29_11-14.png)

**PPI Bus**

私有设备总线上挂载的设备只能由 `LSU` 访问，挂载各种通用的设备。

## 准备方案

将 `iEDA` 作为一个 `Mem` 设备挂载在 `Mem Bus` 上，为了就是能够让 `IFU` 和 `LSU` 能够同时访问。

重新划分 `E203` 地址空间，为 `Mem Bus` 扩展地址空间，足够容纳 `iEDA` 。

**具体实现细节**
1. FIO 去除，清理地址空间
2. PPI 去除，清理地址空间
3. PLIC 外设中断信号至0
4. ITCM 和 DTCM 地址映射改写
5. 将 `iEDA` 接入 `Mem Bus` ，地址空间映射为 0X1000_0000 -- 0XFFFF_FFFF

**目前的困难**
1. `E203` 自带的仿真测试程序中，用到了 `PPI` 总线上的设备，去除后仿真失败
2. `iEDA` 地址范围太大，修改时测试困难







