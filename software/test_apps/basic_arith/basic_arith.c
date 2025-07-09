#include <stdlib.h>
#include <stdbool.h>

#include <stdio.h>
#include <math.h>

#include "../platform.h"
#include "../potato.h"

#include "../libsoc/gpio.h"
#include "../libsoc/icerror.h"
#include "../libsoc/timer.h"
#include "../libsoc/uart.h"

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

char uart_rx_char()
{
    while (uart_rx_fifo_empty(&uart0));
    return uart_rx(&uart0);
}

static int read_int()
{
    int value = 0;
    char c;
    int digits_read = 0;

    while (1)
    {
        c = uart_rx_char();
        uart_tx(&uart0, c);

        if (c >= '0' && c <= '9') {
            value = value * 10 + (c - '0');
            digits_read++;
        } else  if (c == '\r' || c == '\n') {
            break;
        }
    }

    return value;
}

int main()
{
	// Configure the UART:
	uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
	uart_tx_string(&uart0, "\n\r ### TEST APPLICATION (BASIC ARITH: +, -, *, /) ###\n\n\r");

	uart_tx_string(&uart0, "\n\rENTER FIRST OPERAND: ");
	int a = read_int();

	uart_tx_string(&uart0, "\n\rENTER DESIRED OPERATOR (+, -, *, /): ");
	char op = uart_rx_char(&uart0);
	uart_tx(&uart0, op);

	uart_tx_string(&uart0, "\n\rENTER SECOND OPERAND: ");
	int b = read_int();

	uart_tx_string(&uart0, "\n\rRESULT: ");

	char result[16];

	switch (op)
	{
	case '+':
		int2string(a + b, result);
		break;
	case '-':
		int2string(a - b, result);
		break;
	case '*':
		int2string(a * b, result);
		break;
	case '/':
		int2string(a / b, result);
		break;
	default:
		uart_tx(&uart0, op);
		uart_tx_string(&uart0, ": Invalid operator!");
		return 1;
	}

	uart_tx_string(&uart0, result);
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
