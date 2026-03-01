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

void test_conversion() {
    // 1. Start with an integer
    int int_val = 1078530000; 
    
    float f_val;
    // 2. Move bits to float without changing them (Bit-cast)
    // This often compiles to fmv.w.x
    f_val = *(float*)&int_val; 

    // 3. Do math
    f_val = f_val + 1.0f;

    // 4. Convert back to integer (Rounding)
    // This often compiles to fcvt.w.s
    int final_result = (int)f_val;
}

int main()
{
    test_conversion();
    return 0;
}