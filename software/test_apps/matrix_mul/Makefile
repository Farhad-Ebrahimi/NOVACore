.PHONY: all clean
include ../../common.mk

LINKER_SCRIPT := ../../potato.ld
TARGET_LDFLAGS += -T $(LINKER_SCRIPT) -Wl,--Map,matmul.map

OBJECTS := matmul.o start.o func.o

# Include .s files in the all target
all: matmul.elf matmul.bin matmul.coe matmul.s

# The order of prerequisites in matmul.elf rule was adjusted to match the actual order of linking.
matmul.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o $@ $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) $@

clean:
	-$(RM) $(OBJECTS)
	-$(RM) matmul.elf matmul.bin matmul.coe matmul.map matmul.s

# The $@ should be after the -S option in matmul.s rules to match the pattern.
matmul.s: matmul.c func.h ../../../platform.h ../../../potato.h ../../../libsoc/timer.h ../../../libsoc/uart.h ../../../libsoc/icerror.h ../../../libsoc/gpio.h
	$(TARGET_CC) -S $(TARGET_CFLAGS) $< -o $@

 Object file rules:

matmul.o: matmul.c func.h ../../../platform.h ../../../potato.h ../../../libsoc/timer.h ../../../libsoc/uart.h ../../../libsoc/icerror.h ../../../libsoc/gpio.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@

func.o: func.c ../../../platform.h ../../../potato.h ../../../libsoc/timer.h ../../../libsoc/uart.h ../../../libsoc/icerror.h ../../../libsoc/gpio.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@	

start.o: ../../start.S ../../../platform.h
	$(TARGET_CC) -c $(TARGET_CFLAGS) $< -o $@
