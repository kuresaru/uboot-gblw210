uboot-gblw210
给隔壁老王210移植的uboot

编译下载方法(注意修改make.sh中的进程数和写入sd的设备路径):
$ make gblw210_config
$ ./make.sh
$ ./flash_sd.sh /dev/sdb

最后插入sd卡,短接启动模式跳线,启动


参考:
https://www.bilibili.com/video/BV1s4411t7eT
https://blog.csdn.net/a1598025967/article/details/107199524
