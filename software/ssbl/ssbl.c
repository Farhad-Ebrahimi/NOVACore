// The NOVACore - A 7-stage in-order RISC-V processor for FPGAs
// (c) Farhad EbrahimiAzandaryani 2023-2024 <farhad.ebrahimiazandaryani@fau.de>
// Demonstration : <https://www.cs3.tf.fau.de/nova-core-2/>
// Report bugs and issues on <https://github.com/Farhad-Ebrahimi/NOVACore/issues>


#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "platform.h"
#include "uart.h"

#define APP_LEN   0x80000      // 512 KB
#define APP_ADDR  0x00000000   // Valid start address
#define FSBL_ADDR 0xffff8000

static struct uart uart0;

typedef void (*boot_func_t)(void);
#define APP_start  ((boot_func_t)APP_ADDR)
#define FSBL_start ((boot_func_t)FSBL_ADDR)
#define APP_MEM    ((volatile uint8_t *)APP_ADDR)

/* Prototypes */
void int2string(int n, char *s);
void receive_binary(volatile uint8_t *dest, uint32_t length);
char uart_rx_char(void);

void exception_handler(uint32_t cause, void *epc, void *regbase) {
    while (uart_tx_fifo_full(&uart0));
    uart_tx(&uart0, 'E');
}

char uart_rx_char() {
    while (uart_rx_fifo_empty(&uart0));
    return uart_rx(&uart0);
}

/* Updated Binary Receiver */
void receive_binary(volatile uint8_t *dest, uint32_t length) {
    // Check if length is zero or if the end address exceeds 512KB
    if (length == 0 || ((uintptr_t)dest + length) > APP_LEN) {
        uart_tx_string(&uart0, "\n\rError: Invalid length or memory overflow!\n\r");
        return;
    }

    uint32_t last_percent = 0;
    volatile uint8_t *ptr = dest;

    uart_tx_string(&uart0, "Receiving binary: 0%");

    for (uint32_t i = 0; i < length; i++) {
        while (uart_rx_fifo_empty(&uart0));

        *ptr++ = uart_rx(&uart0);

        uint32_t percent = (i * 100) / length;
        if (percent >= last_percent + 10) {
            char buffer[8];
            int2string(percent, buffer);
            uart_tx_string(&uart0, "->");
            uart_tx_string(&uart0, buffer);
            uart_tx_string(&uart0, "%");
            last_percent = percent;
        }
    }
    uart_tx_string(&uart0, " 100% [Transfer completed]\n\r");
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
