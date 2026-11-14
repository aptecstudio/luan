# project-os — GRUB for BIOS boot in the same disk image (step 4e, R-26, D-059).
#
# After wic has written the disk, and before the .wic.bmap map is made from it,
# files/bios/project-os-bios-boot puts GRUB's BIOS boot code into the disk: boot.img in
# the protective MBR, core.img in the bios_grub partition. core.img reads grub.cfg and
# grubenv from the EFI partition, the same ones as on UEFI.
# The work is in a separate POSIX script because BitBake's shell parser does not
# accept arithmetic expansion, which the byte offsets need.

PROJECT_OS_BIOS_BOOT_SCRIPT = "${PROJECT_OS_DESKTOP_LAYERDIR}/files/bios/project-os-bios-boot"

# Modules built into core.img: BIOS disks, GPT, FAT (the EFI partition), the menu
# language and the commands used by project-os-grub.cfg on BIOS (load_env/save_env,
# linux/initrd, tests, echo), and the graphical menu with its theme (fonts, PNG images,
# step 5b, D-060) on the BIOS's VESA video modes (vbe; not all_video, whose drivers for
# QEMU's video cards bypass the firmware). Nothing is loaded from disk: the EFI partition
# has no i386-pc module directory.
PROJECT_OS_BIOS_GRUB_MODULES = "\
    biosdisk part_gpt fat normal configfile echo test loadenv linux minicmd search \
    font gfxterm gfxterm_background gfxmenu png vbe \
"
# grub.cfg and grubenv on the EFI partition, the second partition of the boot disk
# (empty device name: the disk the BIOS booted from)
PROJECT_OS_BIOS_GRUB_PREFIX = "(,gpt2)/EFI/BOOT"

do_image_wic[depends] += "grub-native:do_populate_sysroot"
do_image_wic[file-checksums] += "${PROJECT_OS_BIOS_BOOT_SCRIPT}:True"

IMAGE_CMD:wic:append() {
    sh "${PROJECT_OS_BIOS_BOOT_SCRIPT}" "$out.wic" "${STAGING_LIBDIR_NATIVE}/grub/i386-pc" \
        "${PROJECT_OS_BIOS_GRUB_PREFIX}" ${PROJECT_OS_BIOS_GRUB_MODULES}
}
