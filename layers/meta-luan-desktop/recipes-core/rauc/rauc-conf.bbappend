# RAUC configuration for the desktop and certificate of the CA that verifies updates
# (D-026). The certificate is NOT in the repository: it is taken from the key directory
# given by LUAN_KEYS (see kas/base.yml and tools/gen-dev-keys.sh).
FILESEXTRAPATHS:prepend:luan-amd64 := "${THISDIR}/files:${LUAN_KEYS}:"
RAUC_KEYRING_FILE:luan-amd64 = "ca.cert.pem"

python do_fetch:prepend:luan-amd64() {
    keys = d.getVar('LUAN_KEYS') or ''
    if not keys or not os.path.isfile(os.path.join(keys, 'ca.cert.pem')):
        bb.fatal("CA certificate not found. Set LUAN_KEYS to the key directory; "
                 "for development, create the keys with tools/gen-dev-keys.sh")
}

# Boot attempts (D-058): after rauc-mark-good confirms the booted slot, give it its 3
# attempts back in grubenv (luan-grub.cfg)
SRC_URI:append:luan-amd64 = " \
    file://10-boot-attempts.conf \
    file://luan-boot-attempts \
"

do_install:append:luan-amd64() {
    install -d ${D}${nonarch_libdir}/luan
    install -m 0755 ${UNPACKDIR}/luan-boot-attempts ${D}${nonarch_libdir}/luan/
    install -d ${D}${systemd_system_unitdir}/rauc-mark-good.service.d
    install -m 0644 ${UNPACKDIR}/10-boot-attempts.conf \
        ${D}${systemd_system_unitdir}/rauc-mark-good.service.d/
}

FILES:${PN}:append:luan-amd64 = " \
    ${nonarch_libdir}/luan \
    ${systemd_system_unitdir}/rauc-mark-good.service.d \
"
#   grub-editenv  writes the boot attempts into grubenv
RDEPENDS:${PN}:append:luan-amd64 = " grub-editenv"
