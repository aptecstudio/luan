# Luán — WirePlumber started with PipeWire in every user session (step 3c, D-061).
# The recipe installs the user unit without enabling it; listed here, systemd.bbclass
# enables it with "systemctl --global" (WantedBy=pipewire.service).
SYSTEMD_SERVICE:${PN}:luan = "wireplumber.service"
