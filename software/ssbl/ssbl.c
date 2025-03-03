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

static struct uart uart0;
typedef void (*boot_func_t)(void); 
#define APP_start  ((boot_func_t)APP_ADDR)
#define APP_MEM  ((volatile uint8_t *)APP_ADDR)

void exception_handler(uint32_t cause, void *epc, void *regbase)
{
    while (uart_tx_fifo_full(&uart0));
    uart_tx(&uart0, 'E'); 
}

void receive_binary(volatile uint8_t *dest, uint32_t length)
{
    for (uint32_t i = 0; i < length; i++)
    {
        while (uart_rx_fifo_empty(&uart0));
        dest[i] = uart_rx(&uart0);

        if ((i & 0x7F) == 0 && !uart_tx_fifo_full(&uart0))
            uart_tx(&uart0, '.');
    }
}

uint8_t get_user_choice()
{
    uart_tx_string(&uart0, "\n\n\r$ NOVACore SSBL Bootloader Menu");
    uart_tx_string(&uart0, "\n\r1 - Reset & Reload a New SSBL");
    uart_tx_string(&uart0, "\n\r2 - Upload Application for Execution");
    uart_tx_string(&uart0, "\n\rChoose an option: ");

    while (uart_rx_fifo_empty(&uart0)); 
    return uart_rx(&uart0);
}

int main(void)
{
    
    uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
    uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));

    while (1)
    {
    
        uint8_t choice = get_user_choice();
        uart_tx(&uart0, choice); 

        if (choice == '1') 
        {
            
        }
        else if (choice == '2')
        {
            uart_tx_string(&uart0, "\n\rWaiting for an Application ...\n\r");

            receive_binary(APP_MEM, APP_LEN);

            uart_tx_string(&uart0, "\n\rApplication upload complete. Executing...\n\r");

            // Execute the application
            APP_start();
        }
        else
        {
            uart_tx_string(&uart0, "\n\rInvalid option. Try again.\n\r");
        }
    }

    return 0; // Should never reach here
}
