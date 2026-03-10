#include <stdio.h>
#include <stdint.h>
#include "C:\Users\User\Downloads\novacore\libsoc\timer.h"
#include "C:\Users\User\Downloads\novacore\libsoc\uart.h"
#include "C:\Users\User\Downloads\novacore\platform.h"
#include "C:\Users\User\Downloads\novacore\potato.h"

static struct uart uart0;
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


int main()
{

    volatile int A = 4;
    volatile int B = 5;
 //volatile int C = A + B;
 //volatile float D = (float)C;
 //volatile float E = (float)B;
 //volatile float F = (float)A;
 //volatile float G = D/E;
 //if (G < A)
 //{
 //  volatile  float H = D - E;
 //}
 // if (G >= A)
 //{
 //    volatile float H = D + E;
 //}

     A= (float)A;
      B= (float)B;
      volatile float C = A * B;

}

