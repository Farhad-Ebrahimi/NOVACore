/*
 ****************************************************************************
 *
 *                   "DHRYSTONE" Benchmark Program
 *                   -----------------------------
 *
 *  Version:    C, Version 2.1
 *
 *  File:       dhry_1.c (part 2 of 3)
 *
 *  Date:       May 25, 1988
 *
 *  Author:     Reinhold P. Weicker
 *
 ****************************************************************************
 */
#include <string.h>
#include "dhry.h"

#ifndef DHRY_ITERS
#define DHRY_ITERS 1000
#endif

/*RISC_VT_specific*/
#include "platform.h"
#include "potato.h"

#include "gpio.h"
#include "icerror.h"
#include "timer.h"
#include "uart.h"

/* Global Variables: */

Rec_Pointer Ptr_Glob,
    Next_Ptr_Glob;
int Int_Glob;
Boolean Bool_Glob;
char Ch_1_Glob,
    Ch_2_Glob;
int Arr_1_Glob[50];
int Arr_2_Glob[50][50];

// extern char *malloc();
Enumeration Func_1();
/* forward declaration necessary since Enumeration may not simply be int */

#ifndef REG
Boolean Reg = false;
#define REG
/* REG becomes defined as empty */
/* i.e. no register variables   */
#else
Boolean Reg = true;
#endif

#ifndef REG
#define REG
/* REG becomes defined as empty */
/* i.e. no register variables   */
#endif

extern int Int_Glob;
extern char Ch_1_Glob;
/*RISC_VT_specific*/
static struct gpio gpio0;
static struct uart uart0;
static struct timer timer0;
static struct timer timer1;
static struct icerror icerror0;

static uint8_t led_status = 0x01;
static volatile unsigned int Dhrystones_Per_Second = 0;
static volatile bool reset_counter = false;

// Converts a/an char/integer to a string:
void char2string(char c, char *s);
__attribute__((optimize("O1"))) static void int2string(int i, char *s);
// Converts an unsigned 32 bit integer to a hexadecimal string:
static void int2hex32(uint32_t i, char *s);

void print_result();
int count = 0;
void exception_handler(uint32_t mcause, uint32_t mepc, uint32_t sp)
{
  if ((mcause & (1 << POTATO_MCAUSE_INTERRUPT_BIT)) && (mcause & (1 << POTATO_MCAUSE_IRQ_BIT)))
  {
    uint8_t irq = mcause & 0x0f;

    if (irq == PLATFORM_IRQ_TIMER0)
    {
      // Print the number of hashes since last interrupt:
      char hps_dec[11];
      Dhrystones_Per_Second = Dhrystones_Per_Second * DHRY_ITERS;
      int2string(Dhrystones_Per_Second, hps_dec);
      uart_tx_string(&uart0, hps_dec);
      uart_tx_string(&uart0, " Itr/Sec\n\r");
      count++;
      if (count < 1)
      {
        reset_counter = false;
      }
      else
      {
        reset_counter = true;
        potato_disable_interrupts();
        potato_disable_irq(irq);
      }
      timer_clear(&timer0);
      print_result();
      Dhrystones_Per_Second = 0;
      while (1)
      {
        /* code */
      }
    }
  }
}

/*RISC_VT_specific*/

int main()
/*****/

