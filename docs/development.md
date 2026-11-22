# Working on Luán from your own PC

How to download the project, build the desktop image and test it in the QEMU emulator.
Status: Phase 1 (base system), November 2026.

## 1. The build host

The build compiles the whole system from source (kernel, libraries, systemd and the
rest), so it needs a capable machine:

| | Minimum | Recommended |
|---|---|---|
| System | Ubuntu Server 24.04 LTS | Ubuntu Server 26.04 LTS |
| RAM | 16 GB | 32 GB |
| Free disk | 250 GB | 400 GB on SSD |
| Processor | 4 cores | 8 cores or more |

A virtual machine (VirtualBox, VMware, GNOME Boxes, Hyper‑V) or a dedicated PC both
work. In a VM, enable **nested virtualization**: without it the emulator works but is
very slow. No desktop is needed, the Server edition is enough; the emulator window can
also be opened from Ubuntu Desktop.

If your PC already runs Linux (Ubuntu or Debian), you can work directly there.

**Laptop or PC with few resources** (about 8 GB of RAM, 4 cores and 45 GB free): enough
for the Phase 1 image, with the `--low-resources` mode (section 3). It will not be
enough from Phase 2 on, when WPE WebKit and Skia are compiled.

## 2. Download the project and prepare the machine

```sh
git clone https://github.com/aptecstudio/luan.git
cd luan
tools/setup-host.sh
```

