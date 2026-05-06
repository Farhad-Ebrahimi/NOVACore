#include <stdio.h>
#include "C:\Users\User\Downloads\novacore\libsoc\timer.h"
#include "C:\Users\User\Downloads\novacore\libsoc\uart.h"
#include "C:\Users\User\Downloads\novacore\platform.h"
#include "C:\Users\User\Downloads\novacore\potato.h"

static struct uart uart0;
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


//int main(void)
//{
//    uart_tx_string(&uart0, "dbg msg: starting test\r\n");
//    volatile int a = 1;
//    volatile int b = 2;
//    volatile int c = conv(a); 
//
//    char buf[32];
//    int ipart = (int)c;
//    int fpart = (int)((c - ipart) * 1000000); // Get the fractional part up to 6 decimal places

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



float test_fpu_logic_add(int a, int b) {
   
    float f1 = (float)a; // fcvt.s.w
    float f2 = (float)b; // fcvt.s.w
   float sum = f1 + f2; // fadd.s
   return sum;     // fcvt.w.s
}


float conv(int a){
   return (float)a; }


//int test_fpu_logic_add_1() {
//   volatile int a = 20;
//   volatile int b = 6;
//   float f1 = (float)a; // fcvt.s.w
//   float f2 = (float)b; // fcvt.s.w
//  float sum = f1 + f2; // fadd.s
//  return (int)sum;     // fcvt.w.s
//}

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

int test_fpu_logic_div() {
   volatile int a = 10;
   volatile int b = 2;
   float f1 = (float)a; // fcvt.s.w
   float f2 = (float)b; // fcvt.s.w
  float sum = f1 / f2; // fdiv.s
  return (int)sum;     // fcvt.w.s
}


int main(void) {

  // volatile int a = 2;
  // volatile int b = 3;
  // volatile float b_f = (float)b;       ////3 is converted into float 
  ////volatile int result_add = test_fpu_logic_add();
  volatile int result_mul = test_fpu_logic_mul();
  ////volatile int result_sub = test_fpu_logic_sub();
  //volatile int result_div = test_fpu_logic_div();
//// volatile int result_add = test_fpu_logic_add();
////volatile int result_sub = test_fpu_logic_sub();
  // volatile float result_add_1 = test_fpu_logic_add(a, b);    ///--> 2 and 3 are converted into float and then added together to give 5.0f
  // if (result_add_1 > b_f) {

  //     volatile int c = 10;

  //     volatile float f1 = conv(c); // fcvt.s.w  /// 41200000 
  //         volatile float f2 = f1 * result_add_1;
  //     //printf("Result of multiplication: %f\n",f2);
  //  }  //// 10 * 5.0 

  // else 
  // {

  //      volatile int d = (int)result_add_1;
  // 
  // 
  // }
  //           





//// while(1); 
//// uart_tx_string(&uart0, "result: ");
//// // convert integer part to string
//// intToStr(ipart, buf, 0);
//// uart_tx_string(&uart0, buf);
//// uart_tx_string(&uart0, ".");
//// intToStr(fpart, buf, 6); // 6 digits for fractional part
//// uart_tx_string(&uart0, buf);
//// uart_tx_string(&uart0, "\r\n");
////
//// // test_fpu_logic_mul();
    return 0;
}






//nt main() {
//
///volatile int num = 10;
///  volatile float fnum = conv(num); // fcvt.s.w
///  volatile int a = (int)fnum; // fcvt.w.s
///  while (1);
//
//  volatile int a = 12; 
//  volatile int b = 4;
//
//  volatile float f1 = conv(a); 
//  volatile float f2 = conv(b);
//  volatile float sum = f1 + f2;
//
//  volatile int c = (int)sum;
// 
//
// //volatile float f1 = (float)a; 
//  while(1);
//  return 0;
//
//


//int main(){
//    // Union allows reinterpreting the bits
//    union { 
//        volatile float f; 
//        volatile int32_t i; 
//    } u;
//    
//    // Set the bit pattern for 12.0f
//    u.i = 0x41400000;
//    
//    // Read back as float - triggers fmv.w.x
//    volatile float A = u.f;
//    
//    volatile float B = A;
//    volatile int C = (int)B;
//    volatile float D = (float)C;
//    
//    return 0;
//}