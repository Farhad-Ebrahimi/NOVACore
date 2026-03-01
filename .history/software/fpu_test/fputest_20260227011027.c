#include "func.h"

//-------- Start NOVA setup--------
#include "timer.h"
#include "uart.h"
#include "platform.h"
#include "potato.h"

static struct uart uart0;
static struct timer timer0;

void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
    if ((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
    {
        uint8_t irq = mcause & 0x0f;

        if (irq == PLATFORM_IRQ_TIMER0)
        {
            timer_clear(&timer0);
        }
    }
}
// -------- End NOVA setup--------

int main()
{
    // NOVA platform initialization

    // Configure the UART:
    uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
    uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
    uart_tx_string(&uart0, "--- FPU Test Application ---\r\n\n");

    // Set up timer0 at 1 Hz:
    timer_initialize(&timer0, (volatile void *)PLATFORM_TIMER0_BASE);
    timer_reset(&timer0);
    timer_set_compare(&timer0, PLATFORM_SYSCLK_FREQ);
    timer_start(&timer0);

    // Enable interrupts:
    potato_enable_irq(PLATFORM_IRQ_TIMER0);
    potato_enable_interrupts();

    // End NOVA platform initialization

    float a = 3.14159f;
    float b = 2.71828f;
    char buffer[32];

    // Converts float to string with 4 decimal places
    fp2str(mul(a,b), buffer, 4);
    uart_tx_string(&uart0, buffer);
    uart_tx_string(&uart0, "\r\n");

    return 0;
}