`setup-host.sh` installs the programs for Yocto, kas, QEMU and the UEFI firmware, the
code style tools and the branding tools, and creates the **development keys** to sign
updates in `~/.config/luan/keys` (outside the repository). It asks for
confirmation before changing system settings (`--yes` answers for you). At the end it
checks every tool and lists what is missing; the full list of packages is in
[`README.md`](../README.md#1-install-the-dependencies).

Clone the project into a **Linux file system** (ext4, btrfs, xfs), for example your home
directory: on NTFS, FAT or exFAT disks shared with Windows, or on network shares, the
build fails. The script warns if the repository is in such a place.

When it finishes, log out and back in (or open a new terminal).

## 3. Build the image

There are two modes. Pick one based on your machine:

| | Default | Low resources |
|---|---|---|
| Command | `tools/build.sh` | `tools/build.sh --low-resources` |
| For | the recommended build host (section 1) | a laptop or a PC with less than 16 GB of RAM |
| Parallel compilations | all cores | at most 6 (2 recipes × 3 processes) |
| Recipe work files | kept: later builds are faster | deleted as it goes: less disk |
| Disk for the first build | about 100 GB (estimate) | about 30 GB (measured), 45 GB free recommended |
| First build | 1 to 3 hours (estimate, depends on the machine) | about 4 hours on 4 cores (measured), more on slow PCs |

If the machine looks too small for the default mode (less than 16 GB of RAM or little
free space), the script says so and asks for confirmation before starting. You can
always stop with Ctrl-C and start again with the other mode: the work already done is
not lost.

The first build downloads a few GB of sources into `sources/` and works in `build/`.
Later builds reuse the work already done and take a few minutes, if little changes.

Other commands (they also work with `--low-resources`):

| Command | What it does |
|---|---|
| `tools/build.sh update` | signed update bundle (RAUC) |
| `tools/build.sh shell` | terminal with the bitbake commands |
| `tools/build.sh --help` | script help |

**Without the scripts.** Everything the scripts do is described in the `kas/` files;
the build can also be started directly with [kas](https://kas.readthedocs.io):

```sh
export LUAN_KEYS=~/.config/luan/keys
kas build kas/desktop-amd64.yml:kas/dev.yml                          # default
kas build kas/desktop-amd64.yml:kas/dev.yml:kas/low-resources.yml    # low resources
```

**Code style.** Before committing a change, run `tools/lint.sh`: it checks shell
scripts (ShellCheck), Python (ruff) and BitBake recipes (oelint-adv) with the
conventions of `AGENTS.md` §7, and later Rust, Luau and JavaScript too.

## 4. Test the image in the emulator

```sh
tools/run-qemu.sh            # graphical window, plus the console in the terminal
tools/run-qemu.sh --text     # everything in the terminal; to quit: Ctrl-a then x
tools/run-qemu.sh --reset    # start again from a new disk, copied from the latest build
tools/run-qemu.sh --bios     # the same disk started from a legacy BIOS instead of UEFI
tools/run-qemu.sh --with-disk=other.img   # a second disk, e.g. with another system
```

What to expect today:

1. GRUB boot menu with the Luán theme and the "Luán" entry, booted
   automatically after 5 seconds; from UEFI, Windows and the other known systems found
   on the disks get their own entry;
2. kernel and systemd start;
3. on **first boot**, the encrypted data partition is created in the free space;
4. text login: user `root`, no password (development configuration only); on the
   terminal console the login is automatic.

There is no graphical interface yet: it comes with Phases 2 (graphics framework and
compositor) and 5 (shell).

**Testing an update.** `tools/build.sh update` produces the signed bundle in
`build/tmp/deploy/images/luan-amd64/`. Inside the emulator, download it (for
example from a local web server on the build host, which QEMU reaches at `10.0.2.2`)
and install it with `rauc install <file>.raucb`: on reboot the system starts from the
other copy, and goes back to the previous one by itself if 3 boots in a row do not
complete.

**Protecting the data.** The data partition is created with an empty key, so at first
it is not protected. Inside the system, run:

```sh
luan-data-key setup          # recovery key, then password; removes the empty key
luan-data-key status         # which keys open the data partition
luan-data-key password       # change the password (or set a new one with the recovery key)
luan-data-key recovery-key   # replace the recovery key
```

From the next boot the password is asked on the screen (in the QEMU window, not in the
`--text` terminal); the recovery key is accepted at the same prompt. The keyboard
layout at that prompt is the US one, like the system's console.

**Testing network, Bluetooth and audio.** Start the emulator with a sound card whose
output is recorded: `tools/run-qemu.sh --audio-file=out.wav`. Inside the system:

```sh
nmcli device                 # eth0 connected; Wi-Fi and modems on real hardware
ping -c 2 example.com        # network and name resolution
mmcli -L                     # modems ("No modems were found" in the emulator)
bluetoothctl list            # adapters (none in the emulator: the service waits)
```

PipeWire runs for each user and never for root, so audio is tested with a normal user
in the `audio` group (in the development image, which has only `root`, create one):

```sh
adduser -D tester
sed -i -E 's/^(audio:.*[^:])$/\1,tester/' /etc/group   # BusyBox adduser cannot do it
loginctl enable-linger tester                          # starts the user's session
systemd-run -M tester@ --user --wait --pipe wpctl status
systemd-run -M tester@ --user --wait --pipe speaker-test -t sine -f 440 -l 3
```

`wpctl status` lists the sound card; the tone ends up in `out.wav`. On real hardware
the same commands play through the speakers.

## 5. Current limitations

- **Data protection by command:** until the setup of Phase 8 exists, the data
  partition stays unprotected until `luan-data-key setup` is run; the empty key
  also adds about 2 s to every boot after the setup (D-058). No TPM unlocking yet
  (Phase 8).
- **Changes to `/etc`** (network, users, host name) are kept on the encrypted data
  partition and survive reboots and updates; if an update changes a file you edited,
  your version is kept and the file is listed in `/var/lib/luan/etc-conflicts`.
- **Android / mobile emulator:** not yet, it comes with Phase 7.

## 6. If something goes wrong

- **Build stopped because memory ran out** (processes killed by the system, messages
  like "Killed" or "out of memory"): run again with `tools/build.sh --low-resources`.
- **Build stopped with an error:** copy the last lines of the terminal and, if given,
  the log file named in the error (in `build/tmp/work/...`). The build host's system
  and the output of `git log -1` are useful too.
- **`setup-host.sh` ends with "Setup incomplete":** the list shows what is missing; run
  it again after fixing the cause (network, `sudo` rights), it keeps what is done.
- **Errors about permissions, links or "dubious ownership" from git:** the repository is
  probably on an NTFS/FAT disk or owned by another user. Clone it again into your home
  directory.
- **Error about namespaces or "unshare":** run `tools/setup-host.sh` again and accept
  the AppArmor change (see the explanation in the script).
- **Error about the keys:** check that `~/.config/luan/keys/ca.cert.pem` exists,
  or create the keys with `tools/gen-dev-keys.sh`.
- **The emulator does not start or is extremely slow:** check that `/dev/kvm` exists and
  that your user is in the `kvm` group (`groups`).
- **The QEMU window does not open when started from VS Code or another snap app:**
  `tools/run-qemu.sh` already handles it; if you start `qemu-system-x86_64` by hand,
  launch it from a normal terminal.

## 7. Where things are

| Path | Contents |
|---|---|
| `AGENTS.md`, `MEMORY.md`, `ROADMAP.md` | rules, decisions, project status |
| `kas/` | build configuration |
| `layers/` | Yocto recipes: distribution, image, machine, kernel, boot |
| `branding/` | logo, its design concept and the boot menu theme |
| `tools/` | scripts from this guide and checking tools (`lint.sh` for the code style) |
| `ruff.toml`, `.shellcheckrc`, `tools/oelint-constants.json` | settings of the style checks |
| `build/`, `sources/` | created by the build, not versioned |
