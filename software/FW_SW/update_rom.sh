#!/bin/bash

# Usage:
# ./update_rom.sh input.coe rom.vhd

COE_FILE="$1"
VHD_FILE="$2"

if [ -z "$COE_FILE" ] || [ -z "$VHD_FILE" ]; then
    echo "Usage: $0 input.coe rom.vhd"
    exit 1
fi

if [ ! -f "$COE_FILE" ]; then
    echo "Error: COE file not found."
    exit 1
fi

if [ ! -f "$VHD_FILE" ]; then
    echo "Error: VHD file not found."
    exit 1
fi

echo "Updating ROM from $COE_FILE into $VHD_FILE..."

# Extract hex lines (remove headers, commas, semicolons)
HEX_LINES=$(awk '
/memory_initialization_vector/ {start=1; next}
start {
    gsub(/[,;]/,"");
    if ($0 ~ /^[0-9a-fA-F]+$/) print
}
' "$COE_FILE")

# Build VHDL ROM content
INDEX=0
ROM_CONTENT="constant rom_memory : rom_type := (\n"

while read -r LINE; do
    ROM_CONTENT+="    $INDEX => x\"$LINE\",\n"
    INDEX=$((INDEX+1))
done <<< "$HEX_LINES"

ROM_CONTENT+="    others => x\"00000000\"\n);\n"

# Replace existing rom_memory block in VHD file
awk -v new_rom="$ROM_CONTENT" '
BEGIN {inside=0}
{
    if ($0 ~ /constant rom_memory/) {
        print new_rom
        inside=1
        next
    }
    if (inside && $0 ~ /\);/) {
        inside=0
        next
    }
    if (!inside) print
}
' "$VHD_FILE" > tmp_rom.vhd

mv tmp_rom.vhd "$VHD_FILE"

echo "ROM successfully updated!"