.PHONY: all clean
include ../../common.mk

LINKER_SCRIPT := ../../potato.ld
TARGET_LDFLAGS += -T $(LINKER_SCRIPT) -Wl,--Map,basic_arith.map -lm

OBJECTS := basic_arith.o start.o 

# Include .s files in the all target
all: basic_arith.elf basic_arith.bin basic_arith.coe basic_arith.s

# The order of prerequisites in basic_arith.elf rule was adjusted to match the actual order of linking.
basic_arith.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o $@ $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) $@

clean:
	-$(RM) $(OBJECTS)
	-$(RM) basic_arith.elf basic_arith.bin basic_arith.coe basic_arith.map basic_arith.s

# The $@ should be after the -S option in basic_arith.s rules to match the pattern.
basic_arith.s: basic_arith.c ../../../platform.h ../../../potato.h ../../../libsoc/timer.h ../../../libsoc/uart.h ../../../libsoc/icerror.h ../../../libsoc/gpio.h
	$(TARGET_CC) -S $(TARGET_CFLAGS) $< -o $@

 Object file rules:

basic_arith.o: basic_arith.c ../../../platform.h ../../../potato.h ../../../libsoc/timer.h ../../../libsoc/uart.h ../../../libsoc/icerror.h ../../../libsoc/gpio.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@

start.o: ../../start.S ../../../platform.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@
