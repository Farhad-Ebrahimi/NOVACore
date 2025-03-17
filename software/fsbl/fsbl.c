// The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
// (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
// Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
// Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>

// Based on:
// The Potato Processor - A simple processor for FPGAs
// (c) Kristian Klomsten Skordal 2014 - 2015 <kristian.skordal@wafflemail.net>
// Report bugs and issues on <https://github.com/skordal/potato/issues>

#include <stdint.h>
#include <string.h>

#include "platform.h"
#include "uart.h"

#define SSBL_LEN (0x007fc)
#define VALD_ADDR (0xffff8400)
#define SSBL_ADDR (0xffff8404)

static struct uart uart0;
typedef void (*SSBL_func_t)(void);
#define SSBL_start ((SSBL_func_t)SSBL_ADDR)
#define SSBL_MEM ((volatile uint8_t *)SSBL_ADDR)
#define VALD_REG ((volatile uint8_t *)VALD_ADDR)

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

int main(void)
{
    uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
    uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

    while (1)
    {
        uart_tx_string(&uart0, "\n\n\r+-------------------------------+\n\r|  NOVACore FSBL MENU  CS3@FAU  |\n\r+-------------------------------+\n\r1. HARD RESET [NEW SSBL!] \n\r2. CONTINUE WITH EXISTING SSBL \n\rSELECT > ");
        char option = uart_rx_char();
        uart_tx(&uart0, option);

        if (*VALD_REG != 1)
            *VALD_REG = 0;

        if (option == '1')
        {
            uart_tx_string(&uart0, "\n\n\rUPLOAD AN SSBL...\n\n\r");
            for (int i = 0; i < SSBL_LEN; i++)
            {
                while (uart_rx_fifo_empty(&uart0));
                SSBL_MEM[i] = uart_rx(&uart0);

                if ((i & 0x7F) == 0)
                    uart_tx(&uart0, '.');
            }
            *VALD_REG = 1;
            SSBL_start();
        }
        else if (option == '2')
        {
            if (*VALD_REG == 1)
                SSBL_start();
            else
                uart_tx_string(&uart0, "\n\rWARN: SSBL NOT FOUND!\n\r");
        }
        else
            uart_tx_string(&uart0, "\n\rINVALID!\n\r");
    }
    return 0;
}
