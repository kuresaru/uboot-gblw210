typedef unsigned int (*copy_sd_mmc_to_mem) (unsigned int channel, unsigned int start_block, unsigned char block_size, unsigned int *trg, unsigned int init);

void copy_code_to_dram(void)
{
    unsigned long ch;
    unsigned long dest;
    unsigned int sec_no;
    unsigned int i;
    copy_sd_mmc_to_mem copy_bl2;

    dest = 0x34800000;
    sec_no = 49;
    ch = *(volatile unsigned int *)(0xD0037488);
    copy_bl2 = (copy_sd_mmc_to_mem)(*(unsigned int *)(0xD0037F98)); // 这个函数是写在IROM里的 直接用就行
    if (ch == 0xEB000000)
    {
        // 复制640K
        for (i = 0; i < 10; i++)
        {
            // 复制64K
            copy_bl2(0, i * 128 + sec_no, 128, (unsigned int *)(i * 0x10000 + dest), 0);
        }
    }
}