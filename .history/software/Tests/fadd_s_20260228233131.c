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


// We use a specific pointer to a known memory location in your RAM
// Your RAM starts at 0x00000000 and has a length of 0x00080000
#define TEST_MEM_ADDR  0x00040000 

void test_fsw_storage(void) {
    // 1. Load integer 5 into a register (li x15, 5)
    volatile int int_val = 5;
     volatile int int_val = 2;
    // 2. Convert to float (fcvt.s.w f10, x15)
    // This puts 5.0f (0x40a00000) into an FP register
    float f_val = (float)int_val;

    // 3. Store the float into memory (fsw f10, 0(a0))
    // We use a pointer to force a store to the Data Bus
   // volatile float *mem_ptr = (volatile float *)TEST_MEM_ADDR;
   // *mem_ptr = f_val;
}

int main(void) {
    test_fsw_storage();
    while(1); 
    return 0;
}