#ifndef function_H
#define function_H


#include "../platform.h"
#include "../potato.h"

#include "../libsoc/gpio.h"
#include "../libsoc/icerror.h"
#include "../libsoc/timer.h"
#include "../libsoc/uart.h"

#define SIZE 20

extern struct uart uart0;

void int2string(int n, char *s);
void int2hex32(uint32_t n, char *s);
void fill_matrices();
void multiply_matrices();
void print_result();


#endif /* function_H */
