# The NOVACore

![Processor architecture overview diagramme](docs/nova.png)

The **NOVACore** is a 7-stage in-order RISC-V processor implemented in VHDL, designed for both **FPGA prototyping and ASIC deployment**. It supports the 32-bit **RV32IMF-Zicsr** ISA, including integer, multiplication/division, and IEEE 754 single-precision floating-point operations.

The processor has been successfully implemented on FPGA platforms as well as realized as an **ASIC in IHP 130 nm technology**, demonstrating its readiness for silicon deployment. In addition, NOVACore has been **validated in an industrial environment**, including testing within a **commercial CT scanning system from a leading medical engineering manufacturer**, confirming its robustness and reliability in real-world applications.

---

## Features

* 32-bit **RV32IMF-Zicsr ISA** supporting:
  - Base integer arithmetic instructions (RV32I)
  - Multiplication and division (RV32M) with optimized SRT divider
  - IEEE754 single-precision floating-point (RV32F)
  - Control and status register manipulation (Zicsr v2.0)

* Partial support for **RISC-V Privileged Architecture v1.10 (Machine Mode)**
* **7-stage pipeline**, including 3-stage ternary-encoded execution (IE1, IE2, IE3)
* **3-stage pipelined FPU**
* **1-bit dynamic branch prediction unit**
* Up to **8 maskable external interrupts**
* Optional **instruction cache**
* **Wishbone B4 bus interface**

---

## Implementation & Validation

NOVACore has been tested and validated across multiple platforms:

- **FPGA**
  - Xilinx Zynq-7000 (XC7Z020-1CLG400C)
  - Ultra96-V2 (Zynq UltraScale+ MPSoC)
  - Verified with Xilinx Vivado (up to version 2023.1)

- **ASIC**
  - Implemented using **IHP 130 nm technology**
  - Demonstrates functional correctness and timing closure in silicon

- **Industrial Validation**
  - Tested in a **commercial CT scan device**
  - Proven reliability in real-world, safety-critical environments

---

## Peripherals

The project includes a variety of Wishbone-compatible peripherals for use in system-on-chip designs based on the NOVACore.
The main peripherals are:

* Timer - a 32-bit timer with compare interrupt
* GPIO - a configurable-width generic GPIO module
* Memory - a block RAM module
* UART - a UART module with hardware FIFOs, configurable baud rate, and RX/TX interrupts

## Quick Start/Instantiating

Add the source files from the `src/` folder to your project to instantiate the processor. Use the `pp_novacore`
entity to instantiate a processor with a Wishbone interface. Some generics are provided to configure the processor core.

An example System-on-Chip for the Arty development board can be found in the `example/` directory of the source repository.

## Compiler Toolchain

To program the processor, you need an appropriate compiler toolchain. To compile a working toolchain, go to the
[RISCV GNU toolchain repository](https://github.com/riscv/riscv-gnu-toolchain) and clone the project. Compile and install
the toolchain using the following commands (note that `make` will both build and install the toolchain, ensure that the
the destination directory is writeable by your user):

    ./configure --prefix=/opt/riscv-toolchain --with-abi=ilp32 --with-arch=rv32imf
    make

## Contributors & Acknowledgments

* **Farhad Ebrahimiazandaryani** – Lead Developer; NOVACore and SoC Architect; FPGA Prototyping  

**Co-developers:**
* **Michael Kupfer** – Implementation of the open-source ASIC design flow  
* **Aiswarya Mukherjee** – IEEE 754 single-precision "RV32F" ISA extension  
* **Oliver Schnell** – Optimized SRT divider for "RV32M" division support  
 

## Citation  

If you are using **NOVACore** in your scientific or research activities, please cite it properly: 

* F. EbrahimiAzandaryani and D. Fey, "CSD-Driven Speedup in RISC-V Processors," Design and Architectures for Signal and Image Processing (DASIP)|HiPEAC, 2025. 

* F. EbrahimiAzandaryani and D. Fey, "Extern: Boosting RISC-V Core Performance using Ternary Encoding," Microprocessors and Microsystems, vol. 107, 2024. 

* A. Abdelhafez, F. EbrahimiAzandaryani, M. Bianconi and D. Fey, "FPGA Implementation of a Real-Time Application Based on RISC-V Cores," 2025 IEEE 22nd International Multi-Conference on Systems, Signals & Devices (SSD), Monastir, Tunisia, 2025, pp. 1174-1179, doi: 10.1109/SSD64182.2025.10989839. 

* F. Ebrahimiazandaryani, et al., "Silicon-Based Evaluation of CSD Arithmetic in a RISC-V Processor Using Open-Source ASIC Flow," IEEE ISCAS, 2026. 

We appreciate your acknowledgment and contributions!


## Reference & License

NOVACore originated from an open-source 5-stage RISC-V processor: (https://opencores.org/projects/potato).