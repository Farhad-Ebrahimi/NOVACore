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


// This function forces the use of fmv.s.x and fmv.x.s
uint32_t test_fmv(uint32_t int_data) {
    union {
        uint32_t i;
        float f;
    } pun;

    // 1. Load integer data into the union
    pun.i = int_data;

    // 2. The compiler must move 'i' from an integer register to an FPU register 
    // to perform this math. This generates: fmv.w.x (fmv.s.x)
    float result_f = pun.f + 1.0f;

    // 3. Move the float result back to the union to return it as an integer
    // This generates: fmv.x.w (fmv.x.s)
    pun.f = result_f;
    
    return pun.i;
}

int main(void) {
    // Example: bit pattern for 2.0f is 0x40000000
    uint32_t input = 0x40000000; 
    uint32_t output = test_fmv(input);

    return (int)output;
}