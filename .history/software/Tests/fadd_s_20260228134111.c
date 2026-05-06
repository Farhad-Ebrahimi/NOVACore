#include <stdio.h>
#include "C:\Users\User\Downloads\novacore\libsoc\timer.h"
#include "C:\Users\User\Downloads\novacore\libsoc\uart.h"
#include "C:\Users\User\Downloads\novacore\platform.h"
#include "C:\Users\User\Downloads\novacore\potato.h"
#include <stdint.h>

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


float test_conversion()
{
    volatile int a = 2; // volatile forces the compiler to treat these as real variables
    volatile int b = 3;
    return (float)a + (float)b;
}

int main(void)
{
    float result = test_conversion();
    printf("Result of 2.0 + 3.0 = %f\n", result);
    while(1); // Prevent execution from entering uninitialized memory
    return 0;
}