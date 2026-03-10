// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "platform.h"
#include "potato.h"

#include "gpio.h"
#include "icerror.h"
#include "timer.h"
#include "uart.h"

#include "sha256.h"

static struct uart uart0;
static struct timer timer0;

static volatile unsigned int hashes_per_second = 0;
static volatile bool reset_counter = true;

// Converts an integer to a string:
static void int2string(int i, char *s);
// Converts an unsigned 32 bit integer to a hexadecimal string:
static void int2hex32(uint32_t i, char *s);

void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
	if ((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
	{
		uint8_t irq = mcause & 0x0f;

		if (irq == PLATFORM_IRQ_TIMER0)
		{
			char hps_dec[11];
			int2string(hashes_per_second, hps_dec);
			uart_tx_string(&uart0, "->  ");
			uart_tx_string(&uart0, hps_dec);
			uart_tx_string(&uart0, " Hashes/second\n\r");
			reset_counter = true;
			timer_clear(&timer0);
		}
	}
}

int main(void)
{
	// Configure the UART:
	uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
	uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
	uart_tx_string(&uart0, "+------------------------------------------------------------+\r\n");
	uart_tx_string(&uart0, "|                                                            |\r\n");
	uart_tx_string(&uart0, "|                    'SHA256' Benchmark                      |\r\n");
	uart_tx_string(&uart0, "|                  Version: C, Version 1.0                   |\r\n");
	uart_tx_string(&uart0, "|                  -----------------------                   |\r\n");
	uart_tx_string(&uart0, "|                                                            |\r\n");
	uart_tx_string(&uart0, "|      NOVACore: 7-Stage CSD RISC-V Core(RV32IMF_Zicsr)      |\r\n");
	uart_tx_string(&uart0, "|            (c) Farhad Ebrahimiazandaryani 03/23            |\r\n");
	uart_tx_string(&uart0, "|              Chair of Computer Science 3 | CS3             |\r\n");
	uart_tx_string(&uart0, "|                   FAU Erlangen-Nurnberg                    |\r\n");
	uart_tx_string(&uart0, "|                                                            |\r\n");
	uart_tx_string(&uart0, "|                   ---------------------                    |\r\n");
    uart_tx_string(&uart0, "|                           GitHub:                          |\r\n");
	uart_tx_string(&uart0, "|         https://github.com/Farhad-Ebrahimi/NOVACore        |\r\n");
	uart_tx_string(&uart0, "|                                                            |\r\n");
	uart_tx_string(&uart0, "+------------------------------------------------------------+\r\n\r\n");


	// Set up timer0 at 1 Hz:
	timer_initialize(&timer0, (volatile void *)PLATFORM_TIMER0_BASE);
	timer_reset(&timer0);
	timer_set_compare(&timer0, PLATFORM_SYSCLK_FREQ);
	timer_start(&timer0);

	// Enable interrupts:
	potato_enable_irq(PLATFORM_IRQ_TIMER0);
	potato_enable_interrupts();

	struct sha256_context context;

	// Prepare a block for hashing:
	uint32_t block[16];
	uint8_t *block_ptr = (uint8_t *)block;
	block_ptr[0] = 'a';
	block_ptr[1] = 'b';
	block_ptr[2] = 'c';
	sha256_pad_le_block(block_ptr, 3, 3);

	uart_tx_string(&uart0, "Beginning...\n\n\r");
	while (true)
	{
		uint8_t hash[32];

		sha256_reset(&context);
		sha256_hash_block(&context, block);
		sha256_get_hash(&context, hash);
		potato_disable_interrupts();
		if (reset_counter)
		{
			hashes_per_second = 1;
			reset_counter = false;
		}
		else
			++hashes_per_second;
		potato_enable_interrupts();
	}
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
