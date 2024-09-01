#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "func.h"

uint8_t my_rand()
{
    static unsigned long next = 1;  // Use static to retain state
    next = next * 2 + 3;
    return (uint8_t)(next % 256);
}

void init_arr(uint8_t *a, uint8_t *b, uint8_t *c, uint8_t *d, int n)
{
    for (int i = 0; i < n; i++)
    {
        a[i] = 0;
        b[i] = my_rand();
        c[i] = my_rand();
        d[i] = my_rand();
    }
}

void func(uint8_t *a, uint8_t *b, uint8_t *c, uint8_t *d, int n)
{
    //int mul1,mul2,mul3;
     
    for (int i = 0; i < n; i += 1) // --> Don't forget to change the loop index increment to 3 for 3-way loop-unrolling
    {
        // without loop-unrolling
        a[i] = b[i] * c[i] + d[i];
        
        // uncomment to see loop-unrolling strategy in NOVACore
        /* 
        mul1 = b[i] * c[i];
        mul2 = b[i + 1] * c[i + 1];
        mul3 = b[i + 2] * c[i + 2];
        a[i] = mul1 + d[i];
        a[i + 1] = mul2 + d[i + 1];
        a[i + 2] = mul3 + d[i + 2];
        */
    }
}
