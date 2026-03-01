#include <stdio.h>
#include "timer.h"
#include "uart.h"
#include "platform.h"
#include "potato.h"

//static struct uart uart0;
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
static int fadd(int a, int b)
{
    return a + b;
}

int main()
{
    volatile int a = 3;
    volatile int b = 2;

    volatile int result = fadd(a, b);

    while(1);
}