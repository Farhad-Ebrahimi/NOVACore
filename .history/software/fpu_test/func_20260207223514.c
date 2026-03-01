#include "C:\Users\User\Downloads\novacore-feature-openlane2-sky130nm-compatibility\novacore-feature-openlane2-sky130nm-compatibility\fpu_test\func.h"

float mul(float in1, float in2) 
{
    return in1 * in2;
}

// Helper to reverse a string
void reverse(char* str, int len) {
    int i = 0, j = len - 1, temp;
    while (i < j) {
        temp = str[i];
        str[i] = str[j];
        str[j] = temp;
        i++; j--;
    }
}

// Helper to convert int to string
int int_to_str(int32_t x, char str[], int d) {
    int i = 0;
    int is_negative = 0;

    if (x < 0) {
        is_negative = 1;
        x = -x;
    }

    while (x) {
        str[i++] = (x % 10) + '0';
        x = x / 10;
    }

    // Fill with zeros to meet precision
    while (i < d) str[i++] = '0';

    if (is_negative) str[i++] = '-';

    reverse(str, i);
    str[i] = '\0';
    return i;
}

// THE MAIN FUNCTION: my_ftoa
void fp2str(float n, char* res, int afterpoint) {
    // 1. Handle integer part
    int32_t ipart = (int32_t)n;

    // 2. Handle fractional part
    float fpart = n - (float)ipart;
    if (fpart < 0) fpart = -fpart;

    // Convert integer part to string
    int i = int_to_str(ipart, res, 0);

    // 3. Add decimal point and fractional digits
    if (afterpoint != 0) {
        res[i] = '.'; 

        // Multiply fractional part by 10^afterpoint
        // Example: 0.14 * 100 = 14
        float multiplier = 1.0f;
        for (int j = 0; j < afterpoint; j++) multiplier *= 10.0f;
        
        int32_t fpart_int = (int32_t)(fpart * multiplier + 0.5f); // +0.5 for rounding

        int_to_str(fpart_int, res + i + 1, afterpoint);
    }
}