#include <stdint.h>

volatile float A = 2.5f;
volatile float B = 3.75f;

volatile float add_res;
volatile float sub_res;
volatile float mul_res;
volatile float div_res;

volatile int cmp_eq;
volatile int cmp_lt;
volatile int cmp_le;

volatile int int_val = -4;
volatile float conv_f;
volatile int conv_i;

int main()
{
    float a = A;
    float b = B;

    // arithmetic
    add_res = a + b;
    sub_res = a - b;
    mul_res = a * b;
    div_res = a / b;

    // comparisons
    cmp_eq = (a == b);
    cmp_lt = (a < b);
    cmp_le = (a <= b);

    // conversions
    conv_f = (float)int_val;
    conv_i = (int)a;

    // move through memory
    float tmp;
    tmp = a;
    a = tmp;

    return 0;
}