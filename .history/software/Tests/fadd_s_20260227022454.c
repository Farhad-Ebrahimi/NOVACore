#include <stdio.h>
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
float fadd(float a, float b)
{
    return a + b;
}

int main()
{
    float a = 3.14159f;
    float b = 2.71828f;

    float c = fadd(a, b);

    printf("Result: %f\n", c);

    return 0;
}