#include <stdio.h>
float fadd(float a, float b)
{
    return a + b;
}

int main()
{
    float a = 3.14159f;
    float b = 2.71828f;

    float c = fadd(a, b);

    printf("Result: %f\n", c);

    return 0;
}