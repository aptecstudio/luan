SUMMARY = "Luán — tools for testing the hardware (development images only)"
DESCRIPTION = "Command-line tools to check network, Bluetooth, audio and devices on a \
               development image (kas/dev.yml, D-061). Never in released images: the \
               system's own settings and the broker take their place (AGENTS.md §5.5)."
HOMEPAGE = "https://github.com/aptecstudio/luan"
LICENSE = "GPL-3.0-only"

inherit packagegroup

#   networkmanager-nmcli   connect to wired, Wi-Fi and mobile networks
#   iw                     Wi-Fi details: regulatory domain, scan, link
#   alsa-utils-*           test tone (speaker-test), playback, capture, volumes
#   pciutils, usbutils     list the devices and the drivers in use (lspci, lsusb)
# bluetoothctl (BlueZ) and wpctl (WirePlumber) are already in their services.
RDEPENDS:${PN} = "\
    alsa-utils-amixer \
    alsa-utils-aplay \
    alsa-utils-speaker-test \
    iw \
    networkmanager-nmcli \
    pciutils \
    usbutils \
"
