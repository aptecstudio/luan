SUMMARY = "Luán — initramfs"
DESCRIPTION = "systemd in initrd mode: finds the system slot given on the kernel \
               command line, verifies it with dm-verity, mounts it on /sysroot and \
               switches to it; the machine adds what else it needs before the switch, \
               e.g. the encrypted data partition and the /etc overlay (D-042, D-043, \
               D-044, D-047)."
HOMEPAGE = "https://github.com/aptecstudio/luan"
LICENSE = "GPL-3.0-only"

# Only what systemd needs to find, verify and mount the root file system (AGENTS.md
# §5.5): udev for /dev/disk/by-partlabel, systemd-veritysetup (in the systemd package,
# with the cryptsetup feature) for the erofs slot verified by dm-verity (D-047), mount,
# fsck for the ext4 data partition, the os-release data that becomes
# /etc/initrd-release, BusyBox for the emergency shell (sulogin needs /bin/sh). No
# kernel modules: the boot drivers are built in.
# LUAN_INITRD_INSTALL: what the machine adds (e.g. luan-storage-initrd).
LUAN_INITRD_INSTALL ??= ""
PACKAGE_INSTALL = "\
    systemd \
    udev \
    systemd-udev-rules \
    util-linux-mount \
    util-linux-fsck \
    e2fsprogs-e2fsck \
    os-release \
    busybox \
    ${LUAN_INITRD_INSTALL} \
"
# Nothing else from recommendations: the initramfs stays small
NO_RECOMMENDATIONS = "1"

IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""
IMAGE_FSTYPES = "cpio.zst"
IMAGE_NAME_SUFFIX = ""
IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

inherit core-image

# systemd runs as /init and knows it is in an initramfs from /etc/initrd-release
ROOTFS_POSTPROCESS_COMMAND += "luan_initrd_setup"
luan_initrd_setup[doc] = "Make systemd the init of the initramfs and mark it as an initrd"
luan_initrd_setup() {
    ln -sf ${nonarch_libdir}/systemd/systemd ${IMAGE_ROOTFS}/init
    cp ${IMAGE_ROOTFS}${nonarch_libdir}/os-release ${IMAGE_ROOTFS}${sysconfdir}/initrd-release
}
