// SPDX-License-Identifier: GPL-2.0+
/*
 *  Copyright (C) 2008-2009 Samsung Electronics
 *  Minkyu Kang <mk7.kang@samsung.com>
 *  Kyungmin Park <kyungmin.park@samsung.com>
 */

#include <common.h>
#include <init.h>
#include <log.h>
#include <asm/gpio.h>
#include <asm/arch/mmc.h>
#include <dm.h>
#include <linux/delay.h>
#include <power/pmic.h>
#include <usb/dwc2_udc.h>
#include <asm/arch/cpu.h>
#include <power/max8998_pmic.h>
#include <samsung/misc.h>
#include <usb.h>
#include <usb_mass_storage.h>
#include <asm/mach-types.h>
#include <netdev.h>

DECLARE_GLOBAL_DATA_PTR;

u32 get_board_rev(void)
{
	return 0;
}

int board_init(void)
{
	/* Set Initial global variables */
	gd->bd->bi_arch_number = MACH_TYPE_GBLW210;
	gd->bd->bi_boot_params = PHYS_SDRAM_1 + 0x100;

	return 0;
}

#ifdef CONFIG_SYS_I2C_INIT_BOARD
void i2c_init_board(void)
{
	gpio_request(S5PC110_GPIO_J43, "i2c_clk");
	gpio_request(S5PC110_GPIO_J40, "i2c_data");
	gpio_direction_output(S5PC110_GPIO_J43, 1);
	gpio_direction_output(S5PC110_GPIO_J40, 1);
}
#endif

int dram_init(void)
{
	gd->ram_size = PHYS_SDRAM_1_SIZE;
	return 0;
}

int dram_init_banksize(void)
{
	gd->bd->bi_dram[0].start = PHYS_SDRAM_1;
	gd->bd->bi_dram[0].size = PHYS_SDRAM_1_SIZE;
	return 0;
}

#ifdef CONFIG_DISPLAY_BOARDINFO
int checkboard(void)
{
	puts("Board:\tGBLW210\n");
	return 0;
}
#endif

#ifdef CONFIG_MMC
int board_mmc_init(struct bd_info *bis)
{
	int i, ret;

	puts("board_mmc_init\r\n");

	/*
	 * MMC0 GPIO
	 * GPG0[0]	SD_0_CLK
	 * GPG0[1]	SD_0_CMD
	 * GPG0[2]	SD_0_CDn	-> Not used
	 * GPG0[3:6]	SD_0_DATA[0:3]
	 */
	for (i = S5PC110_GPIO_G00; i < S5PC110_GPIO_G07; i++) {
		if (i == S5PC110_GPIO_G02)
			continue;
		/* GPG0[0:6] special function 2 */
		gpio_cfg_pin(i, 0x2);
		/* GPG0[0:6] pull disable */
		gpio_set_pull(i, S5P_GPIO_PULL_NONE);
		/* GPG0[0:6] drv 4x */
		gpio_set_drv(i, S5P_GPIO_DRV_4X);
	}

	ret = s5p_mmc_init(0, 4);
	printf("s5p_mmc_init = %d\r\n", ret);
	if (ret)
		pr_err("MMC: Failed to init MMC:0.\n");
	return ret;
}
#endif

#ifdef CONFIG_DRIVER_DM9000
int board_eth_init(struct bd_info *bis)
{
	unsigned int tmp;

	// config dm9000 sromc
	// HCLK MSYS = 200MHz 5ns
	*((volatile unsigned int *)0xE8000004) =  // srom bc0
		  (0 << 28)   // Adress set-up before nGCS
											 // 发出片选信号之前,多长时间内要先发出地址信号
											 // DM9000C的片选信号和CMD信号可以同时发出, 所以它设为0
		  | (1 << 24) // Chip selection set-up before nOE
											 // 发出片选信号之后,多长时间才能发出读信号nOE
											 // >5ns
		  | (5 << 16) // Access cycle
											 // 读写信号的脉冲长度
											 // >22ns
		  | (1 << 12) // Chip selection hold on nOE
											 // 当读信号nOE变为高电平后,片选信号还要维持多长时间
											 // >5ns
		  | (0 << 8) // Address holding time after nGCSn
						// 当片选信号变为高电平后, 地址信号还要维持多长时间
		  | (0 << 4) // Page mode access cycle @ Page mode
		  | (0 << 0); // Page mode configuration

	tmp = *((volatile unsigned int *)0xE8000000); // read srom bw
	tmp &= ~0x0000000F; // 重置bank0设置
	tmp |=  0x00000003; // byte base address, 16bit
	*((volatile unsigned int *)0xE8000000) = tmp; // write srom bw

	return dm9000_initialize(bis);
}
#endif /* CONFIG_DRIVER_DM9000 */

#ifdef CONFIG_USB_GADGET
static int s5pc1xx_phy_control(int on)
{
	struct udevice *dev;
	static int status;
	int reg, ret;

	ret = pmic_get("max8998-pmic", &dev);
	if (ret)
		return ret;

	if (on && !status) {
		reg = pmic_reg_read(dev, MAX8998_REG_ONOFF1);
		reg |= MAX8998_LDO3;
		ret = pmic_reg_write(dev, MAX8998_REG_ONOFF1, reg);
		if (ret) {
			puts("MAX8998 LDO setting error!\n");
			return -EINVAL;
		}

		reg = pmic_reg_read(dev, MAX8998_REG_ONOFF2);
		reg |= MAX8998_LDO8;
		ret = pmic_reg_write(dev, MAX8998_REG_ONOFF2, reg);
		if (ret) {
			puts("MAX8998 LDO setting error!\n");
			return -EINVAL;
		}
		status = 1;
	} else if (!on && status) {
		reg = pmic_reg_read(dev, MAX8998_REG_ONOFF1);
		reg &= ~MAX8998_LDO3;
		ret = pmic_reg_write(dev, MAX8998_REG_ONOFF1, reg);
		if (ret) {
			puts("MAX8998 LDO setting error!\n");
			return -EINVAL;
		}

		reg = pmic_reg_read(dev, MAX8998_REG_ONOFF2);
		reg &= ~MAX8998_LDO8;
		ret = pmic_reg_write(dev, MAX8998_REG_ONOFF2, reg);
		if (ret) {
			puts("MAX8998 LDO setting error!\n");
			return -EINVAL;
		}
		status = 0;
	}
	udelay(10000);
	return 0;
}

struct dwc2_plat_otg_data s5pc110_otg_data = {
	.phy_control = s5pc1xx_phy_control,
	.regs_phy = S5PC110_PHY_BASE,
	.regs_otg = S5PC110_OTG_BASE,
	.usb_phy_ctrl = S5PC110_USB_PHY_CONTROL,
};

int board_usb_init(int index, enum usb_init_type init)
{
	debug("USB_udc_probe\n");
	return dwc2_udc_probe(&s5pc110_otg_data);
}
#endif

#ifdef CONFIG_MISC_INIT_R
int misc_init_r(void)
{
#ifdef CONFIG_ENV_VARS_UBOOT_RUNTIME_CONFIG
	set_board_info();
#endif
	return 0;
}
#endif

int board_usb_cleanup(int index, enum usb_init_type init)
{
	return 0;
}
