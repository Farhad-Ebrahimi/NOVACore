#include <stdio.h>
#include "func.h"
#include "../../libsoc/timer.h"
#include "../../libsoc/uart.h"
#include "../../platform.h"
#include "../../potato.h"

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


int main(void)
{
    uart_tx_string(&uart0, "dbg msg: starting test\r\n");
    volatile int a = 1;
    volatile int b = 2;
    volatile int c = conv(a); 

    char buf[32];
    int ipart = (int)c;
    int fpart = (int)((c - ipart) * 1000000); // Get the fractional part up to 6 decimal places

    uart_tx_string(&uart0, "result: ");
    // convert integer part to string
    intToStr(ipart, buf, 0);
    uart_tx_string(&uart0, buf);
    uart_tx_string(&uart0, ".");
    intToStr(fpart, buf, 6); // 6 digits for fractional part
    uart_tx_string(&uart0, buf);
    uart_tx_string(&uart0, "\r\n");

    // test_fpu_logic_mul();
    return 0;
}