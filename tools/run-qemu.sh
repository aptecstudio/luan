#!/bin/sh
# Boots the project-os desktop image in the QEMU emulator, with UEFI firmware (or BIOS).
#
# Usage: tools/run-qemu.sh [--reset] [--text] [--bios] [--with-disk=FILE]
#                          [--audio-file=FILE]
#   --reset            start again from a new disk, copied from the latest build (loses
#                      data)
#   --text             no graphical window: everything in the terminal (serial console)
#   --bios             start the same disk from a legacy BIOS (SeaBIOS) instead of UEFI
#   --with-disk=FILE   attach FILE (raw disk image) as a second disk, e.g. with another
#                      system, to see it in the boot menu (D-060)
#   --audio-file=FILE  add an HD Audio sound card whose output is recorded into FILE
#                      (WAV), to check the audio services (D-061)
#
# The emulator disk is a copy of the image in build/qemu/disk.img, with 16 GB of extra
# free space: on first boot systemd-repart creates the data partition there.
# To quit in --text mode: Ctrl-a then x.
# With --bios, GRUB and the password prompt are only on the screen, not in the terminal.
set -eu

cd "$(dirname "$0")/.."

reset=0
text_mode=0
bios=0
other_disk=""
audio_file=""
for arg in "$@"; do
    case "$arg" in
        --reset) reset=1 ;;
        --text) text_mode=1 ;;
        --bios) bios=1 ;;
        --with-disk=*) other_disk=${arg#--with-disk=} ;;
        --audio-file=*) audio_file=${arg#--audio-file=} ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
    esac
done

DEPLOY=build/tmp/deploy/images/project-os-amd64
IMAGE="$DEPLOY/project-os-image-base-project-os-amd64.rootfs.wic"
WORK=build/qemu
DISK="$WORK/disk.img"
VARS="$WORK/OVMF_VARS.fd"

if [ ! -f "$IMAGE" ]; then
    echo "Image not found: $IMAGE" >&2
    echo "Run tools/build.sh first" >&2
    exit 1
fi

# OVMF UEFI firmware: Debian/Ubuntu and Fedora paths
CODE=""
for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
         /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    [ -f "$c" ] && { CODE="$c"; break; }
done
if [ -z "$CODE" ]; then
    echo "OVMF firmware not found: install the ovmf package." >&2
    exit 1
fi
VARS_TEMPLATE="$(dirname "$CODE")/$(basename "$CODE" | sed 's/CODE/VARS/')"

mkdir -p "$WORK"
if [ "$reset" -eq 1 ] || [ ! -f "$DISK" ]; then
    echo "Preparing a new disk from the latest build..."
    cp --sparse=always "$IMAGE" "$DISK"
    truncate -s +16G "$DISK"
    cp "$VARS_TEMPLATE" "$VARS"
elif [ "$IMAGE" -nt "$DISK" ]; then
    echo "Note: there is a build newer than the disk in use. Use --reset to start from it."
fi

if [ -w /dev/kvm ]; then
    ACCEL=kvm
    CPU=host
else
    echo "KVM not available: emulation will be slow."
    ACCEL=tcg
    # Baseline x86-64 processor, like the system (D-027)
    CPU=qemu64
fi

# Started from a snap app (e.g. VS Code): its GTK/GIO variables make QEMU load
# incompatible libraries from the snap and the window does not open.
if [ -n "${SNAP:-}" ]; then
    unset GTK_PATH GTK_EXE_PREFIX GTK_MODULES GTK_IM_MODULE_FILE GIO_MODULE_DIR \
          GDK_PIXBUF_MODULE_FILE GDK_PIXBUF_MODULEDIR GSETTINGS_SCHEMA_DIR LOCPATH
    if [ -n "${XDG_DATA_DIRS_VSCODE_SNAP_ORIG:-}" ]; then
        XDG_DATA_DIRS="$XDG_DATA_DIRS_VSCODE_SNAP_ORIG"
        export XDG_DATA_DIRS
    fi
fi

if [ "$text_mode" -eq 1 ]; then
    DISPLAY_ARGS="-nographic -serial mon:stdio"
else
    DISPLAY_ARGS="-vga std -serial mon:stdio"
fi

# Firmware: OVMF (UEFI) with its variables, or QEMU's default SeaBIOS (no flash drives)
if [ "$bios" -eq 1 ]; then
    FIRMWARE_ARGS=""
else
    FIRMWARE_ARGS="-drive if=pflash,format=raw,readonly=on,file=$CODE
        -drive if=pflash,format=raw,file=$VARS"
fi

# Second disk: after the system disk, so the firmware still boots project-os
OTHER_DISK_ARGS=""
if [ -n "$other_disk" ]; then
    [ -f "$other_disk" ] || { echo "Disk not found: $other_disk" >&2; exit 1; }
    OTHER_DISK_ARGS="-drive if=none,id=other,format=raw,file=$other_disk
        -device nvme,serial=projectos1,drive=other"
fi

# Sound card: Intel HD Audio with a codec that has output and input; what the system
# plays is written into the WAV file
AUDIO_ARGS=""
if [ -n "$audio_file" ]; then
    AUDIO_ARGS="-audiodev wav,id=audio0,path=$audio_file
        -device intel-hda -device hda-duplex,audiodev=audio0"
fi

# shellcheck disable=SC2086
exec qemu-system-x86_64 \
    -machine q35,accel="$ACCEL" -cpu "$CPU" -smp 2 -m 2048 \
    $FIRMWARE_ARGS \
    -drive if=none,id=system,format=raw,file="$DISK" \
    -device nvme,serial=projectos0,drive=system \
    $OTHER_DISK_ARGS \
    $AUDIO_ARGS \
    -nic user,model=e1000e \
    -device qemu-xhci -device usb-kbd -device usb-tablet \
    $DISPLAY_ARGS
