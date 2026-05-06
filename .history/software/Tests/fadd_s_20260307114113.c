#include <stdio.h>
#include <stdint.h>
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

//float test_fpu_logic_mul() {
//    volatile int a = 12;
//    volatile int b = 4;
//    float f1 = (float)a; // fcvt.s.w
//    float f2 = (float)b; // fcvt.s.w
//   float sum = f1 * f2; // fadd.s
//   return (int)sum;     // fcvt.w.s
//}


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



//float test_fpu_logic_add(int a, int b) {
//   
//    float f1 = (float)a; // fcvt.s.w
//    float f2 = (float)b; // fcvt.s.w
//   float sum = f1 + f2; // fadd.s
//   return sum;     // fcvt.w.s
//}
//
//
//float conv(int a){
//   return (float)a; }
//
//
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

///int test_fpu_logic_div(int a, int b) {
///   float f1 = (float)a; // fcvt.s.w
///   float f2 = (float)b; // fcvt.s.w
///  float sum = f1 / f2; // fdiv.s
///  return (int)sum;     // fcvt.w.s
///}
///
///
///int main(void) {
///
///   volatile int a = 2;
///   volatile int b = 3;
///   volatile int c = 20;
///   volatile int d = 4;
///  // volatile float b_f = (float)b;       ////3 is converted into float 
///  //volatile int result_add = test_fpu_logic_add_1();
///  volatile int result_mul = test_fpu_logic_mul();
///  ////volatile int result_sub = test_fpu_logic_sub();
///  //volatile int result_div_1 = test_fpu_logic_div(b, a);
///  //volatile int result_div_2 = test_fpu_logic_div(c, d);
///  //volatile int result_add = test_fpu_logic_add_1();
/////// volatile int result_add = test_fpu_logic_add();
///////volatile int result_sub = test_fpu_logic_sub();
///  // volatile float result_add_1 = test_fpu_logic_add(a, b);    ///--> 2 and 3 are converted into float and then added together to give 5.0f
///  // if (result_add_1 > b_f) {
///
///  //     volatile int c = 10;
///
///  //     volatile float f1 = conv(c); // fcvt.s.w  /// 41200000 
///  //         volatile float f2 = f1 * result_add_1;
///  //     //printf("Result of multiplication: %f\n",f2);
///  //  }  //// 10 * 5.0 
///
///  // else 
///  // {
///
///  //      volatile int d = (int)result_add_1;
///  // 
///  // 
///  // }
///  //           
///
///
///
///
///
/////// while(1); 
/////// uart_tx_string(&uart0, "result: ");
/////// // convert integer part to string
/////// intToStr(ipart, buf, 0);
/////// uart_tx_string(&uart0, buf);
/////// uart_tx_string(&uart0, ".");
/////// intToStr(fpart, buf, 6); // 6 digits for fractional part
/////// uart_tx_string(&uart0, buf);
/////// uart_tx_string(&uart0, "\r\n");
///////
/////// // test_fpu_logic_mul();
///    return 0;
///}
///
///
///
///
///
///
/////nt main() {
/////
//////volatile int num = 10;
//////  volatile float fnum = conv(num); // fcvt.s.w
//////  volatile int a = (int)fnum; // fcvt.w.s
//////  while (1);
/////
/////  volatile int a = 12; 
/////  volatile int b = 4;
/////
/////  volatile float f1 = conv(a); 
/////  volatile float f2 = conv(b);
/////  volatile float sum = f1 + f2;
/////
/////  volatile int c = (int)sum;
///// 
/////
///// //volatile float f1 = (float)a; 
/////  while(1);
/////  return 0;
/////
/////
///
///
/////int main(){
/////    // Union allows reinterpreting the bits
/////    union { 
/////        volatile float f; 
/////        volatile int32_t i; 
/////    } u;
/////    
/////    // Set the bit pattern for 12.0f
/////    u.i = 0x41400000;
/////    
/////    // Read back as float - triggers fmv.w.x
/////    volatile float A = u.f;
/////    
/////    volatile float B = A;
/////    volatile int C = (int)B;
/////    volatile float D = (float)C;
/////    
/////    return 0;
/////}




// Union to facilitate integer-based loading of float bit-patterns
typedef union {
  volatile float f;
  volatile uint32_t i;
} conv_t;

void fpu_test_bench() {
    // 1. Integer Loads (using uint32_t to force lw)
    conv_t a, b, res;
    a.i = 0x40800000; // 4.0f
    b.i = 0x40000000; // 2.0f

    // 2. Arithmetic Ops (FADD, FSUB, FMUL, FDIV)
    // These trigger the 3-cycle pipeline in your hardware [cite: 350, 402, 479]
   volatile  float f_add = a.f + b.f;
   volatile  float f_sub = a.f - b.f;
   volatile  float f_mul = a.f * b.f;
   volatile  float f_div = a.f / b.f;

   
   volatile  int eq = (a.f == b.f);
   volatile  int lt = (a.f < b.f);
   volatile  int le = (a.f <= b.f);
 
   
   
   volatile  int int_val = 10;
   volatile  float f_from_int = (float)int_val; // fcvt.s.w
   volatile  int int_from_f = (int)f_mul;       // fcvt.w.s

    res.f = f_mul + f_from_int;
    
    // Volatile pointer to a memory-mapped address to prevent optimization
    volatile uint32_t* output_port = (uint32_t*)0x80000000;
    *output_port = res.i; 
}


int main() {
    fpu_test_bench();
    //while(1); // Loop indefinitely to allow inspection of results
    return 0;
}