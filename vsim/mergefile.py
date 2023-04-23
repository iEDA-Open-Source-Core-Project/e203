from importlib.metadata import files
import os

#coreFiles = os.popen('find ./../rtl/e203/core -name "*.v"').read()  # core all *.v paths
e203Files = os.popen('find ./../rtl/e203/core -name "*.v"').read()                                # core all *.v paths

tbFiles = os.popen('find ../tb -name "tb_top.v"').readline().rstrip('\n')                                        # tb file paths
E203con = os.popen('find ./../rtl/e203/core -name "config.v"').readline().rstrip('\n')
E203def = os.popen('find ./../rtl/e203/core -name "e203_defines.v"').readline().rstrip('\n')
#I2Cdef = os.popen('find ./../rtl/e203/core -name "i2c_master_defines.v"').readline().rstrip('\n')

e203def = open(E203def).read()
e203def = e203def.replace('`include "config.v"', "")

#print(e203Files)
#print(tbFiles)
############################## TB #############################
tb = open("./install/tb/tb_top.v", "w") # write file
tb.truncate()
tb.write(open(E203con).read())
tb.write(e203def)

f=open(tbFiles).read()
f = f.replace('`include "e203_defines.v"', "")
tb.write(f)
print('TB is ok')
#tb.write(open(tbFiles).read())
tb.close()

############################## core #############################
log = open("./install/rtl/core/e203_cpu_top.v", "w")  # 打开文件
log.truncate()
log.write(open(E203con).read())
log.write(e203def)

for path in e203Files.splitlines():
    if path.find("config.v")!=-1:
        continue
    if path.find("e203_defines.v")!=-1:
        continue
    if path.find("i2c_master_defines.v")!=-1: # 配置文件需要放在最顶部
        continue

    f = open(path).read()                         # 将打开的文件内容保存到变量f
    f = f.replace('`include "e203_defines.v"', " ")  #  include 去除
#    f = f.replace('ysyx_041514_soc','ysyx_041514')# 模块名称替换，满足端口要求

    log.write(f)  # 写入文件
#    print('已经合并：' + path)
log.close()
print('Core is ok')
