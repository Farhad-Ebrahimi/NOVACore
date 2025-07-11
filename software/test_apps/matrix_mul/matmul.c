#include <stdio.h>
#include "func.h"

struct uart uart0;
struct timer timer0;

static volatile unsigned int mul_add_op = 0;
static volatile bool reset_counter = true;

void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
	if ((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
	{
		uint8_t irq = mcause & 0x0f;

		if (irq == PLATFORM_IRQ_TIMER0)
		{
			char int2str[16];
			int2string(mul_add_op, int2str);
			uart_tx_string(&uart0, int2str);
			uart_tx_string(&uart0, " mul_add_operations/s\n\r");
			reset_counter = true;
			timer_clear(&timer0);
		}
	}
}

int main()
{
	// Configure the UART:
	uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
	uart_tx_string(&uart0, "\n\r ### TEST APPLICATION (MATRIX MULTIPLICATION) ###\n\n\r");

	// Set up timer0 at 1 Hz:
	timer_initialize(&timer0, (volatile void *)PLATFORM_TIMER0_BASE);
	timer_reset(&timer0);
	timer_set_compare(&timer0, PLATFORM_SYSCLK_FREQ);
	timer_start(&timer0);

	potato_enable_irq(PLATFORM_IRQ_TIMER0);
	potato_enable_interrupts();

	uart_tx_string(&uart0, "Beginning...\n\n\r");
	fill_matrices();
	while (true)
	{
		if (reset_counter)
		{
			mul_add_op = 0;
			reset_counter = false;
		}
		else
			mul_add_op += multiply_matrices();
	}

	return 0;
}