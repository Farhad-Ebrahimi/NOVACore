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
    // 1. Bit-pattern for 3.14159... (IEEE-754)
    // Loading this as an integer uses 'lui' and 'addi' (embedded in .text)
    uint32_t bit_pattern = 0x40490fdb; 
    
    // Union forces the compiler to use 'fmv.w.x' to move bits to the FPU
    union {
        uint32_t i;
        float f;
    } pun;

    pun.i = bit_pattern;
    volatile float f_val = pun.f; 

    // 2. Perform math - This will generate 'fadd.s'
    // 1.0f is also an immediate that the compiler can often optimize
    f_val = f_val + 1.0f;

    // 3. Convert back to integer - This generates 'fcvt.w.s'
    // Storing to a volatile int ensures the instruction isn't skipped
    volatile int final_result = (int)f_val;
}

int main(void)
{
    test_conversion();
    while(1); // Keep the processor active
    return 0;
}