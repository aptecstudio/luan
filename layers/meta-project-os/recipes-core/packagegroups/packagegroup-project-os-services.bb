SUMMARY = "project-os — hardware services: network, Bluetooth, audio"
DESCRIPTION = "The system services that make the hardware usable (D-061): \
               NetworkManager for wired, Wi-Fi and mobile broadband networks, BlueZ \
               for Bluetooth, PipeWire with WirePlumber for audio. Their build options \
               are in the distribution configuration."
HOMEPAGE = "https://github.com/aptecstudio/project-os"
LICENSE = "GPL-3.0-only"

inherit packagegroup

RDEPENDS:${PN} = "\
    ${AUDIO} \
    ${BLUETOOTH} \
    ${NETWORK} \
"

# NetworkManager: wired networks are handled by the daemon itself; Wi-Fi through
# wpa_supplicant (pulled by networkmanager-wifi), mobile broadband through ModemManager
# (pulled by networkmanager-wwan) with the provider database for the APN
NETWORK = "\
    networkmanager-daemon \
    networkmanager-wifi \
    networkmanager-wwan \
"

# BlueZ: bluetoothd, with the profiles for keyboards, mice and audio devices
BLUETOOTH = "bluez5"

# PipeWire and its session manager, started by systemd for each user session; ALSA's
# UCM profiles describe the devices of laptops with an audio DSP (Intel SOF, AMD ACP)
AUDIO = "\
    pipewire \
    wireplumber \
    alsa-ucm-conf \
"
