# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -Wl,-T../potato.ld -Wl,--Map,dhry_1.map

OBJECTS := dhry_1.o start.o
LINKER_SCRIPT := ../potato.ld

all: dhry_1.elf dhry_1.bin dhry_1.coe dhry_1.s

dhry_1.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o dhry_1.elf $(TARGET_LDFLAGS) -O3 $(OBJECTS)
	$(TARGET_SIZE) dhry_1.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) dhry_1.elf dhry_1.bin dhry_1.coe dhry_1.map dhry_1.s
# Compile source files into human-readable assembly files
dhry_1.s: dhry_1.c  *.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -S $@ $(TARGET_CFLAGS) -O3 $<

# Object file rules:

dhry_1.o: dhry_1.c *.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) -O3 $<

start.o: ../start.S ../../platform.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) -O3 $<

