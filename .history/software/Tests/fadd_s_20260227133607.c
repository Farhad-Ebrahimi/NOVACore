#include <stdio.h>
#include "C:\Users\User\Downloads\novacore\libsoc\timer.h"
#include "C:\Users\User\Downloads\novacore\libsoc\uart.h"
#include "C:\Users\User\Downloads\novacore\platform.h"
#include "C:\Users\User\Downloads\novacore\potato.h"

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
#include <stdint.h>

// Use volatile to prevent the compiler from pre-calculating the result
volatile float a = 2.0f;
volatile float b = 3.0f;
volatile float result;

void fpu_addition_test() {
    // This will generate:
    // 1. flw fa4, addr(a)
    // 2. flw fa5, addr(b)
    // 3. fadd.s fa5, fa4, fa5
    // 4. fsw fa5, addr(result)
    result = a + b;
}

int main(void) {
    fpu_addition_test();
    while(1); // Halt
    return 0;
}