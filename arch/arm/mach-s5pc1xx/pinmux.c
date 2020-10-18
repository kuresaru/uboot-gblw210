#include <common.h>
#include <asm/arch/pinmux.h>

int exynos_pinmux_config(int peripheral, int flags)
{
	return 0;
}

int pinmux_decode_periph_id(const void *blob, int node)
{
	return fdtdec_get_int(blob, node, "id", 0);
}
