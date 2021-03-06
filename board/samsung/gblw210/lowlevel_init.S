/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Memory Setup stuff - taken from blob memsetup.S
 *
 * Copyright (C) 2009 Samsung Electronics
 * Kyungmin Park <kyungmin.park@samsung.com>
 */

#include <config.h>
#include <asm/arch/cpu.h>
#include <asm/arch/clock.h>
#include <asm/arch/power.h>

/*
 * Register usages:
 *
 * r5 has zero always
 * r7 has S5PC100 GPIO base, 0xE0300000
 * r8 has real GPIO base, 0xE0300000, 0xE0200000 at S5PC100, S5PC110 repectively
 * r9 has Mobile DDR size, 1 means 1GiB, 2 means 2GiB and so on
 */

	.globl lowlevel_init
lowlevel_init:
	mov	r11, lr

	/* r5 has always zero */
	mov	r5, #0

	ldr	r7, =S5PC100_GPIO_BASE
	ldr	r8, =S5PC100_GPIO_BASE
	/* Read CPU ID */
	ldr	r2, =S5PC110_PRO_ID
	ldr	r0, [r2]
	mov	r1, #0x00010000
	and	r0, r0, r1
	cmp	r0, r5
	beq	100f
	ldr	r8, =S5PC110_GPIO_BASE
100:
	/* Turn on KEY_LED_ON [GPJ4(1)] XMSMWEN */
	cmp	r7, r8
	beq	skip_check_didle			@ Support C110 only

	ldr	r0, =S5PC110_RST_STAT
	ldr	r1, [r0]
	and	r1, r1, #0x000D0000
	cmp	r1, #(0x1 << 19)			@ DEEPIDLE_WAKEUP
	beq	didle_wakeup
	cmp	r7, r8

