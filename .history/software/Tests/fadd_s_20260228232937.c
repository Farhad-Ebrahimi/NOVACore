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


//#include <stdio.h>

int main() {
    int a = 2;
    int b = 3;
    int result_int;

    // Use inline assembly to bypass standard C float handling
    asm volatile (
        "fcvt.s.w f1, %1\n\t"   // Convert int 'a' (2) from x-reg to f1
        "fcvt.s.w f2, %2\n\t"   // Convert int 'b' (3) from x-reg to f2
        "fadd.s   f3, f1, f2\n\t" // Add f1 + f2 = 5.0 in Stage 3
        "fcvt.w.s %0, f3\n\t"   // Convert f3 (5.0) back to int in %0 (result_int)
        : "=r" (result_int)     // Output: %0 maps to result_int
        : "r" (a), "r" (b)      // Inputs: %1 maps to a, %2 maps to b
        : "f1", "f2", "f3"      // Clobbered registers
    );

    // If the hardware is correct, this will print 5
    if (result_int == 5) {
        printf("Success! Result: %d\n", result_int);
    } else {
        printf("Fail! Result: %d\n", result_int);
    }

    return 0;
}