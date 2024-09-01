#include <stdlib.h>
#include <stdbool.h>

#include <stdio.h>
#include <math.h>

#include "platform.h"
#include "potato.h"

#include "gpio.h"
#include "icerror.h"
#include "timer.h"
#include "uart.h"

#include "func.h"

char ops_dec[11];
volatile int count = 0;
volatile bool done = false;
volatile bool prt = false;

static struct uart uart0;
static struct timer timer0;
static struct timer timer1;
static struct icerror icerror0;

static void int2string(int i, char *s);
static void int2hex32(uint32_t i, char *s);

void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
	if ((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
	{
		uint8_t irq = mcause & 0x0f;

		switch (irq)
		{
		case PLATFORM_IRQ_TIMER0:
		{
			if (done == true && prt == false)
			{
				prt = true;
				count *= 250;
				int2string(count, ops_dec);
				uart_tx_string(&uart0, "exe_time: ");
				uart_tx_string(&uart0, ops_dec);
				uart_tx_string(&uart0, " (ms) \n\r");
				potato_disable_irq(PLATFORM_IRQ_TIMER1);
			}
			timer_clear(&timer0);
			break;
		}
		case PLATFORM_IRQ_TIMER1:
		{
			if (done == false)
				count++;

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
	uart_tx_string(&uart0, "\n\r*** loop unrolling test application developed for NOVACore ***\r\n\n");

	// Set up timer0 at 1 Hz:
	timer_initialize(&timer0, (volatile void *)PLATFORM_TIMER0_BASE);
	timer_reset(&timer0);
	timer_set_compare(&timer0, PLATFORM_SYSCLK_FREQ);
	timer_start(&timer0);

	// Set up timer1 at 4 Hz:
	timer_initialize(&timer1, (volatile void *)PLATFORM_TIMER1_BASE);
	timer_reset(&timer1);
	timer_set_compare(&timer1, PLATFORM_SYSCLK_FREQ >> 2);
	timer_start(&timer1);

	// Enable interrupts:
	potato_enable_irq(PLATFORM_IRQ_TIMER0);
	potato_enable_irq(PLATFORM_IRQ_TIMER1);

	uint8_t a[size];
	uint8_t b[size];
	uint8_t c[size];
	uint8_t d[size];
	int cnt = 0;

	potato_enable_interrupts();
	uart_tx_string(&uart0, "Beginning...\n\n\r");

	init_arr(a, b, c, d, size);
	do{
		func(a, b, c, d, size);
		cnt++;
	}while(cnt<size);
	
	cnt*=size;
	int2string(cnt, ops_dec);
	uart_tx_string(&uart0, ops_dec);
	uart_tx_string(&uart0, " loop iteration execution has been completed!");
	uart_tx_string(&uart0, "\n\n\r");
	done = true;

	return 0;
}

static void int2string(int n, char *s)
{
	bool first = true;

	if (n == 0)
	{
		s[0] = '0';
		s[1] = 0;
		return;
	}

	if (n & (1u << 31))
	{
		n = ~n + 1;
		*(s++) = '-';
	}

	for (int i = 1000000000; i > 0; i /= 10)
	{
		if (n / i == 0 && !first)
			*(s++) = '0';
		else if (n / i != 0)
		{
			*(s++) = '0' + n / i;
			n %= i;
			first = false;
		}
	}
	*s = 0;
}

static void int2hex32(uint32_t n, char *s)
{
	static const char *hex_digits = "0123456789abcdef";

	int index = 0;
	for (int i = 28; i >= 0; i -= 4)
		s[index++] = hex_digits[(n >> (32 - i)) & 0xf];
	s[index] = 0;
}
