uboot-gblw210
给隔壁老王210移植的uboot


TODO: 
LED初始化
NAND驱动
ddr时序不是最佳
为什么board/samsung/gblw210/lowlevel_init.S中的ddr读写测试代码删除后无法启动


编译下载方法(注意修改make.sh中的进程数和写入sd的设备路径):
$ make gblw210_config
$ ./make.sh
$ ./flash_sd.sh /dev/sdb

最后插入sd卡,短接启动模式跳线,启动


SD卡数据分布:
address     content     size(byte)  size(human-readable)
0-1ff       mbr         512         512
200-41ff    210.bin     16384	    16K
4200-61ff   env         8192        8K        
6200-3fffff u-boot.bin  4169216     3.97M       
400000+     sd-data


mach type: 21986


参考:
https://www.bilibili.com/video/BV1s4411t7eT
https://blog.csdn.net/a1598025967/article/details/107199524
