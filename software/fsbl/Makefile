# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

TARGET_LDFLAGS += -Wl,-Tfsbl.ld -Wl,--Map,fsbl.map

OBJECTS := fsbl.o start.o

all: fsbl.elf fsbl.bin fsbl.coe

fsbl.elf: $(OBJECTS)
	$(TARGET_LD) -o fsbl.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) fsbl.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) fsbl.elf fsbl.bin fsbl.coe fsbl.map

# Object file rules:

fsbl.o: fsbl.c ../../potato.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S
	$(TARGET_CC) -DCOPY_DATA_TO_RAM -c -o $@ $(TARGET_CFLAGS) $<

