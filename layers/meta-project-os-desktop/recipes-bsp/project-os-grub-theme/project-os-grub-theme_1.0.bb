SUMMARY = "project-os desktop — theme of the GRUB boot menu"
DESCRIPTION = "The boot menu theme of branding/grub-theme (D-009, D-023) with the \
               Inter fonts converted to GRUB's .pf2 format, deployed for the EFI \
               partition of the disk image (step 5b, D-060)."
HOMEPAGE = "https://github.com/aptecstudio/project-os"
LICENSE = "GPL-3.0-only & OFL-1.1"
LIC_FILES_CHKSUM = "\
    file://${COMMON_LICENSE_DIR}/GPL-3.0-only;md5=c79ff39f19dfec6d293b95dea7b07891 \
    file://inter/LICENSE.txt;md5=082d8cc7db39783f598b7eda8c911f9d \
"

DEPENDS += "grub-native"

# The theme has a single source, branding/ at the root of the repository (D-023),
# outside the layer
# nooelint: oelint.vars.fileextrapaths,oelint.vars.outofcontext
FILESEXTRAPATHS:prepend := "${PROJECT_OS_DESKTOP_LAYERDIR}/../../branding:"

INTER_VERSION = "4.1"
# nooelint: oelint.vars.downloadfilename - the file name carries Inter's version
SRC_URI = "\
    https://github.com/rsms/inter/releases/download/v${INTER_VERSION}/Inter-${INTER_VERSION}.zip;subdir=inter \
    file://grub-theme/ \
"
SRC_URI[sha256sum] = "9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e"

S = "${UNPACKDIR}"

inherit deploy nopackages

INHIBIT_DEFAULT_DEPS = "1"
PACKAGE_ARCH = "${MACHINE_ARCH}"

# Characters kept in the fonts: ASCII, Latin-1 and Latin Extended-A (names of other
# systems, future translations of the menu), punctuation (· – …) and the arrows of the
# key help. The whole font would make every .pf2 ten times bigger and slower to load.
GRUB_FONT_RANGES = "0x20-0x7e,0xa0-0x17f,0x2010-0x2027,0x2190-0x2193"

# grub-mkfont names each font "<name> <style> <size>" and reads the style from the
# file's bold and italic flags only: the Medium and SemiBold files give "Regular" too,
# so their weight goes into the name (theme.txt: "Inter Medium Regular 18").
# grub-mkfont prints a warning for every OpenType feature it does not use (kerning
# tables): they are not errors, so they go to a log file.
do_compile() {
    ttf="${S}/inter/extras/ttf"
    log="${B}/grub-mkfont.log"
    mkfont="grub-mkfont --range=${GRUB_FONT_RANGES}"
    $mkfont --name=Inter --size=14 --output=${B}/inter-regular-14.pf2 \
        $ttf/Inter-Regular.ttf 2>>"$log"
    $mkfont --name=Inter --size=18 --output=${B}/inter-regular-18.pf2 \
        $ttf/Inter-Regular.ttf 2>>"$log"
    $mkfont --name="Inter Medium" --size=18 --output=${B}/inter-medium-18.pf2 \
        $ttf/Inter-Medium.ttf 2>>"$log"
    $mkfont --name="Inter SemiBold" --size=28 --output=${B}/inter-semibold-28.pf2 \
        $ttf/Inter-SemiBold.ttf 2>>"$log"
}

do_deploy() {
    theme="${DEPLOYDIR}/project-os/grub-theme"
    install -d "$theme"
    install -m 0644 ${S}/grub-theme/theme.txt ${S}/grub-theme/*.png "$theme"
    install -m 0644 ${B}/*.pf2 "$theme"
    # OFL-1.1: the license goes with the fonts made from Inter
    install -m 0644 ${S}/inter/LICENSE.txt "$theme/Inter-LICENSE.txt"
}
do_compile[doc] = "Convert the Inter fonts used by the theme to GRUB's .pf2 format"
do_deploy[doc] = "Deploy the theme and its fonts for the EFI partition of the disk image"
addtask deploy after do_compile before do_build
