#include <stdint.h>
#include <string.h>

#include "platform.h"
#include "uart.h"

#define SSBL_LEN (0x00800)
#define SSBL_ADDR (0xffff8400)

static struct uart uart0;
typedef void (*SSBL_func_t)(void);
#define SSBL_start ((SSBL_func_t)SSBL_ADDR)

#define SSBL_MEM ((volatile uint8_t *)SSBL_ADDR)

void exception_handler(uint32_t cause, void *epc, void *regbase)
{
    while (uart_tx_fifo_full(&uart0));
    uart_tx(&uart0, 'E');
}

int main(void)
{
    uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
    uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

    uart_tx_string(&uart0, "\n\r$ NOVACore FSBL Menu:");
    uart_tx_string(&uart0, "\n\r> Waiting for SSBL...\n\r");

    for (int i = 0; i < SSBL_LEN; i++)
    {
        while (uart_rx_fifo_empty(&uart0));
        SSBL_MEM[i] = uart_rx(&uart0);

        if ((i & 0x3F) == 0 && !uart_tx_fifo_full(&uart0))
            uart_tx(&uart0, '.');
    }

    if (*(volatile uint32_t *)SSBL_ADDR == 0xFFFFFFFF)
    {
        uart_tx_string(&uart0, "\n\rError: SSBL not loaded! Halting...\n\r");
        while (1);
    }
    uart_tx_string(&uart0, "\n\r SSBL loaded sucessfully!\n\r");
    uart_tx_string(&uart0, "\n\r Jumping to SSBL...\n\r");

    SSBL_start();

    return 0;
}
