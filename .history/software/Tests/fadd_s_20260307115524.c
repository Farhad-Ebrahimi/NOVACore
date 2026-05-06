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



void fpu_logic_test() {
    // Input 4 integers
    volatile int int_a = 100;
    volatile int int_b = 50;
    volatile int int_c = 20;
    volatile int int_d = 20;
    
    // 1. Convert them into floats (Triggers FCVT.S.W) 
    float a = (float)int_a;
    float b = (float)int_b;
    float c = (float)int_c;
    float d = (float)int_d;
    
    float res = 0.0f;

    // 2. Logic: if a > b perform addition (Triggers FLT/FLE + FADD) [cite: 125, 387]
    if (a > b) {
        res = a + b;
    }

    // 3. Logic: if c == d perform division (Triggers FEQ + FDIV) [cite: 125, 397]
    if (c == d) {
        res = c / d;
    }

    // 4. Logic: if a < c perform mul (Triggers FLT + FMUL) [cite: 125, 393]
    if (a < c) {
        res = a * c;
    }

    // 5. Logic: if b <= d perform subtraction (Triggers FLE + FSUB) [cite: 125, 390]
    if (b <= d) {
        res = b - d;
    }

    // 6. Store the float value into memory 
    // We use a union or pointer cast to ensure an integer 'sw' is used 
    volatile uint32_t* mem_store = (uint32_t*)0x80000000;
    *mem_store = *(uint32_t*)&res;

    // 7. Load 'a' into another register (effectively a move or reload)
    // This will result in an 'lw' followed by 'fmv.w.x' if optimized 
    volatile float final_load;
    final_load = a;
}

int main() {
    fpu_logic_test();
    return 0;
}