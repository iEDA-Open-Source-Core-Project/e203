import glob
import os
import logging

# 配置日志输出格式
logging.basicConfig(
    level=logging.DEBUG,
    format='%(levelname)s - %(message)s')
    # format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

# 查找文件路径
e203Path = os.path.join('..', 'rtl', 'e203')
tbPath = os.path.join('..', 'tb')

# e203Files = glob.glob(os.path.join(e203Path,'core', '*.v'))
e203Files = glob.glob(os.path.join(e203Path, '**', '*.v'))           # 寻找e203子目录下所有文件
apbFiles = glob.glob(os.path.join(e203Path, '**', '**','*.v'))       # 寻找e203子子目录下所有文件
allFiles = e203Files + apbFiles
# ##################### opt ####################################
# 如果您想要优化这段代码，可以考虑使用os.walk函数来代替glob.glob函数。
# os.walk函数可以递归遍历目录树，返回每个目录及其子目录中的文件和子目录。

# 以下是使用os.walk函数来寻找所有的.v文件的示例代码：

# vFiles = []
# for root, dirs, files in os.walk(e203Path):
    # for file in files:
        # if file.endswith('.v'):
            # vFiles.append(os.path.join(root, file))
# 该代码递归遍历e203Path目录及其子目录中的所有文件和子目录，对于每个子目录，
# os.walk函数会返回当前目录的路径、子目录的名称列表和文件的名称列表。
# 通过判断文件的扩展名是否为.v，将符合条件的文件路径添加到vFiles列表中。
# 
# 使用os.walk函数的好处在于不需要使用glob.glob函数进行多次查找，而是一次性遍历整个目录树，可以提高代码的效率。
# 

tbFiles = glob.glob(os.path.join(tbPath, 'axi_tb_top.v'), recursive=True)
# tbFiles = glob.glob(os.path.join(tbPath, 'tb_top.v'), recursive=True)
E203con = os.path.join(e203Path, 'core', 'config.v')
E203def = os.path.join(e203Path, 'core', 'e203_defines.v')
E203i2c = os.path.join(e203Path, 'perips', 'apb_i2c', 'i2c_master_defines.v')

# 输出文件数量
print('Found {} e203 files'.format(len(allFiles)))

# 输出文件列表
for file in allFiles: print(file)

# 读取文件内容
with open(E203def) as f:
    e203def = f.read()
    e203def = e203def.replace('`include "config.v"', "")

# 合并测试台文件
with open('./install/tb/tb_top.v', 'w') as tb:
    tb.write(open(E203con).read())
    tb.write(e203def)
    for path in tbFiles:
        with open(path) as f:
            content = f.read()
            content = content.replace('`include "e203_defines.v"', "")

            tb.write(content)
    logging.info('TB is ok')

# 合并 RTL 文件
# with open('./install/rtl/core/e203_cpu_top.v', 'w') as log:
with open('./install/rtl/e203_soc_top.v', 'w') as log:
    log.write(open(E203con).read())
    log.write(open(E203i2c).read())
    log.write(e203def)
    for path in allFiles:
    # for path in e203Files:
        filename = os.path.basename(path)
        if filename in ['config.v', 'e203_defines.v', 'i2c_master_defines.v']:
            continue
        ext = os.path.splitext(filename)[1]
        if ext == '.v':
            with open(path) as f:
                content = f.read()
                content = content.replace('`include "e203_defines.v"', "")
                content = content.replace('`include "i2c_master_defines.v"', "")
                log.write(content)
#                print('已经合并：' + path)
    logging.info('Core is ok')
