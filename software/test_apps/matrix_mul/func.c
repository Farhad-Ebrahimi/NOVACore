#include <stdio.h>
#include <stdbool.h>
#include <stdint.h>
#include "func.h"
#include "../libsoc/uart.h"


int A[SIZE][SIZE];
int B[SIZE][SIZE];
int C[SIZE][SIZE];
char int2str[16];
int mul_op;
int add_op;

void fill_matrices() {
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            A[i][j] = 1;  // Or use any formula/data
            B[i][j] = j;
            C[i][j] = 0;
        }
    }
}

void multiply_matrices() {
	mul_op = 0;
	add_op = 0;
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            for (int k = 0; k < SIZE; k++) {
                C[i][j] += A[i][k] * B[k][j];
				mul_op  += 1;
				add_op  += 1;
            }
			add_op  -= 1;
        }
    }
	uart_tx_string(&uart0, "MATRIX [SIZE][SIZE]: ");
	int2string(SIZE, int2str);
	uart_tx_string(&uart0, "[");
	uart_tx_string(&uart0, int2str);
	uart_tx_string(&uart0, "]*[");
	uart_tx_string(&uart0, int2str);
	uart_tx_string(&uart0, "]\n\r");
	
	uart_tx_string(&uart0, "# MUL_OPERATIONS: ");
	int2string(mul_op, int2str);
	uart_tx_string(&uart0, int2str);
	uart_tx_string(&uart0, "\n\r");
	uart_tx_string(&uart0, "# ADD_OPERATIONS: ");
	int2string(add_op, int2str);
	uart_tx_string(&uart0, int2str);
	uart_tx_string(&uart0, "\n\n\r");
}

void print_result() {
    // Just print part of the matrix to verify
	for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            
				int2string(A[i][j], int2str);
				uart_tx_string(&uart0, int2str);
				uart_tx_string(&uart0, " ");
        }
		uart_tx_string(&uart0, "\n\r");
    }
	uart_tx_string(&uart0, "\n\n\n\r");
	for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            
				int2string(B[i][j], int2str);
				uart_tx_string(&uart0, int2str);
				uart_tx_string(&uart0, " ");
        }
		uart_tx_string(&uart0, "\n\r");
    }
	uart_tx_string(&uart0, "\n\n\n\r");
	for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            
				int2string(C[i][j], int2str);
				uart_tx_string(&uart0, int2str);
				uart_tx_string(&uart0, " ");
        }
		uart_tx_string(&uart0, "\n\r");
    }
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

void int2hex32(uint32_t n, char *s)
{
	static const char *hex_digits = "0123456789abcdef";

	int index = 0;
	for (int i = 28; i >= 0; i -= 4)
		s[index++] = hex_digits[(n >> (32 - i)) & 0xf];
	s[index] = 0;
}

