// The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
// (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
// Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
// Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

// The Potato Processor Benchmark Applications
// (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdint.h>
#include <string.h>

#include "platform.h"
#include "uart.h"

#define APP_LEN   (0x02000) 
#define APP_ADDR  (0x00000000) 
#define FSBL_ADDR  (0xffff8000) 

static struct uart uart0;
typedef void (*boot_func_t)(void); 
#define APP_start  ((boot_func_t)APP_ADDR)
#define FSBL_start ((boot_func_t)FSBL_ADDR)
#define APP_MEM  ((volatile uint8_t *)APP_ADDR)

void int2string(int i, char *s);


void exception_handler(uint32_t cause, void *epc, void *regbase)
{
    while (uart_tx_fifo_full(&uart0));
    uart_tx(&uart0, 'E'); 
}

char uart_rx_char()
{
    while (uart_rx_fifo_empty(&uart0));
    return uart_rx(&uart0);
}

void receive_binary(volatile uint8_t *dest, uint32_t length)
{
    uint32_t last_percent = 0;

    uart_tx_string(&uart0, "Receiving binary: 0%");

    for (uint32_t i = 0; i < length; i++)
    {
        while (uart_rx_fifo_empty(&uart0));
        dest[i] = uart_rx(&uart0);

        int percent = (i * 100) / length;

        // Print percentage only if it has increased by at least 10%
        if (percent >= last_percent + 10)
        {
            uart_tx_string(&uart0, "====%");
            last_percent = percent;
            char buffer[8];
            int2string(percent, buffer);
            uart_tx_string(&uart0, buffer);   
        }
    }

    uart_tx_string(&uart0, "===>100% Transfer completed.\n\n\r");
}

int main(void)
{
    
    uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
    uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

    while (1)
    {
    
        uart_tx_string(&uart0, "\n\n\r+-------------------------------+\n\r|  NOVACore SSBL MENU  CS3@FAU  |\n\r+-------------------------------+\n\r1. RESET AND RELOAD A NEW SSBL! \n\r2. CONTINUE WITH UPLOADING AN APPLICATION \n\rSELECT > ");
        char option = uart_rx_char();
        uart_tx(&uart0, option); 

        if (option == '1') 
        {
            FSBL_start();
        }
        else if (option == '2')
        {
            uart_tx_string(&uart0, "\n\rWAITING FOR AN APPLICATION ...\n\n\r");
            receive_binary(APP_MEM, APP_LEN);

            // Execute the application
            APP_start();
        }
        else
        {
            uart_tx_string(&uart0, "\n\rINVALID OPTION! TRY AGAIN.\n\r");
        }
    }

    return 0;
}

void int2string(int n, char *s)
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
