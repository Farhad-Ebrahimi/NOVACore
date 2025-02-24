#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "platform.h"
#include "potato.h"

#include "gpio.h"
#include "icerror.h"
#include "timer.h"
#include "uart.h"

static struct gpio gpio0;
static struct uart uart0;
static struct timer timer0;
static struct timer timer1;
static struct icerror icerror0;

static uint8_t led_status = 0x01;
static unsigned int iteration = 33;
static volatile unsigned int count = 0;
static volatile bool reset_counter = true;

// Converts an integer to a string:
__attribute__((optimize("O1"))) static void int2string(int i, char *s);
// Converts an unsigned 32 bit integer to a hexadecimal string:
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
			timer_clear(&timer0);
			break;
		}
		case PLATFORM_IRQ_TIMER1:
		{
			count += 1;

			led_status >>= 1;
			if ((led_status & 0xf) == 0)
				led_status = 0x8;

			// Read the switches to determine which LEDs should be used:
			uint32_t switch_mask = (gpio_get_input(&gpio0) >> 4) & 0xf;

			// Read the buttons and turn on the corresponding LED regardless of the switch settings:
			uint32_t button_mask = gpio_get_input(&gpio0) & 0xf;

			// Set the LEDs:
			gpio_set_output(&gpio0, ((led_status & switch_mask) | button_mask) << 8);

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

static int fib(int i)
{
	return (i > 1) ? fib(i - 1) + fib(i - 2) : i;
}

int main(void)
{

	// Configure GPIOs:
	gpio_initialize(&gpio0, (volatile void *)PLATFORM_GPIO_BASE);
	gpio_set_direction(&gpio0, 0xf00); // Set LEDs to output, buttons and switches to input
	gpio_set_output(&gpio0, 0x100);	   // Turn LED0 on.

	// Configure the UART:
	uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
	uart_tx_string(&uart0, "--- Fibonacci-Sequence Benchmark Application ---\r\n\n");

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

	// Set up the interconnect error module for detecting invalid bus accesses:
	// icerror_initialize(&icerror0, (volatile void *) PLATFORM_ICERROR_BASE);
	// icerror_reset(&icerror0);

	// Enable interrupts:
	potato_enable_irq(PLATFORM_IRQ_TIMER0);
	potato_enable_irq(PLATFORM_IRQ_TIMER1);
	// potato_enable_irq(PLATFORM_IRQ_BUS_ERROR);
	potato_enable_interrupts();

	uart_tx_string(&uart0, "begun. wait for the result..!\n\n\r");
	for (int i = 20; i < iteration; i++)
	{
		int value = fib(i);

		char itr[16], time[16], result[16];

		uart_tx_string(&uart0, "computaion time for ");
		int2string(i, itr);
		uart_tx_string(&uart0, itr);
		uart_tx_string(&uart0, " sequence is: ");
		int2string((count * 250), time);
		uart_tx_string(&uart0, time);
		uart_tx_string(&uart0, " ms\n\r");

		int2string(value, result);
		uart_tx_string(&uart0, "result: ");
		uart_tx_string(&uart0, result);
		uart_tx_string(&uart0, "\n\n\r");

	}
	potato_disable_irq(PLATFORM_IRQ_TIMER1);

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
