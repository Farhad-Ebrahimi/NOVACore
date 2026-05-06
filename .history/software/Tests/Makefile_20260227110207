# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -Wl,-T../potato.ld -Wl,--Map,fibonacci_sequence.map

OBJECTS := fibonacci_sequence.o start.o
LINKER_SCRIPT := ../potato.ld

all: fibonacci_sequence.elf fibonacci_sequence.bin fibonacci_sequence.coe

fibonacci_sequence.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o fibonacci_sequence.elf $(TARGET_LDFLAGS) -O3 $(OBJECTS)
	$(TARGET_SIZE) fibonacci_sequence.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) fibonacci_sequence.elf fibonacci_sequence.bin fibonacci_sequence.coe fibonacci_sequence.map

# Object file rules:

fibonacci_sequence.o: fibonacci_sequence.c ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) -O3 $<

start.o: ../start.S ../../platform.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) -O3 $<

