#include <stdio.h>
#include "C:\Users\User\Downloads\novacore\libsoc\timer.h"
#include "C:\Users\User\Downloads\novacore\libsoc\uart.h"
#include "C:\Users\User\Downloads\novacore\platform.h"
#include "C:\Users\User\Downloads\novacore\potato.h"

//static struct uart uart0;
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


// We use a specific pointer to a known memory location in your RAM
// Your RAM starts at 0x00000000 and has a length of 0x00080000
//#define TEST_MEM_ADDR  0x00040000 
//
//int test_fpu_logic_mul() {
//    volatile int a = 12;
//    volatile int b = 4;
//    float f1 = (float)a; // fcvt.s.w
//    float f2 = (float)b; // fcvt.s.w
//   float sum = f1 * f2; // fadd.s
//   return (int)sum;     // fcvt.w.s
//}


float test_fpu_logic_mul() {
    volatile int a = 12;
    volatile int b = 4;
    float f1 = (float)a; // fcvt.s.w
    float f2 = (float)b; // fcvt.s.w
   float sum = f1 * f2; // fadd.s
   return (int)sum;     // fcvt.w.s
}


//void test_fpu_logic_mul() {
//    //volatile int a = 12;
//    //volatile int b = 4;
//    volatile float f1 = 12.0f; // fcvt.s.w
//    volatile float f2 = 4.0f; // fcvt.s.w
//    volatile float a_f = f1;
//    volatile float b_f = f2;
//    //volatile int c = (int)a_f;
//   
//        // fcvt.w.s
//}



//float test_fpu_logic_mul2() {
//    volatile int a = 10;
//    volatile int b = 5;
//    float f1 = (float)a; // fcvt.s.w
//    float f2 = (float)b; // fcvt.s.w
//   float sum = f1 * f2; // fadd.s
//   return (int)sum;     // fcvt.w.s
//}



//int test_fpu_logic_add() {
//    volatile int a = 2;
//    volatile int b = 3;
//    float f1 = (float)a; // fcvt.s.w
//    float f2 = (float)b; // fcvt.s.w
//   float sum = f1 + f2; // fadd.s
//   return (int)sum;     // fcvt.w.s
//}



int test_fpu_logic_add_1() {
   volatile int a = 20;
   volatile int b = 6;
   float f1 = (float)a; // fcvt.s.w
   float f2 = (float)b; // fcvt.s.w
  float sum = f1 + f2; // fadd.s
  return (int)sum;     // fcvt.w.s
}

////
////
//
//int test_fpu_logic_sub() {
//   volatile int a = 10;
//   volatile int b = 1;
//   float f1 = (float)a; // fcvt.s.w
//   float f2 = (float)b; // fcvt.s.w
//  float sum = f1 - f2; // fadd.s
//  return (int)sum;     // fcvt.w.s
//}
//

//int test_fpu_logic_div() {
//   volatile int a = 10;
//   volatile int b = 1;
//   float f1 = (float)a; // fcvt.s.w
//   float f2 = (float)b; // fcvt.s.w
//  float sum = f1 / f2; // fdiv.s
//  return (int)sum;     // fcvt.w.s
//}


///int main(void) {
///
///   //volatile int result_add = test_fpu_logic_add();
///   //volatile int result_mul = test_fpu_logic_mul();
///   //volatile int result_sub = test_fpu_logic_sub();
///   //volatile int result_div = test_fpu_logic_div();
/////  volatile int result_add = test_fpu_logic_add();
///// volatile int result_sub = test_fpu_logic_sub();
///volatile int result_add_1 = test_fpu_logic_add_1();
/////test_fpu_logic_mul();
///   
///    
///
///    while(1); 
///    return 0;
///}


float conv(int a){
    return (float)a;
}



//nt main() {
//
////volatile int num = 10;
////  volatile float fnum = conv(num); // fcvt.s.w
////  volatile int a = (int)fnum; // fcvt.w.s
////  while (1);
//
//   volatile int a = 12; 
//   volatile int b = 4;
//
//   //volatile float f1 = conv(a); 
//   //volatile float f2 = conv(b);
//   //volatile float sum = f1 + f2;
//  //
//
//  volatile float f1 = (float)a; 
//   while(1);
//   return 0;
//




int main() {
    uint32_t x = 0x41800000;
    float f;

    memcpy(&f, &x, sizeof(float));

    printf("float = %f\n", f);

    uint32_t y;
    memcpy(&y, &f, sizeof(uint32_t));

    printf("hex = 0x%08x\n", y);

    return 0;
}