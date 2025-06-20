#!/bin/sh

# ============================================================================
# build-linux.sh — Build script for LoRanOS (floppy + ISO)
# ============================================================================

# --- Configuration ---
OS_NAME="LoRanOS"
IMAGE_DIR="disk_images"
BOOT_DIR="boot"
SRC_DIR="src"
FLOPPY_IMG="disk_images/LoRanOS.flp"
ISO_IMG="disk_images/LoRanOS.iso"
BOOTLOADER_SRC="boot/bootload.asm"
BOOTLOADER_BIN="boot/bootload.bin"
KERNEL_SRC="src/kernel.asm"
KERNEL_BIN="src/kernel.bin"

# --- Create directories if they don't exist ---
mkdir -p $IMAGE_DIR

# --- Create floppy image if not exists ---
if [ ! -e "$FLOPPY_IMG" ]; then
    echo ">>> Creating new floppy image: $FLOPPY_IMG"
    mkdosfs -C $FLOPPY_IMG 1440 || exit 1
fi

# --- Assemble bootloader ---
echo ">>> Assembling bootloader..."
nasm -f bin -o $BOOTLOADER_BIN $BOOTLOADER_SRC || exit 1

# --- Assemble kernel ---
echo ">>> Assembling LoRanOS kernel..."
nasm -f bin -o $KERNEL_BIN $KERNEL_SRC || exit 1

# --- Write bootloader to floppy image (first 512 bytes) ---
echo ">>> Adding bootloader to floppy image..."
dd status=noxfer conv=notrunc if=$BOOTLOADER_BIN of=$FLOPPY_IMG || exit 1

# --- Copy kernel file to floppy image root directory ---
echo ">>> Copying LoRanOS kernel & programs to floppy image..."
mcopy -o -i $FLOPPY_IMG $KERNEL_BIN ::/ || exit 1


# --- Create ISO image from floppy ---
echo ">>> Creating ISO image..."
rm -f $ISO_IMG
mkisofs -quiet -V "LoRanOS" -input-charset iso8859-1 -o $ISO_IMG -b $(basename $FLOPPY_IMG) $IMAGE_DIR/ || exit 1

echo ">>> ✅ Build complete! ISO ready at: $ISO_IMG"

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
