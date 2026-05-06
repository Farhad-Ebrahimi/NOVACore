# ------------------------------------------------------------
# The Potato Processor - Applications (FPU Enabled)
# ------------------------------------------------------------

TARGET_PREFIX ?= riscv64-unknown-elf

TARGET_CC       := $(TARGET_PREFIX)-gcc
TARGET_LD       := $(TARGET_PREFIX)-gcc
TARGET_SIZE     := $(TARGET_PREFIX)-size
TARGET_OBJCOPY  := $(TARGET_PREFIX)-objcopy
HEXDUMP ?= hexdump

# ------------------------------------------------------------
# Architecture (match multilib exactly!)
# ------------------------------------------------------------

ARCH := rv32imafc
ABI  := ilp32f

TARGET_CFLAGS += \
	-march=$(ARCH) \
	-mabi=$(ABI) \
	-mno-div \
	-Wall -Os \
	-ffreestanding \
	-fno-builtin \
	-fomit-frame-pointer \
	-ffunction-sections \
	-fdata-sections \
	-std=gnu99 \
	-I../.. \
	-I../../libsoc \
	-Werror=implicit-function-declaration

TARGET_LDFLAGS += \
	-march=$(ARCH) \
	-mabi=$(ABI) \
	-mno-div \
	-nostartfiles \
	-L../libsoc \
	--specs=nosys.specs \
	-Wl,--no-relax \
	-Wl,--gc-sections

# ------------------------------------------------------------
# ELF → BIN
# ------------------------------------------------------------

%.bin: %.elf
	$(TARGET_OBJCOPY) -j .text -j .data -j .rodata -O binary $< $@

# ------------------------------------------------------------
# BIN → COE (Vivado)
# ------------------------------------------------------------

%.coe: %.bin
	echo "memory_initialization_radix=16;" > $@
	echo "memory_initialization_vector=" >> $@
	$(HEXDUMP) -v -e '1/4 "%08x,\n"' $< | sed '$$s/,$$/;/' >> $@