# Luán — grub-mkfont in the GRUB tools of the build (step 5b, D-060).
# Only grub-native: luan-grub-theme converts the Inter fonts of the boot menu to
# GRUB's .pf2 format with it. The GRUB that goes into the image does not change.
DEPENDS:append:class-native:luan = " freetype-native"
EXTRA_OECONF:remove:class-native:luan = "--disable-grub-mkfont"
EXTRA_OECONF:append:class-native:luan = " --enable-grub-mkfont"
