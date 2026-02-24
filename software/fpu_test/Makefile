# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

LINKER_SCRIPT := ../potato.ld
TARGET_LDFLAGS += -Wl,-T$(LINKER_SCRIPT) -Wl,--Map,fputest.map

OBJECTS := fputest.o func.o start.o

all: fputest.elf fputest.bin fputest.s func.s

fputest.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o fputest.elf $(TARGET_LDFLAGS) $(OBJECTS) -lm
	$(TARGET_SIZE) fputest.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) fputest.elf fputest.bin fputest.coe fputest.map fputest.s func.s

# Compile source files into human-readable assembly files

fputest.s: fputest.c  func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -S $@ $(TARGET_CFLAGS) $<
func.s: func.c  func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -S $@ $(TARGET_CFLAGS) $<


# Object file rules:

fputest.o: fputest.c func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

func.o: func.c func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S ../../platform.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

