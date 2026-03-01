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

//static float fadd(float a, float b)
//{
//    return a + b;
//}



volatile uint32_t input0 = 0x40490FDB;
volatile uint32_t input1 = 0x402DF854;

int main()
{
    union {
        uint32_t i;
        float f;
    } u;

    u.i = input0;
    float f0 = u.f;

    u.i = input1;
    float f1 = u.f;

    volatile uint32_t out0 = *(uint32_t*)&f0;
    volatile uint32_t out1 = *(uint32_t*)&f1;

    while (1);
}