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
volatile float b = 3.0001f;
volatile float a = 2.000f;

static float int_to_float (int a)
{
    return (float)a ;
}


int main()
{
    

   

    int num1= 2;
    int num2= 3;
    float f1 = int_to_float(num1);
    int_to_float(num2);





    //volatile int int_result = (int)result;

    while(1);
}
