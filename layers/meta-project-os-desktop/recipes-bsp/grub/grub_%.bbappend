# project-os — grub-mkfont in the GRUB tools of the build (step 5b, D-060).
# Only grub-native: project-os-grub-theme converts the Inter fonts of the boot menu to
# GRUB's .pf2 format with it. The GRUB that goes into the image does not change.
DEPENDS:append:class-native:project-os = " freetype-native"
EXTRA_OECONF:remove:class-native:project-os = "--disable-grub-mkfont"
EXTRA_OECONF:append:class-native:project-os = " --enable-grub-mkfont"
