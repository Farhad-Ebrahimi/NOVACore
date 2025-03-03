# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -Wl,-Tssbl.ld -Wl,--Map,ssbl.map

OBJECTS := ssbl.o start.o

all: ssbl.elf ssbl.bin ssbl.coe

ssbl.elf: $(OBJECTS)
	$(TARGET_LD) -o ssbl.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) ssbl.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) ssbl.elf ssbl.bin ssbl.coe ssbl.map

# Object file rules:

ssbl.o: ssbl.c ../../potato.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S
	$(TARGET_CC) -DCOPY_DATA_TO_RAM -c -o $@ $(TARGET_CFLAGS) $<

