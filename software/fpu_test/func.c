
#include "func.h"
#include <stdio.h>
#include <stdbool.h>

# define SCALE 1.0f 

int sum (int a, int b) 
{ 
    return a + b; 
}

float fsum (float a, float b) 
{ 
    return a + b; 
}
void int2string(int n, char *s)
{
    bool first = true;

    if (n == 0)
    {
        s[0] = '0';
        s[1] = 0;
        return;
    }

    if (n & (1u << 31))
    {
        n = ~n + 1;
        *(s++) = '-';
    }

    for (int i = 1000000000; i > 0; i /= 10)
    {
        if (n / i == 0 && !first)
            *(s++) = '0';
        else if (n / i != 0)
        {
            *(s++) = '0' + n / i;
            n %= i;
            first = false;
        }
    }
    *s = 0;
}


