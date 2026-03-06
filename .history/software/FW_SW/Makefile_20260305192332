# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include common.mk

TARGET_LDFLAGS += -Wl,-T../potato.ld -Wl,--Map,fadd_s.map

OBJECTS := fadd_s.o start.o
LINKER_SCRIPT := ../potato.ld

all: fadd_s.elf fadd_s.bin fadd_s.coe fadd_s.s

fadd_s.s: fadd_s.c
	$(TARGET_CC) $(TARGET_CFLAGS) -O3 -S -o $@ $<

fadd_s.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o fadd_s.elf $(TARGET_LDFLAGS) -O3 $(OBJECTS)
	$(TARGET_SIZE) fadd_s.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) fadd_s.elf fadd_s.bin fadd_s.coe fadd_s.map fadd_s.s

# Object file rules:

fadd_s.o: fadd_s.c ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) -O3 $<

start.o: ../start.S ../../platform.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) -O3 $<

