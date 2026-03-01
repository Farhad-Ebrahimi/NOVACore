#include <stdio.h>
#include <stdint.h>
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
---static float fadd(float a, float b)
---{
---    return a + b;
---}



int main()
{
    volatile uint32_t i0 = 0x40490FDB;   // 3.14159f
    volatile uint32_t i1 = 0x402DF854;   // 2.71828f

    volatile float f0;
    volatile float f1;

    volatile uint32_t out0;
    volatile uint32_t out1;

    /* Move integer -> FP register */
    __asm__ volatile (
        "fmv.w.x %0, %1"
        : "=f"(f0)
        : "r"(i0)
    );

    __asm__ volatile (
        "fmv.w.x %0, %1"
        : "=f"(f1)
        : "r"(i1)
    );

    /* Move FP register -> integer */
    __asm__ volatile (
        "fmv.x.w %0, %1"
        : "=r"(out0)
        : "f"(f0)
    );

    __asm__ volatile (
        "fmv.x.w %0, %1"
        : "=r"(out1)
        : "f"(f1)
    );

    while(1);   // stay here for simulation
}