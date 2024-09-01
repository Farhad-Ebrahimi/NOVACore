.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -T ../potato.ld -Wl,--Map,main.map -lm

OBJECTS := main.o start.o func.o 
LINKER_SCRIPT := ../potato.ld

# Include .s files in the all target
all: main.elf main.bin main.coe main.s func.s

# The order of prerequisites in main.elf rule was adjusted to match the actual order of linking.
main.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o $@ $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) $@

clean:
	-$(RM) $(OBJECTS)
	-$(RM) main.elf main.bin main.coe main.map main.s func.s

# The $@ should be after the -S option in main.s and func.s rules to match the pattern.
main.s: main.c func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -S $(TARGET_CFLAGS) $< -o $@

 func.s: func.c func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -S $(TARGET_CFLAGS) $< -o $@

 Object file rules:

main.o: main.c func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@

 func.o: func.c func.h ../../platform.h ../../potato.h ../../libsoc/timer.h ../../libsoc/uart.h ../../libsoc/icerror.h ../../libsoc/gpio.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@

start.o: ../start.S ../../platform.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@
