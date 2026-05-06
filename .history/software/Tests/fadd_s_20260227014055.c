#include <stdio.h>
void fadd(float a,float b, float c)
{
    c = a + b;
}

int main()
{
    float a = 3.14159f;
    float b = 2.71828f;
    float c;

    fadd(a, b, c);
    printf("Result: %f\n", c); // This will not print the correct result due to pass-by-value

    return 0;
}