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

#define TEST_ADDR 0x80000200 

int main()
{
    // Use volatile to force memory access (fsw)
    volatile float a = 3.14159f;
    volatile float b = 2.71828f;
    
    // Store values to a specific memory location manually if needed
    float *ptr = (float *)TEST_ADDR;
    
    // This will trigger 'fsw' (store)
    *ptr = a; 
    
    // This will trigger 'flw' (load)
    volatile float c = *ptr; 

    while(1);
    return 0;
}