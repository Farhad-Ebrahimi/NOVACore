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

void test_conversion(void) {
    // 1. Load the IEEE-754 bit pattern as a 32-bit integer literal.
    // This value (0x40490fdb) represents ~3.14159.
    // It is baked into the .text section via 'lui' and 'addi'.
    uint32_t bit_pattern = 0x40490fdb; 
    
    // 2. Use a union to cast bits from Integer to Float registers.
    // This generates the 'fmv.w.x' instruction.
    union {
        uint32_t i;
        float f;
    } pun;

    pun.i = bit_pattern;
    volatile float f_val = pun.f; 

    // 3. Perform FPU math (generates 'fadd.s').
    f_val = f_val + 1.0f;

    // 4. Convert back to integer (generates 'fcvt.w.s').
    // Rounding is handled by the hardware FPU.
    volatile int final_result = (int)f_val;
}

int main(void)
{
    test_conversion();
    while(1); // Prevent execution from entering uninitialized memory
    return 0;
}