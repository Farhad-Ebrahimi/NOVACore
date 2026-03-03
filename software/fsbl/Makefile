# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>

.PHONY: all clean
include ../common.mk

LINKER_SCRIPT = fsbl.ld

TARGET_LDFLAGS += -Wl,-T$(LINKER_SCRIPT) -Wl,--Map=fsbl.map

OBJECTS := fsbl.o start.o

all: fsbl.elf fsbl.bin fsbl.coe fsbl.s

fsbl.elf: $(OBJECTS) $(LINKER_SCRIPT)
	$(TARGET_LD) -o fsbl.elf $(TARGET_LDFLAGS) $(OBJECTS)
	$(TARGET_SIZE) fsbl.elf

clean:
	-$(RM) $(OBJECTS)
	-$(RM) fsbl.elf fsbl.bin fsbl.coe fsbl.map

# human readable asembly .s file for debugging and inspection purposes:
fsbl.s: fsbl.c ../../potato.h $(LINKER_SCRIPT)	
	$(TARGET_CC) -S $(TARGET_CFLAGS) $< -o $@

# Object file rules:

fsbl.o: fsbl.c ../../potato.h
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<

start.o: ../start.S
	$(TARGET_CC) -DCOPY_DATA_TO_RAM -c -o $@ $(TARGET_CFLAGS) $<

