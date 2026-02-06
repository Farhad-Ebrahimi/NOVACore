// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdint.h>
#include <limits.h>

#include "platform.h"
#include "uart.h"

#define APP_START (0x00000000)
#define APP_LEN   (0x20000)
#define APP_ENTRY (0x00000000)

static struct uart uart0;

void exception_handler(uint32_t cause, void * epc, void * regbase)
{
	while(uart_tx_fifo_full(&uart0));
	uart_tx(&uart0, 'E');
}

int main(void)
{
	__asm__ (
		"li	t0, 200\n\t"
		"li	t1, 30\n\t"
		"div	t3, t0, t1\n\t"
		"addi	t4, t3, 1\n\t"
		"li	t0, 100\n\t"
		"li	t1, 10\n\t"
		"div	t3, t0, t1\n\t"
		"addi	t4, t3, 1\n\t"
	);

	return 0;
}
