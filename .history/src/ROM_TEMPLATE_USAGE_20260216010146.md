# FPU Test ROM Template - Usage Guide

## Overview
The `aee_rom.vhd` file now contains a template for testing the FPU with arbitrary floating-point values. The ROM is organized into three sections:

1. **Initialization Section** (entries 0-3): Initializes stack pointer and sets up data section pointer
2. **Test Code Section** (entries 4-16): Loads FP values and performs FPU operations
3. **Data Section** (entries 48-63): Pre-stored IEEE-754 floating-point test values

## ROM Structure

```
Entry 0-1:   Stack pointer initialization (sp = 0x7ffc)
Entry 2-3:   Load data section address into x15
Entry 4-7:   Load FP values from data section using FLW
Entry 8-11:  FPU arithmetic operations (fadd, fsub, fmul, fdiv)
Entry 12-15: Store results to memory using FSW
Entry 16:    Infinite loop (halt)
Entry 48-63: Data section with IEEE-754 values
```

## How to Modify Test Values

### Quick Test Value Changes
To test different values, simply modify the data section (entries 48-63):

```vhdl
48 => x"40490fdb",  -- [Data 0] Pi = 3.14159265
49 => x"402df854",  -- [Data 1] e = 2.71828183
50 => x"40000000",  -- [Data 2] 2.0
51 => x"40400000",  -- [Data 3] 3.0
-- ... modify these hex values ...
```

### Current Test Values Included
| Entry | Hex Value    | Decimal Value | Description |
|-------|--------------|---------------|-------------|
| 48    | 0x40490fdb   | 3.14159265    | Pi          |
| 49    | 0x402df854   | 2.71828183    | e           |
| 50    | 0x40000000   | 2.0           | Two         |
| 51    | 0x40400000   | 3.0           | Three       |
| 52    | 0x3f800000   | 1.0           | One         |
| 53    | 0x41200000   | 10.0          | Ten         |
| 54    | 0x42c80000   | 100.0         | Hundred     |
| 55    | 0x3f000000   | 0.5           | Half        |
| 56    | 0x40800000   | 4.0           | Four        |
| 57    | 0x40a00000   | 5.0           | Five        |
| 58    | 0x41f00000   | 30.0          | Thirty      |
| 59    | 0xbf800000   | -1.0          | Neg One     |
| 60    | 0xc0000000   | -2.0          | Neg Two     |
| 61    | 0x00000000   | 0.0           | Zero        |
| 62    | 0x7f800000   | +Infinity     | +Inf        |
| 63    | 0x7fc00000   | NaN           | Not-a-Number|

## Converting Decimal to IEEE-754 Hex

### Method 1: Online Converter
Use: https://www.h-schmidt.net/FloatConverter/IEEE754.html
- Enter your decimal value
- Get the hex representation
- Add to ROM with `x"` prefix

### Method 2: Python Script
```python
import struct

def float_to_hex(f):
    return hex(struct.unpack('>I', struct.pack('>f', f))[0])

# Example:
print(float_to_hex(3.14159))  # Output: 0x40490fda
print(float_to_hex(2.71828))  # Output: 0x402df854
```

### Method 3: Manual Calculation
IEEE-754 Single Precision (32-bit) format:
```
[Sign: 1 bit][Exponent: 8 bits][Mantissa: 23 bits]
```

**Example: 3.14159**
1. Binary: 11.001001000011111...
2. Normalized: 1.1001001000011111... × 2^1
3. Exponent: 1 + 127 (bias) = 128 = 0b10000000
4. Mantissa: 10010010000111110101011 (23 bits after binary point)
5. Sign: 0 (positive)
6. Result: 0 10000000 10010010000111110101011
7. Hex: 0x40490fdb

## Modifying Test Operations

To test different FP operations, modify entries 8-15:

### Example: Testing Square Root Operation
```vhdl
8 => x"58208253",   -- fsqrt.s f4, f1   (f4 = sqrt(f1))
```

### Example: Testing FP Comparison
```vhdl
8 => x"a02081d3",   -- feq.s x3, f1, f2  (x3 = 1 if f1==f2, else 0)
9 => x"a02091d3",   -- flt.s x3, f1, f2  (x3 = 1 if f1<f2, else 0)
10 => x"a02089d3",  -- fle.s x3, f1, f2  (x3 = 1 if f1<=f2, else 0)
```

## Loading Different Values into Different Registers

Modify entries 4-7 to load from different data section offsets:

```vhdl
4 => x"0007a087",   -- flw f1, 0(x15)    (f1 = Data[0] = Pi)
5 => x"0047a107",   -- flw f2, 4(x15)    (f2 = Data[1] = e)
6 => x"0087a187",   -- flw f3, 8(x15)    (f3 = Data[2] = 2.0)
7 => x"00c7a207",   -- flw f4, 12(x15)   (f4 = Data[3] = 3.0)
8 => x"0107a287",   -- flw f5, 16(x15)   (f5 = Data[4] = 1.0)
9 => x"0147a307",   -- flw f6, 20(x15)   (f6 = Data[5] = 10.0)
```

**Offset Calculation:**
- Data[0] at entry 48: offset = 0
- Data[1] at entry 49: offset = 4
- Data[2] at entry 50: offset = 8
- Data[n]: offset = n * 4

## Verifying Results

Results are stored back to main memory starting at `sp - 32`:

```
Memory Address  | Content        | Description
----------------|----------------|------------------
0x7ffc - 32     | f3 value       | Addition result
0x7ffc - 28     | f4 value       | Subtraction result
0x7ffc - 24     | f5 value       | Multiplication result
0x7ffc - 20     | f6 value       | Division result
```

In simulation, monitor these addresses to verify FPU operation correctness.

## Common Test Scenarios

### Test 1: Basic Arithmetic (Default)
- f1 = Pi, f2 = e
- Operations: +, -, *, /

### Test 2: Edge Cases
Replace data section with:
```vhdl
48 => x"7f800000",  -- +Infinity
49 => x"ff800000",  -- -Infinity
50 => x"00000000",  -- +Zero
51 => x"80000000",  -- -Zero
52 => x"7fc00000",  -- NaN
```

### Test 3: Precision Test
```vhdl
48 => x"3f800000",  -- 1.0
49 => x"34000000",  -- Very small (5.96e-8)
50 => x"7f7fffff",  -- Max normal (3.4e38)
51 => x"00800000",  -- Min normal (1.17e-38)
```

## Important Notes

1. **Stack Pointer**: Always initialized to 0x7ffc (top of 512KB RAM minus 4)
2. **Data Section**: Fixed at entries 48-63 (16 values max currently)
3. **ROM Address**: Base is 0xFFFF8000, data section starts at 0xFFFF80C0
4. **Test Expansion**: You can expand the data section by adjusting entry ranges and load offsets

## Quick Reference: FPU Instruction Encoding

| Instruction | Opcode  | Format | Example           |
|-------------|---------|--------|-------------------|
| FLW         | 0x07    | I-type | flw f1, 0(x15)    |
| FSW         | 0x27    | S-type | fsw f1, 0(x15)    |
| FADD.S      | 0x53    | R-type | fadd.s f3, f1, f2 |
| FSUB.S      | 0x53    | R-type | fsub.s f3, f1, f2 |
| FMUL.S      | 0x53    | R-type | fmul.s f3, f1, f2 |
| FDIV.S      | 0x53    | R-type | fdiv.s f3, f1, f2 |

For detailed encoding, refer to RISC-V F extension specification.
