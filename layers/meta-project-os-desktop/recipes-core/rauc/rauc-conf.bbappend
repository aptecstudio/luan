# RAUC configuration for the desktop and certificate of the CA that verifies updates
# (D-026). The certificate is NOT in the repository: it is taken from the key directory
# given by PROJECT_OS_KEYS (see kas/base.yml and tools/gen-dev-keys.sh).
FILESEXTRAPATHS:prepend:project-os-amd64 := "${THISDIR}/files:${PROJECT_OS_KEYS}:"
RAUC_KEYRING_FILE:project-os-amd64 = "ca.cert.pem"

python do_fetch:prepend:project-os-amd64() {
    keys = d.getVar('PROJECT_OS_KEYS') or ''
    if not keys or not os.path.isfile(os.path.join(keys, 'ca.cert.pem')):
        bb.fatal("CA certificate not found. Set PROJECT_OS_KEYS to the key directory; "
                 "for development, create the keys with tools/gen-dev-keys.sh")
}

# Boot attempts (D-058): after rauc-mark-good confirms the booted slot, give it its 3
# attempts back in grubenv (project-os-grub.cfg)
SRC_URI:append:project-os-amd64 = " \
    file://10-boot-attempts.conf \
    file://project-os-boot-attempts \
"

do_install:append:project-os-amd64() {
    install -d ${D}${nonarch_libdir}/project-os
    install -m 0755 ${UNPACKDIR}/project-os-boot-attempts ${D}${nonarch_libdir}/project-os/
    install -d ${D}${systemd_system_unitdir}/rauc-mark-good.service.d
    install -m 0644 ${UNPACKDIR}/10-boot-attempts.conf \
        ${D}${systemd_system_unitdir}/rauc-mark-good.service.d/
}

FILES:${PN}:append:project-os-amd64 = " \
    ${nonarch_libdir}/project-os \
    ${systemd_system_unitdir}/rauc-mark-good.service.d \
"
#   grub-editenv  writes the boot attempts into grubenv
RDEPENDS:${PN}:append:project-os-amd64 = " grub-editenv"
