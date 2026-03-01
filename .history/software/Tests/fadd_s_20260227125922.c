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
    volatile uint32_t debug_mcause = mcause;

    while(1);   // stop here
}


// This function forces the use of fmv.s.x and fmv.x.s
uint32_t test_fmv(uint32_t int_data) {
    union {
        uint32_t i;
        float f;
    } pun;

    
    pun.i = int_data;

    
    float result_f = pun.f + 1.0f;

    
    pun.f = result_f;
    
    return pun.i;
}

int main(void) {
    
    uint32_t input = 0x40000000; 
    uint32_t output = test_fmv(input);

    return (int)output;
}