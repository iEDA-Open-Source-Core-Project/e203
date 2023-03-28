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
e203Files = glob.glob(os.path.join(e203Path, '**', '*.v'))
tbFiles = glob.glob(os.path.join(tbPath, 'tb_top.v'), recursive=True)
E203con = os.path.join(e203Path, 'core', 'config.v')
E203def = os.path.join(e203Path, 'core', 'e203_defines.v')
# print(e203Files)
#print(tbFiles, E203con, E203def)

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
    log.write(e203def)
    for path in e203Files:
        filename = os.path.basename(path)
        if filename in ['config.v', 'e203_defines.v', 'i2c_master_defines.v']:
            continue
        ext = os.path.splitext(filename)[1]
        if ext == '.v':
            with open(path) as f:
                content = f.read()
                content = content.replace('`include "e203_defines.v"', "")
                log.write(content)
#                print('已经合并：' + path)
    logging.info('Core is ok')
