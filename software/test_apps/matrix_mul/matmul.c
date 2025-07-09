#include <stdio.h>
#include "func.h"

struct uart uart0; 
static struct timer timer0;
static struct timer timer1;
static struct icerror icerror0;

void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
	if ((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
	{
		uint8_t irq = mcause & 0x0f;

		switch (irq)
		{
		case PLATFORM_IRQ_TIMER0:
		{
			timer_clear(&timer0);
			break;
		}
		case PLATFORM_IRQ_TIMER1:
		{
			timer_clear(&timer1);
			break;
		}
		case PLATFORM_IRQ_BUS_ERROR:
		{
			uart_tx_string(&uart0, "Bus error!\n\r");

			enum icerror_access_type access = icerror_get_access_type(&icerror0);
			switch (access)
			{
			case ICERROR_ACCESS_READ:
			{
				uart_tx_string(&uart0, "\tType: read\n\r");

				uart_tx_string(&uart0, "\tAddress: ");
				char address_buffer[5];
				int2hex32(icerror_get_read_address(&icerror0), address_buffer);
				uart_tx_string(&uart0, address_buffer);
				uart_tx_string(&uart0, "\n\r");
				break;
			}
			case ICERROR_ACCESS_WRITE:
			{
				uart_tx_string(&uart0, "\tType: write\n\r");

				char address_buffer[5];
				int2hex32(icerror_get_write_address(&icerror0), address_buffer);
				uart_tx_string(&uart0, address_buffer);
				uart_tx_string(&uart0, "\n\r");
				break;
			}
			case ICERROR_ACCESS_NONE:
				// fallthrough
			default:
				break;
			}

			potato_disable_interrupts();
			while (1)
				potato_wfi();

			break;
		}
		default:
			potato_disable_irq(irq);
			break;
		}
	}
}




int main()
{
	// Configure the UART:
	uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
	uart_tx_string(&uart0, "\n\r ### TEST APPLICATION (MATRIX MULTIPLICATION) ###\n\n\r");

	fill_matrices();
    multiply_matrices();

	return 0;
}