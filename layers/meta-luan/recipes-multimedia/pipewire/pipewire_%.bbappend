# Luán — PipeWire started in every user session (step 3c, D-061).
# The recipe installs the user units but enables none of them (its own comment: the
# class cannot do it), so nothing ever started PipeWire. Listed here, systemd.bbclass
# enables them with "systemctl --global": the socket for the first client, the service
# at login, so WirePlumber (WantedBy=pipewire.service) sets up the devices before any
# app plays a sound. PipeWire never runs for root (ConditionUser=!root upstream).
SYSTEMD_SERVICE:${PN}:luan = "pipewire.socket pipewire.service"
