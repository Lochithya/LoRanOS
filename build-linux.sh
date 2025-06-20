#!/bin/sh

# ============================================================================
# build-linux.sh — Build script for LoRanOS (floppy + ISO)
# ============================================================================

# --- Configuration ---
OS_NAME="LoRanOS"

# --- Create directories if they don't exist ---
mkdir -p disk_images

# --- Create floppy image if not exists ---
if [ ! -e "disk_images/LoRanOS.flp" ]; then
    echo ">>> Creating new floppy image: disk_images/LoRanOS.flp"
    mkdosfs -C disk_images/LoRanOS.flp 1440 || exit 1
fi

# --- Assemble bootloader ---
echo ">>> Assembling bootloader..."
nasm -f bin -o boot/bootload.bin boot/bootload.asm || exit 1

# --- Assemble kernel ---
echo ">>> Assembling LoRanOS kernel..."
nasm -f bin -o src/kernel.bin src/kernel.asm || exit 1

# --- Write bootloader to floppy image (first 512 bytes) ---
echo ">>> Adding bootloader to floppy image..."
dd status=noxfer conv=notrunc if=boot/bootload.bin of=disk_images/LoRanOS.flp || exit 1

# --- Copy kernel file to floppy image root directory ---
echo ">>> Copying LoRanOS kernel & programs to floppy image..."
mcopy -o -i disk_images/LoRanOS.flp src/kernel.bin ::/ || exit 1


# --- Create ISO image from floppy ---
echo ">>> Creating ISO image..."
rm -f disk_images/LoRanOS.iso
mkisofs -quiet -V "LoRanOS" -input-charset iso8859-1 -o disk_images/LoRanOS.iso -b $(basename disk_images/LoRanOS.flp) disk_images/ || exit 1

echo ">>> ✅ Build complete! ISO ready at: disk_images/LoRanOS.iso"

#!/bin/sh

# ============================================================================
# test-link.sh — Boot LoRanOS from floppy image using QEMU
# ============================================================================

echo ">>> Booting LoRanOS floppy image with QEMU..."

qemu-system-i386 \
    -drive format=raw,file=disk_images/LoRanOS.flp,index=0,if=floppy \
    -m 32M \
    -boot a \
    -cpu 486 \
    -no-reboot
