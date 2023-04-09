**TODO**：将e203 添加AXI4总线接口，并将其放在top接口，与ysyx_soc对接：
1. e203 接入AXI结构图：
	1. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304091726227.png)
	2. ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304091726325.png)
2. 注意：
	1. ysyx-soc中地址范围太大，e203无法满足：首先e203_biu.v中将ITCM、DTCM、ppi、fio拉低，使其访问mem（mem优先级最低）；其中系统存储总线不需要太大的地址映射，故其他模块删除，只留下一个icb2axi接口；（详细见e203 接入iEDA方式分析）
	2. 在蜂鸟内部实现的icb2axi模块为32位并且没有**id**信号。由于这里master与slave是一对一，所以强制每个通道的id信号为0，防止后面接入soc，id为高阻态；

### 2. 32位ICB总线转64位AXI4总线
1. 步骤：
    1.  `203_subsys_mems.v`：将原先32位`icb2axi`模块注释，然后实例化模块`sirv_gnrl_icb_n2w` ，将icb总线的数据位宽扩宽为 64bits；
    2.  实例化`icb2axi`模块，将64位icb总线转换为64位AXI4总线。
	    1. 通过在E203测试环境中，其中axi接口使用E203内部axi_slave，通过测试；
	    2. 注意：axi_slave模块：只含有axi总线接口，内部无数据返回，用来验证模块间连接的正确性；
    3.  将AXI总线接口放在顶层接口；
	    1. 同理步骤2，通过在E203测试环境中，在外层搭建一个测试模块(e203_soc_axi_top.v)，其中在顶层axi接口使用E203内部axi_slave，通过测试；
2.  E203_SOC测试：
    1.  ![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304091726371.png)
    2.  蜂鸟E203回归测试：![](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304091726430.png)
### 3. 32位ICB总线转32位AXI4总线：
1. 步骤：
	1.  `e203_subsys_mems.v`：32位`icb2axi`模块直接与模块传输信号对接，得到总线信号转换；
	2. 将AXI4接口拉到最顶层，连接ysyx-soc；
2. 测试：
	1. 添加`hello-riscv32-mycpu.flash`到iverilog-soc/prog目录中；
```diff
diff --git a/run/Makefile b/run/Makefile
index 6010451..3705ec3 100644
--- a/run/Makefile
+++ b/run/Makefile
@@ -53,8 +53,7 @@ FILE_LIST += -f ../filelist/ram.f
 endif
 
 link-hello:
-#	# @ln -sf ../prog/hello.flash mem_Q128_bottom.vmf
-	@ln -sf ../prog/hello-riscv32-mycpu.flash mem_Q128_bottom.vmf
+	@ln -sf ../prog/hello.flash mem_Q128_bottom.vmf
 	@ln -sf ../prog/memtest.ram init_mem.bin.txt
 	@ln -sf ../perip/spiFlash/N25Q128A13E_VG12/sim/sfdp.vmf sfdp.vmf
 	@echo "link-hello ok!"
@@ -84,11 +83,9 @@ run: comp
 	@python3 ../script/perf.py -s
 
 wave:
-	vcd2fst -v $(WAVE_FILE) soc_tb.fst
-	$(WAVE_TOOL) soc_tb.fst
+	$(WAVE_TOOL) $(WAVE_FILE)
 
 clean:
-#	rm -rf asic_top.vcd* *.log a.out
-	rm -rf *.vcd *.log *.fst a.out *.txt *.vmf
+	rm -rf asic_top.vcd* *.log a.out
 
 .PHONY: update-filelist comp run wave
\ No newline at end of file
```

 2. 修改Makefile中link-hello软链接目标，使其读取添加的flash数据；
 3. 通过ysyx-soc测试，可以正确打印hello：![image.png](https://zpnmh.oss-cn-beijing.aliyuncs.com/img2/202304091726507.png)