skip_check_didle:
	addeq	r0, r8, #0x280				@ S5PC100_GPIO_J4
	addne	r0, r8, #0x2C0				@ S5PC110_GPIO_J4
	ldr	r1, [r0, #0x0]				@ GPIO_CON_OFFSET
	bic	r1, r1, #(0xf << 4)			@ 1 * 4-bit
	orr	r1, r1, #(0x1 << 4)
	str	r1, [r0, #0x0]				@ GPIO_CON_OFFSET

	ldr	r1, [r0, #0x4]				@ GPIO_DAT_OFFSET
	bic	r1, r1, #(1 << 1)
	str	r1, [r0, #0x4]				@ GPIO_DAT_OFFSET

	/* Don't setup at s5pc100 */
	beq	100f

	/*
	 * Initialize Async Register Setting for EVT1
	 * Because we are setting EVT1 as the default value of EVT0,
	 * setting EVT0 as well does not make things worse.
	 * Thus, for the simplicity, we set for EVT0, too
	 *
	 * The "Async Registers" are:
	 *	0xE0F0_0000
	 *	0xE1F0_0000
	 *	0xF180_0000
	 *	0xF190_0000
	 *	0xF1A0_0000
	 *	0xF1B0_0000
	 *	0xF1C0_0000
	 *	0xF1D0_0000
	 *	0xF1E0_0000
	 *	0xF1F0_0000
	 *	0xFAF0_0000
	 */
	ldr     r0, =0xe0f00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xe1f00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1800000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1900000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1a00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1b00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1c00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1d00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1e00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xf1f00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	ldr     r0, =0xfaf00000
	ldr     r1, [r0]
	bic     r1, r1, #0x1
	str     r1, [r0]

	/*
	 * Diable ABB block to reduce sleep current at low temperature
	 * Note that it's hidden register setup don't modify it
	 */
	ldr	r0, =0xE010C300
	ldr	r1, =0x00800000
	str	r1, [r0]

100:
	/* IO retension release */
	ldreq	r0, =S5PC100_OTHERS			@ 0xE0108200
	ldrne	r0, =S5PC110_OTHERS			@ 0xE010E000
	ldr	r1, [r0]
	ldreq	r2, =(1 << 31)				@ IO_RET_REL
	ldrne	r2, =((1 << 31) | (1 << 30) | (1 << 29) | (1 << 28))
	orr	r1, r1, r2
	/* Do not release retention here for S5PC110 */
	streq	r1, [r0]

	/* Disable Watchdog */
	ldreq	r0, =S5PC100_WATCHDOG_BASE		@ 0xEA200000
	ldrne	r0, =S5PC110_WATCHDOG_BASE		@ 0xE2700000
	str	r5, [r0]

	/* setting SRAM */
	ldreq	r0, =S5PC100_SROMC_BASE
	ldrne	r0, =S5PC110_SROMC_BASE
	ldr	r1, =0x9
	str	r1, [r0]

	/* S5PC100 has 3 groups of interrupt sources */
	ldreq	r0, =S5PC100_VIC0_BASE			@ 0xE4000000
	ldrne	r0, =S5PC110_VIC0_BASE			@ 0xF2000000
	add	r1, r0, #0x00100000
	add	r2, r0, #0x00200000

	/* Disable all interrupts (VIC0, VIC1 and VIC2) */
	mvn	r3, #0x0
	str	r3, [r0, #0x14]				@ INTENCLEAR
	str	r3, [r1, #0x14]				@ INTENCLEAR
	str	r3, [r2, #0x14]				@ INTENCLEAR

	/* Set all interrupts as IRQ */
	str	r5, [r0, #0xc]				@ INTSELECT
	str	r5, [r1, #0xc]				@ INTSELECT
	str	r5, [r2, #0xc]				@ INTSELECT

	/* Pending Interrupt Clear */
	str	r5, [r0, #0xf00]			@ INTADDRESS
	str	r5, [r1, #0xf00]			@ INTADDRESS
	str	r5, [r2, #0xf00]			@ INTADDRESS

	bl system_clock_init

	/* for UART */
	bl	uart_asm_init

	bl  ddr_init

	// 测试在DDR的256M+4B进行读写
	// TODO 为什么删除了不能启动
	ldr r0, =0x30000004
	ldr r1, =0x12345678
	str r1, [r0]
	ldr r0, [r0]
	bl test_print

	bl	internal_ram_init

	// 加载完整的u-boot程序到ddr中
	bl  copy_code_to_dram

	cmp	r7, r8
	/* Clear wakeup status register */
	ldreq	r0, =S5PC100_WAKEUP_STAT
	ldrne	r0, =S5PC110_WAKEUP_STAT
	ldr	r1, [r0]
	str	r1, [r0]

	/* IO retension release */
	ldreq	r0, =S5PC100_OTHERS			@ 0xE0108200
	ldrne	r0, =S5PC110_OTHERS			@ 0xE010E000
	ldr	r1, [r0]
	ldreq	r2, =(1 << 31)				@ IO_RET_REL
	ldrne	r2, =((1 << 31) | (1 << 30) | (1 << 29) | (1 << 28))
	orr	r1, r1, r2
	str	r1, [r0]

	b	1f

didle_wakeup:
	/* Wait when APLL is locked */
	ldr	r0, =0xE0100100			@ S5PC110_APLL_CON
lockloop:
	ldr	r1, [r0]
	and	r1, r1, #(1 << 29)
	cmp	r1, #(1 << 29)
	bne	lockloop

	ldr	r0, =S5PC110_INFORM0
	ldr	r1, [r0]
	mov	pc, r1
	nop
	nop
	nop
	nop
	nop

1:
	mov	lr, r11
	mov	pc, lr

/*
 * system_clock_init: Initialize core clock and bus clock.
 * void system_clock_init(void)
 */
system_clock_init:

	// clock base
	ldr r0, =0xe0100000

	// 3 设置分频
	ldr r1, =0x14131440
	str r1, [r0, #0x300]

	// 4 设置PLL
	// APLL=1GHz
	ldr r1, =0x807d0301
	str r1, [r0, #0x100]
	// MPLL=667MHz
	ldr r1, =0x829b0c01
	str r1, [r0, #0x108]
	// EPLL=96MHz
	ldr r1, =0x80300302
	str r1, [r0, #0x110]
	ldr r1, =0
	str r1, [r0, #0x114]
	// VPLL=54MHz
	ldr r1, =0x806c0603
	str r1, [r0, #0x120]

	/* wait at least 200us to stablize all clock */
	mov	r2, #0x10000
1:	subs	r2, r2, #1
	bne	1b

	mov	pc, lr

internal_ram_init:
	ldreq	r0, =0xE3800000
	ldrne	r0, =0xF1500000
	ldr	r1, =0x0
	str	r1, [r0]

	mov	pc, lr

/*
 * uart_asm_init: Initialize UART's pins
 */
uart_asm_init:
	/* set GPIO to enable UART0-UART4 */
	mov	r0, r8
	ldr	r1, =0x22222222
	str	r1, [r0, #0x0]			@ S5PC100_GPIO_A0_OFFSET
	ldr	r1, =0x00002222
	str	r1, [r0, #0x20]			@ S5PC100_GPIO_A1_OFFSET

	/* Check S5PC100 */
	cmp	r7, r8
	bne	110f

	/* UART_SEL GPK0[5] at S5PC100 */
	add	r0, r8, #0x2A0			@ S5PC100_GPIO_K0_OFFSET
	ldr	r1, [r0, #0x0]			@ S5PC1XX_GPIO_CON_OFFSET
	bic	r1, r1, #(0xf << 20)		@ 20 = 5 * 4-bit
	orr	r1, r1, #(0x1 << 20)		@ Output
	str	r1, [r0, #0x0]			@ S5PC1XX_GPIO_CON_OFFSET

	ldr	r1, [r0, #0x8]			@ S5PC1XX_GPIO_PULL_OFFSET
	bic	r1, r1, #(0x3 << 10)		@ 10 = 5 * 2-bit
	orr	r1, r1, #(0x2 << 10)		@ Pull-up enabled
	str	r1, [r0, #0x8]			@ S5PC1XX_GPIO_PULL_OFFSET

	ldr	r1, [r0, #0x4]			@ S5PC1XX_GPIO_DAT_OFFSET
	orr	r1, r1, #(1 << 5)		@ 5 = 5 * 1-bit
	str	r1, [r0, #0x4]			@ S5PC1XX_GPIO_DAT_OFFSET

	b	200f
110:
	/*
	 * Note that the following address
	 * 0xE020'0360 is reserved address at S5PC100
	 */
	/* UART_SEL MP0_5[7] at S5PC110 */
	add	r0, r8, #0x360			@ S5PC110_GPIO_MP0_5_OFFSET
	ldr	r1, [r0, #0x0]			@ S5PC1XX_GPIO_CON_OFFSET
	bic	r1, r1, #(0xf << 28)		@ 28 = 7 * 4-bit
	orr	r1, r1, #(0x1 << 28)		@ Output
	str	r1, [r0, #0x0]			@ S5PC1XX_GPIO_CON_OFFSET

	ldr	r1, [r0, #0x8]			@ S5PC1XX_GPIO_PULL_OFFSET
	bic	r1, r1, #(0x3 << 14)		@ 14 = 7 * 2-bit
	orr	r1, r1, #(0x2 << 14)		@ Pull-up enabled
	str	r1, [r0, #0x8]			@ S5PC1XX_GPIO_PULL_OFFSET

	ldr	r1, [r0, #0x4]			@ S5PC1XX_GPIO_DAT_OFFSET
	orr	r1, r1, #(1 << 7)		@ 7 = 7 * 1-bit
	str	r1, [r0, #0x4]			@ S5PC1XX_GPIO_DAT_OFFSET

	// 新初始化
	ldr r0, =0xE2900000
	ldr r1, =3
	str r1, [r0]	@ULCON0=3

	ldr r1, =0x305
	str r1, [r0, #0x4] @UCON0=0x305

	ldr r1, =1
	str r1, [r0, #0x8] @UFCON0=0

	ldr r1, =0
	str r1, [r0, #0xC] @UMCON0=0

	ldr r1, =34
	str r1, [r0, #0x28] @UBRDIV0=34

	ldr r1, =0xDFDD
	str r1, [r0, #0x2C] @UDIVSLOT0=13'1

200:
	mov	pc, lr


.global test_print
test_print:
    ldr r1, =0xE2900020 @uart0

    ldr r2, =0x30
    str r2, [r1]        @0

    ldr r2, =0x78
    str r2, [r1]        @x

    ldr r3, =28

test_print_mem_loop:
    // 取4bit
    lsr r2, r0, r3       @ r0右移r3位结果保存到r2
    and r2, r2, #0xF     @ r2 = r2 & 0xF

    // 数字变ascii
    cmp r2, #10
    addmi r2, r2, #0x30  @ if <0, +0x30 (0-9)
    addpl r2, r2, #0x37  @ if >=0, +0x37 (a-f)

    // 输出一个字符
    str r2, [r1]

    // 循环下四位
    sub r3, r3, #4
    cmp r3, #0
    bpl test_print_mem_loop

    // 结束输出换行
    ldr r2, =0x0D
    str r2, [r1]        @\r

    ldr r2, =0x0A
    str r2, [r1]        @\n

    // 程序返回
    mov pc, lr

.global ddr_init
ddr_init:

#define ELFIN_GPIO_BASE			0xE0200000

#define MP1_0DRV_SR_OFFSET 		0x3CC
#define MP1_1DRV_SR_OFFSET 		0x3EC
#define MP1_2DRV_SR_OFFSET 		0x40C
#define MP1_3DRV_SR_OFFSET 		0x42C
#define MP1_4DRV_SR_OFFSET 		0x44C
#define MP1_5DRV_SR_OFFSET 		0x46C
#define MP1_6DRV_SR_OFFSET 		0x48C
#define MP1_7DRV_SR_OFFSET 		0x4AC
#define MP1_8DRV_SR_OFFSET 		0x4CC

#define APB_DMC_0_BASE			0xF0000000

#define DMC_CONCONTROL 			0x00
#define DMC_MEMCONTROL 			0x04
#define DMC_MEMCONFIG0 			0x08
#define DMC_MEMCONFIG1 			0x0C
#define DMC_DIRECTCMD 			0x10
#define DMC_PRECHCONFIG 		0x14
#define DMC_PHYCONTROL0 		0x18
#define DMC_PHYCONTROL1 		0x1C
#define DMC_RESERVED 			0x20
#define DMC_PWRDNCONFIG 		0x28
#define DMC_TIMINGAREF 			0x30
#define DMC_TIMINGROW 			0x34
#define DMC_TIMINGDATA 			0x38
#define DMC_TIMINGPOWER 		0x3C
#define DMC_PHYSTATUS 			0x40

	// 1. 设置DMC0 Drive Strength (Setting 2X)
	ldr	r0, =ELFIN_GPIO_BASE
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_0DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_1DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_2DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_3DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_4DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_5DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_6DRV_SR_OFFSET]
	ldr	r1, =0x0000AAAA
	str	r1, [r0, #MP1_7DRV_SR_OFFSET]
	ldr	r1, =0x00002AAA
	str	r1, [r0, #MP1_8DRV_SR_OFFSET]

	// 2. 初始化PHY DLL
	ldr r0, =APB_DMC_0_BASE
	// step2 set phycontrol0.control_start_point, .ctrl_inc, .ctrl_dll_on
	ldr r1, =0x0010100A
	str r1, [r0, #DMC_PHYCONTROL0]

	// step3 set phycontrol1.ctrl_shiftc, .ctrl_offsetc
	ldr r1, =0x00000086
	str r1, [r0, #DMC_PHYCONTROL1]

	// step4 phycontrol0 dll start
	ldr r1, =0x0010100B
	str r1, [r0, #DMC_PHYCONTROL0]

find_lock_val:
	// step11 loop until dll is locked
	ldr	r1, [r0, #DMC_PHYSTATUS]			
	and	r2, r1, #0x7
	cmp	r2, #0x7					
	bne	find_lock_val

	// step12 force value locking
	and	r1, #0x3fc0
	mov	r2, r1, LSL #18
	orr	r2, r2, #0x100000
	orr	r2 ,r2, #0x1000
	orr	r1, r2, #0xB					
	str	r1, [r0, #DMC_PHYCONTROL0]

	// 3. 初始化DMC0
	// step5 concontrol auto refresh off
	ldr r1, =0x0FFF1010
	str r1, [r0, #DMC_CONCONTROL]

	// step6 memctrl bl=4, 1chip, ddr2 type, dynamic power down off
	ldr r1, =0x00202400
	str r1, [r0, #DMC_MEMCONTROL]

	// step7 memconfig0 512MB config, 8banks, mapping method[12:15]0:linear
	ldr r1, =0x20E00323
	str r1, [r0, #DMC_MEMCONFIG0]

	// step8 prechconfig
	ldr r1, =0xFF000000
	str r1, [r0, #DMC_PRECHCONFIG]
	ldr r1, =0xFFFF00FF
	str r1, [r0, #DMC_PWRDNCONFIG]

	// step9 timingaref 
	@ ldr r1, =0x0000040E
	ldr r1, =0x00000618
	str r1, [r0, #DMC_TIMINGAREF]

	@ ldr r1, =0x11122206
	ldr r1, =0x2B34438A
	str r1, [r0, #DMC_TIMINGROW]

	@ ldr r1, =0x12240000
	ldr r1, =0x24240000
	str r1, [r0, #DMC_TIMINGDATA]

	@ ldr r1, =0x05DC0343
	ldr r1, =0x0BDC0343
	str r1, [r0, #DMC_TIMINGPOWER]

	// 4. 初始化DDR2 DRAM
	// step14 directcmd chip0 nop
	ldr r1, =0x07000000
	str r1, [r0, #DMC_DIRECTCMD]

	// step16 directcmd chip0 pall
	ldr r1, =0x01000000
	str r1, [r0, #DMC_DIRECTCMD]

	// step17 directcmd chip0 emrs2
	ldr r1, =0x00020000
	str r1, [r0, #DMC_DIRECTCMD]

	// step18 directcmd chip0 emrs3
	ldr r1, =0x00030000
	str r1, [r0, #DMC_DIRECTCMD]

	// step19 directcmd chip0 emrs1
	ldr r1, =0x00010000
	str r1, [r0, #DMC_DIRECTCMD]

	// step20 directcmd chip0 mrs
	ldr r1, =0x00000542
	str r1, [r0, #DMC_DIRECTCMD]

	// step21 directcmd chip0 pall
	ldr r1, =0x01000000
	str r1, [r0, #DMC_DIRECTCMD]

	// step22 directcmd chip0 refa
	ldr r1, =0x05000000
	str r1, [r0, #DMC_DIRECTCMD]
	ldr r1, =0x05000000
	str r1, [r0, #DMC_DIRECTCMD]

	// step23 directcmd chip0 mrs
	ldr r1, =0x00000442
	str r1, [r0, #DMC_DIRECTCMD]

	// step25(1) directcmd chip0 emrs1
	ldr r1, =0x00010300
	str r1, [r0, #DMC_DIRECTCMD]

	// step25(2) directcmd chip0 emrs1
	ldr r1, =0x00010000
	str r1, [r0, #DMC_DIRECTCMD]

	// step27 concontrol auto refresh on
	ldr r1, =0x0FF01030
	str r1, [r0, #DMC_CONCONTROL]

	// step28 memcontrol bl=4 1chip, ddr2 type, dynamic self refresh, force precharge, dynamic power down off
	ldr r1, =0x00202400
	str r1, [r0, #DMC_MEMCONTROL]

	mov pc, lr