/* main program, corresponds to procedures        */
/* Main and Proc_0 in the Ada version             */
{
  One_Fifty Int_1_Loc;
  REG One_Fifty Int_2_Loc;
  One_Fifty Int_3_Loc;
  REG char Ch_Index;
  Enumeration Enum_Loc;
  Str_30 Str_1_Loc;
  Str_30 Str_2_Loc;
  REG int Run_Index;
  REG int Number_Of_Runs;
  /* *****  NOVACore-SPECIFIC ***** */
  // Configure the UART:
  uart_initialize(&uart0, (volatile void *)PLATFORM_UART0_BASE);
  uart_set_divisor(&uart0, uart_baud2divisor(115200, PLATFORM_SYSCLK_FREQ));
  // uart_tx_string(&uart0, "--- Dhrystone Benchmark Application ---\r\n\n");

  // Set up timer0 at 1 Hz:
  timer_initialize(&timer0, (volatile void *)PLATFORM_TIMER0_BASE);
  timer_reset(&timer0);
  timer_set_compare(&timer0, PLATFORM_SYSCLK_FREQ);
  timer_start(&timer0);

  // Enable interrupts:
  potato_enable_irq(PLATFORM_IRQ_TIMER0);
  /* *****  NOVACore-SPECIFIC ***** */

  /* Initializations */

  // Next_Ptr_Glob = (Rec_Pointer)malloc(sizeof(Rec_Type));
  // Ptr_Glob = (Rec_Pointer)malloc(sizeof(Rec_Type));

  static Rec_Type Rec_Type_v0, Rec_Type_v1;
  Next_Ptr_Glob = &Rec_Type_v0;
  Ptr_Glob = &Rec_Type_v1;

  Ptr_Glob->Ptr_Comp = Next_Ptr_Glob;
  Ptr_Glob->Discr = Ident_1;
  Ptr_Glob->variant.var_1.Enum_Comp = Ident_3;
  Ptr_Glob->variant.var_1.Int_Comp = 40;
  strcpy(Ptr_Glob->variant.var_1.Str_Comp,
         "DHRYSTONE PROGRAM, SOME STRING");
  strcpy(Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

  Arr_2_Glob[8][7] = 10;
  /* Was missing in published program. Without this statement,    */
  /* Arr_2_Glob [8][7] would have an undefined value.             */
  /* Warning: With 16-Bit processors and Number_Of_Runs > 32000,  */
  /* overflow may occur for this array element.                   */

  uart_tx_string(&uart0, "\n");
  uart_tx_string(&uart0, "+--------------------------------------------------------+\r\n");
  uart_tx_string(&uart0, "|              'DHRYSTONE' Benchmark Program             |\r\n");
  uart_tx_string(&uart0, "|                 Version: C, Version 2.1                |\r\n");
  uart_tx_string(&uart0, "|               File: dhry_1.c (part 2 of 3)             |\r\n");
  uart_tx_string(&uart0, "|                   Date: May 25, 1988                   |\r\n");
  uart_tx_string(&uart0, "|               Author: Reinhold P. Weicker              |\r\n");
  uart_tx_string(&uart0, "|      https://github.com/sifive/benchmark-dhrystone     |\r\n");
  uart_tx_string(&uart0, "|                   -----------------------              |\r\n");
  uart_tx_string(&uart0, "|                                                        |\r\n");
  uart_tx_string(&uart0, "|    NOVACore: 7-Stage CSD RISC-V Core(RV32IMF_Zicsr)    |\r\n");
  uart_tx_string(&uart0, "|          (c) Farhad Ebrahimiazandaryani 03/23          |\r\n");
  uart_tx_string(&uart0, "|            Chair of Computer Science 3 | CS3           |\r\n");
  uart_tx_string(&uart0, "|                  FAU Erlangen-Nurnberg                 |\r\n");
  uart_tx_string(&uart0, "|                                                        |\r\n");
  uart_tx_string(&uart0, "|                   -----------------------              |\r\n");
  uart_tx_string(&uart0, "|                          GitHub:                       |\r\n");
  uart_tx_string(&uart0, "|       https://github.com/Farhad-Ebrahimi/NOVACore      |\r\n");
  uart_tx_string(&uart0, "|                                                        |\r\n");
  uart_tx_string(&uart0, "+--------------------------------------------------------+\r\n\r\n");

  if (Reg)
  {
    uart_tx_string(&uart0, "Program compiled with 'register' attribute\r\n\n");
  }
  else
  {
    uart_tx_string(&uart0, "Program compiled without 'register' attribute\r\n\n");
  }
#ifdef DHRY_ITERS
  Number_Of_Runs = DHRY_ITERS;
#endif
  char hps_dec[11];
  uart_tx_string(&uart0, "Execution starts ");

  int2string(Number_Of_Runs, hps_dec);
  uart_tx_string(&uart0, hps_dec);
  uart_tx_string(&uart0, " runs through Dhrystone\r\n\n");
  potato_enable_interrupts();
  while (!reset_counter)
  {
    // potato_enable_interrupts();
    for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index)
    {

      Proc_5();
      Proc_4();
      /* Ch_1_Glob == 'A', Ch_2_Glob == 'B', Bool_Glob == true */
      Int_1_Loc = 2;
      Int_2_Loc = 3;
      strcpy(Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
      Enum_Loc = Ident_2;
      Bool_Glob = !Func_2(Str_1_Loc, Str_2_Loc);
      /* Bool_Glob == 1 */
      while (Int_1_Loc < Int_2_Loc) /* loop body executed once */
      {
        Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
        /* Int_3_Loc == 7 */
        Proc_7(Int_1_Loc, Int_2_Loc, &Int_3_Loc);
        /* Int_3_Loc == 7 */
        Int_1_Loc += 1;
      } /* while */
      /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
      Proc_8(Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
      /* Int_Glob == 5 */
      Proc_1(Ptr_Glob);
      for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index)
      /* loop body executed twice */
      {
        if (Enum_Loc == Func_1(Ch_Index, 'C'))
        /* then, not executed */
        {
          Proc_6(Ident_1, &Enum_Loc);
          strcpy(Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
          Int_2_Loc = Run_Index;
          Int_Glob = Run_Index;
        }
      }
      /* Int_1_Loc == 3, Int_2_Loc == 3, Int_3_Loc == 7 */
      Int_2_Loc = Int_2_Loc * Int_1_Loc;
      Int_1_Loc = Int_2_Loc / Int_3_Loc;
      Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
      /* Int_1_Loc == 1, Int_2_Loc == 13, Int_3_Loc == 7 */
      Proc_2(&Int_1_Loc);
      /* Int_1_Loc == 5 */
    } /* loop "for Run_Index" */
    ++Dhrystones_Per_Second;
  }

  return 0;
}

void print_result()
{
  char hps_dec[11];
  uart_tx_string(&uart0, "\r\n");
  uart_tx_string(&uart0, "Execution ends\r\n");
  uart_tx_string(&uart0, "Final values of the variables used in the benchmark:\r\n");
  uart_tx_string(&uart0, "\r\n");
  uart_tx_string(&uart0, "Int_Glob:            ");
  int2string(Int_Glob, hps_dec);
  uart_tx_string(&uart0, hps_dec);
  uart_tx_string(&uart0, "        should be:   ");
  int2string(5, hps_dec);
  uart_tx_string(&uart0, hps_dec);
  uart_tx_string(&uart0, "\r\n");
  uart_tx_string(&uart0, "Bool_Glob:           ");
  int2string(Bool_Glob, hps_dec);
  uart_tx_string(&uart0, hps_dec);
  uart_tx_string(&uart0, "        should be:   ");
  int2string(1, hps_dec);
  uart_tx_string(&uart0, hps_dec);
  uart_tx_string(&uart0, "\r\n");
  uart_tx_string(&uart0, "Ch_1_Glob:           ");
  char2string(Ch_1_Glob, hps_dec);
  uart_tx_string(&uart0, hps_dec);
  uart_tx_string(&uart0, "        should be:   A\r\n");
  uart_tx_string(&uart0, " . \r\n");
  uart_tx_string(&uart0, " . \r\n");
  uart_tx_string(&uart0, " . \r\n");
  //  printf("Ch_1_Glob:           %c\n", Ch_1_Glob);
  //  printf("        should be:   %c\n", 'A');
  //  printf("Ch_2_Glob:           %c\n", Ch_2_Glob);
  //  printf("        should be:   %c\n", 'B');
  //  printf("Arr_1_Glob[8]:       %d\n", Arr_1_Glob[8]);
  //  printf("        should be:   %d\n", 7);
  //  printf("Arr_2_Glob[8][7]:    %d\n", Arr_2_Glob[8][7]);
  //  printf("        should be:   Number_Of_Runs + 10\n");
  //  printf("Ptr_Glob->\n");
  //  printf("  Ptr_Comp:          %d\n", (int)Ptr_Glob->Ptr_Comp);
  //  printf("        should be:   (implementation-dependent)\n");
  //  printf("  Discr:             %d\n", Ptr_Glob->Discr);
  //  printf("        should be:   %d\n", 0);
  //  printf("  Enum_Comp:         %d\n", Ptr_Glob->variant.var_1.Enum_Comp);
  //  printf("        should be:   %d\n", 2);
  //  printf("  Int_Comp:          %d\n", Ptr_Glob->variant.var_1.Int_Comp);
  //  printf("        should be:   %d\n", 17);
  //  printf("  Str_Comp:          %s\n", Ptr_Glob->variant.var_1.Str_Comp);
  //  printf("        should be:   DHRYSTONE PROGRAM, SOME STRING\n");
  //  printf("Next_Ptr_Glob->\n");
  //  printf("  Ptr_Comp:          %d\n", (int)Next_Ptr_Glob->Ptr_Comp);
  //  printf("        should be:   (implementation-dependent), same as above\n");
  //  printf("  Discr:             %d\n", Next_Ptr_Glob->Discr);
  //  printf("        should be:   %d\n", 0);
  //  printf("  Enum_Comp:         %d\n", Next_Ptr_Glob->variant.var_1.Enum_Comp);
  //  printf("        should be:   %d\n", 1);
  //  printf("  Int_Comp:          %d\n", Next_Ptr_Glob->variant.var_1.Int_Comp);
  //  printf("        should be:   %d\n", 18);
  //  printf("  Str_Comp:          %s\n", Next_Ptr_Glob->variant.var_1.Str_Comp);
  //  printf("        should be:   DHRYSTONE PROGRAM, SOME STRING\n");
  //  printf("Int_1_Loc:           %d\n", Int_1_Loc);
  //  printf("        should be:   %d\n", 5);
  //  printf("Int_2_Loc:           %d\n", Int_2_Loc);
  //  printf("        should be:   %d\n", 13);
  //  printf("Int_3_Loc:           %d\n", Int_3_Loc);
  //  printf("        should be:   %d\n", 7);
  //  printf("Enum_Loc:            %d\n", Enum_Loc);
  //  printf("        should be:   %d\n", 1);
  //  printf("Str_1_Loc:           %s\n", Str_1_Loc);
  //  printf("        should be:   DHRYSTONE PROGRAM, 1'ST STRING\n");
  //  printf("Str_2_Loc:           %s\n", Str_2_Loc);
  //  printf("        should be:   DHRYSTONE PROGRAM, 2'ND STRING\n");
  //  printf("\n");
  //
  //  User_Time = End_Time - Begin_Time;
  //
  //  if (User_Time < Too_Small_Time)
  //  {
  //    printf("Measured time too small to obtain meaningful results\n");
  //    printf("Please increase number of runs\n");
  //    printf("\n");
  //  }
  //  else
  //  {
  // #ifdef TIME
  //    Microseconds = (float)User_Time * Mic_secs_Per_Second / (float)Number_Of_Runs;
  //    Dhrystones_Per_Second = (float)Number_Of_Runs / (float)User_Time;
  // #else
  //    Microseconds = (float)User_Time * Mic_secs_Per_Second / ((float)HZ * ((float)Number_Of_Runs));
  //    Dhrystones_Per_Second = ((float)HZ * (float)Number_Of_Runs) / (float)User_Time;
  // #endif
  //    printf("Microseconds for one run through Dhrystone: ");
  //    // printf ("%6.1f \n", Microseconds);
  //    printf("%d \n", (int)Microseconds);
  //    printf("Dhrystones per Second:                      ");
  //    // printf ("%6.1f \n", Dhrystones_Per_Second);
  //    printf("%d \n", (int)Dhrystones_Per_Second);
  //    printf("\n");
  //  }
};

Proc_1(Ptr_Val_Par)
    /******************/

    REG Rec_Pointer Ptr_Val_Par;
/* executed once */
{
  REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;
  /* == Ptr_Glob_Next */
  /* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    */
  /* corresponds to "rename" in Ada, "with" in Pascal           */

  structassign(*Ptr_Val_Par->Ptr_Comp, *Ptr_Glob);
  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3(&Next_Record->Ptr_Comp);
  /* Ptr_Val_Par->Ptr_Comp->Ptr_Comp
                      == Ptr_Glob->Ptr_Comp */
  if (Next_Record->Discr == Ident_1)
  /* then, executed */
  {
    Next_Record->variant.var_1.Int_Comp = 6;
    Proc_6(Ptr_Val_Par->variant.var_1.Enum_Comp,
           &Next_Record->variant.var_1.Enum_Comp);
    Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
    Proc_7(Next_Record->variant.var_1.Int_Comp, 10,
           &Next_Record->variant.var_1.Int_Comp);
  }
  else /* not executed */
    structassign(*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
} /* Proc_1 */

Proc_2(Int_Par_Ref)
    /******************/
    /* executed once */
    /* *Int_Par_Ref == 1, becomes 4 */

    One_Fifty *Int_Par_Ref;
{
  One_Fifty Int_Loc;
  Enumeration Enum_Loc;

  Int_Loc = *Int_Par_Ref + 10;
  do /* executed once */
    if (Ch_1_Glob == 'A')
    /* then, executed */
    {
      Int_Loc -= 1;
      *Int_Par_Ref = Int_Loc - Int_Glob;
      Enum_Loc = Ident_1;
    } /* if */
  while (Enum_Loc != Ident_1); /* true */
} /* Proc_2 */

Proc_3(Ptr_Ref_Par)
    /******************/
    /* executed once */
    /* Ptr_Ref_Par becomes Ptr_Glob */

    Rec_Pointer *Ptr_Ref_Par;

{
  if (Ptr_Glob != Null)
    /* then, executed */
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7(10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
} /* Proc_3 */

Proc_4() /* without parameters */
/*******/
/* executed once */
{
  Boolean Bool_Loc;

  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
} /* Proc_4 */

Proc_5() /* without parameters */
/*******/
/* executed once */
{
  Ch_1_Glob = 'A';
  Bool_Glob = false;
} /* Proc_5 */

/* Procedure for the assignment of structures,          */
/* if the C compiler doesn't support this feature       */
#ifdef NOSTRUCTASSIGN
memcpy(d, s, l) register char *d;
register char *s;
register int l;
{
  while (l--)
    *d++ = *s++;
}
#endif

Proc_6(Enum_Val_Par, Enum_Ref_Par)
    /*********************************/
    /* executed once */
    /* Enum_Val_Par == Ident_3, Enum_Ref_Par becomes Ident_2 */

    Enumeration Enum_Val_Par;
Enumeration *Enum_Ref_Par;
{
  *Enum_Ref_Par = Enum_Val_Par;
  if (!Func_3(Enum_Val_Par))
    /* then, not executed */
    *Enum_Ref_Par = Ident_4;
  switch (Enum_Val_Par)
  {
  case Ident_1:
    *Enum_Ref_Par = Ident_1;
    break;
  case Ident_2:
    if (Int_Glob > 100)
      /* then */
      *Enum_Ref_Par = Ident_1;
    else
      *Enum_Ref_Par = Ident_4;
    break;
  case Ident_3: /* executed */
    *Enum_Ref_Par = Ident_2;
    break;
  case Ident_4:
    break;
  case Ident_5:
    *Enum_Ref_Par = Ident_3;
    break;
  } /* switch */
} /* Proc_6 */

Proc_7(Int_1_Par_Val, Int_2_Par_Val, Int_Par_Ref)
    /**********************************************/
    /* executed three times                                      */
    /* first call:      Int_1_Par_Val == 2, Int_2_Par_Val == 3,  */
    /*                  Int_Par_Ref becomes 7                    */
    /* second call:     Int_1_Par_Val == 10, Int_2_Par_Val == 5, */
    /*                  Int_Par_Ref becomes 17                   */
    /* third call:      Int_1_Par_Val == 6, Int_2_Par_Val == 10, */
    /*                  Int_Par_Ref becomes 18                   */
    One_Fifty Int_1_Par_Val;
One_Fifty Int_2_Par_Val;
One_Fifty *Int_Par_Ref;
{
  One_Fifty Int_Loc;

  Int_Loc = Int_1_Par_Val + 2;
  *Int_Par_Ref = Int_2_Par_Val + Int_Loc;
} /* Proc_7 */

Proc_8(Arr_1_Par_Ref, Arr_2_Par_Ref, Int_1_Par_Val, Int_2_Par_Val)
    /*********************************************************************/
    /* executed once      */
    /* Int_Par_Val_1 == 3 */
    /* Int_Par_Val_2 == 7 */
    Arr_1_Dim Arr_1_Par_Ref;
Arr_2_Dim Arr_2_Par_Ref;
int Int_1_Par_Val;
int Int_2_Par_Val;
{
  REG One_Fifty Int_Index;
  REG One_Fifty Int_Loc;

  Int_Loc = Int_1_Par_Val + 5;
  Arr_1_Par_Ref[Int_Loc] = Int_2_Par_Val;
  Arr_1_Par_Ref[Int_Loc + 1] = Arr_1_Par_Ref[Int_Loc];
  Arr_1_Par_Ref[Int_Loc + 30] = Int_Loc;
  for (Int_Index = Int_Loc; Int_Index <= Int_Loc + 1; ++Int_Index)
    Arr_2_Par_Ref[Int_Loc][Int_Index] = Int_Loc;
  Arr_2_Par_Ref[Int_Loc][Int_Loc - 1] += 1;
  Arr_2_Par_Ref[Int_Loc + 20][Int_Loc] = Arr_1_Par_Ref[Int_Loc];
  Int_Glob = 5;
} /* Proc_8 */

Enumeration Func_1(Ch_1_Par_Val, Ch_2_Par_Val)
/*************************************************/
/* executed three times                                         */
/* first call:      Ch_1_Par_Val == 'H', Ch_2_Par_Val == 'R'    */
/* second call:     Ch_1_Par_Val == 'A', Ch_2_Par_Val == 'C'    */
/* third call:      Ch_1_Par_Val == 'B', Ch_2_Par_Val == 'C'    */

Capital_Letter Ch_1_Par_Val;
Capital_Letter Ch_2_Par_Val;
{
  Capital_Letter Ch_1_Loc;
  Capital_Letter Ch_2_Loc;

  Ch_1_Loc = Ch_1_Par_Val;
  Ch_2_Loc = Ch_1_Loc;
  if (Ch_2_Loc != Ch_2_Par_Val)
    /* then, executed */
    return (Ident_1);
  else /* not executed */
  {
    Ch_1_Glob = Ch_1_Loc;
    return (Ident_2);
  }
} /* Func_1 */

Boolean Func_2(Str_1_Par_Ref, Str_2_Par_Ref)
/*************************************************/
/* executed once */
/* Str_1_Par_Ref == "DHRYSTONE PROGRAM, 1'ST STRING" */
/* Str_2_Par_Ref == "DHRYSTONE PROGRAM, 2'ND STRING" */

Str_30 Str_1_Par_Ref;
Str_30 Str_2_Par_Ref;
{
  REG One_Thirty Int_Loc;
  Capital_Letter Ch_Loc;

  Int_Loc = 2;
  while (Int_Loc <= 2) /* loop body executed once */
    if (Func_1(Str_1_Par_Ref[Int_Loc],
               Str_2_Par_Ref[Int_Loc + 1]) == Ident_1)
    /* then, executed */
    {
      Ch_Loc = 'A';
      Int_Loc += 1;
    } /* if, while */
  if (Ch_Loc >= 'W' && Ch_Loc < 'Z')
    /* then, not executed */
    Int_Loc = 7;
  if (Ch_Loc == 'R')
    /* then, not executed */
    return (true);
  else /* executed */
  {
    if (strcmp(Str_1_Par_Ref, Str_2_Par_Ref) > 0)
    /* then, not executed */
    {
      Int_Loc += 7;
      Int_Glob = Int_Loc;
      return (true);
    }
    else /* executed */
      return (false);
  } /* if Ch_Loc */
} /* Func_2 */

Boolean Func_3(Enum_Par_Val)
/***************************/
/* executed once        */
/* Enum_Par_Val == Ident_3 */
Enumeration Enum_Par_Val;
{
  Enumeration Enum_Loc;

  Enum_Loc = Enum_Par_Val;
  if (Enum_Loc == Ident_3)
    /* then, executed */
    return (true);
  else /* not executed */
    return (false);
} /* Func_3 */

static void int2string(int n, char *s)
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
void char2string(char c, char *s)
{
  s[0] = c;
  s[1] = '\0';
}

static void int2hex32(uint32_t n, char *s)
{
  static const char *hex_digits = "0123456789abcdef";

  int index = 0;
  for (int i = 28; i >= 0; i -= 4)
    s[index++] = hex_digits[(n >> (32 - i)) & 0xf];
  s[index] = 0;
}
