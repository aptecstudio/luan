# MEMORY.md — Choices, style and conventions

Current state of the project decisions and their reasons, of the visual style, of the
code structure and of the syntax conventions. Update rules in `AGENTS.md` §3: this file
describes only the current state; the history of each choice is in the git commits.

**Decision states:** `requirement` (set by the user) · `confirmed` (approved) ·
`proposed` (awaiting approval).

---

## 1. Basic requirements

Set by the user (2026-11-11 to 2026-11-13).

| ID | Requirement |
|---|---|
| R-02 | System reduced to the essentials: no superfluous packages, clean and light. |
| R-03 | **Wayland** for video and input devices. |
| R-04 | Keep support for the main modern hardware (audio, Bluetooth, Wi‑Fi, GPU, etc.) in the kernel and firmware. |
| R-05 | Architectures: **mobile ARM** (smartphones, tablets) and **Intel/AMD desktop**. |
| R-09 | Each application is a process that can have subprocesses; its windows belong to its own process (shell and panels included). |
| R-10 | All system dialogs are replaced by predefined dialogs of the system, built with the native framework. |
| R-11 | Each application declares in its `package.json` name, metadata and the native APIs it requires, also as an extra security layer. |
| R-12 | Each application has basic system APIs: filesystem, devices, windows, system services. |
| R-13 | An application can request root access from its `package.json` and/or through dedicated APIs. |
| R-14 | The system must be **secure**. |
| R-15 | Main branch of the repository: `main`. |
| R-16 | **Mobile:** installation by flashing a published image (fastboot package, or zip from the device recovery where one exists); the setup continues on first boot with a graphical interface. |
| R-17 | **Desktop:** installation with a wizard application in Windows/Debian style, built like all the other apps. |
| R-18 | **Desktop:** boot menu with centered entries and the system logo (a generic logo at first), allowing dual boot with Windows or other systems. |
| R-19 | No live mode for now. |
| R-20 | **No starting distribution:** start from Linux (the kernel) and build every package on top. |
| R-21 | **One system, two bases:** with few changes, the Android-based mobile version (vendor kernel and drivers) and the desktop one; both on Linux. |
| R-22 | Native components in **Rust**. |
| R-23 | First mobile device: the user's **Google Pixel**. Not to be neglected: older **Oppo** and **Samsung** models the user owns. |
| R-24 | **Differentiated setup:** on desktop it includes disk formatting, keyboard layout and basic configuration; on mobile it asks for other data or starts from later steps (the system is already installed from the recovery). |
| R-25 | **Backward compatibility at every level and in every context of the project**: hardware, boot, formats, APIs, data, updates. |
| R-26 | **Desktop:** boot from both UEFI and legacy BIOS, with the same image. |
| R-27 | **Encryption without TPM:** the data partition must work on older PCs without a TPM chip too. |
| R-28 | **Desktop processors:** all 64-bit x86 processors (baseline x86-64 instructions). |
| R-29 | **App APIs as objects in the script context**, like the `chrome.*` APIs of extensions: apps reach them from a global object, without importing them. |
| R-30 | **Dynamic script loading with `include("url")`** and its counterpart **`includeAsync("url")`**, not with the language's own module system. Each included script exposes its symbols to the includer through its exports; included scripts are cached; cyclic imports are prevented. |
| R-31 | **Isolated root for each app:** scripts, images and other resources are loaded only from there, with a dedicated protocol (`app://`), and only the app itself can access its own resources. External files only through the filesystem system APIs. |
| R-32 | **Design:** a hybrid of Windows 11, macOS Big Sur and Xiaomi MIUI. |
| R-33 | **Interoperability between devices:** the devices running Luán, desktop and mobile, cooperate as a single ecosystem, on the model of Apple's. |
| R-34 | **UI framework `systemui`:** our own framework to build graphical interfaces (buttons, headers, footers, text fields and everything an interface needs), reached as `system.ui.*` like the other APIs (R-29). An app that wants it declares `systemui` in its `package.json`. Developers can create their own custom components. Apps (system apps included) do not write HTML: interfaces are written in Lua or XML (R-40), with a class and event model; the framework owns the component tree and its removal. |
| R-35 | **Class and event model for the APIs:** the system APIs (`system.*`) also follow the class and event model, like `system.ui`. |
| R-36 | **Developer guides:** a documentation folder of indexed Markdown pages for `systemui`, organized by component, written as a real guide for programmers on how to build interfaces with the framework; the same kind of guide for all the system APIs (`system.*`), organized by namespace. |
| R-37 | **Native interface, Lua as the main language:** applications do not run on a web engine. The main script of every app is written in **object-oriented Lua**; Lua is the main language of the project for apps, shell and system interfaces. |
| R-38 | **Own graphics framework on EGL**, the same on desktop and mobile, that draws the components of `systemui`. |
| R-39 | **App formats:** an app is a **folder** whose resources are reached with `app://` (R-31), or a **`.pak` package** (a zip archive with the `.pak` extension). |
| R-40 | **Component descriptions** either in a Lua script or in **XML**, Android-layout style. |
| R-42 | **Release images:** besides being buildable, the project publishes ready-to-use files: an installation image for desktops and a flashable image for each supported mobile device (D-056). |
| R-41 | **WebKit** is the base for web views and for a future web browser; on mobile another library may be used if needed, but the goal is a single system on both kinds of device (WPE WebKit chosen, D-051). |

---

## 2. Decision log

### D-005 — Security: permission broker and per-app sandbox · `confirmed` (2026-11-11)
- **What:**
  - a system daemon (*broker*) is the only one exposing native APIs; apps talk to it
    through authenticated IPC (Unix socket, process identity checked with
    `SO_PEERCRED`);
  - each app runs in a sandbox (`bubblewrap` + `seccomp` filter), with filesystem,
    network and devices denied by default;
  - the permissions declared in `package.json` are an **upper bound**: the broker
    grants them only after installation/approval by the user;
  - root (R-13) never gives the app a root shell: the broker performs specific
    privileged operations on its behalf, after confirmation with a system dialog, and
    records them in the audit log.
- **Why:** R-13 and R-14 are in tension; an app with full root would cancel every other
  protection. Mediation keeps the functionality with a controlled risk.

### D-006 — System dialogs through portals · `confirmed` (2026-11-11)
- **What:** our own `xdg-desktop-portal` backend and polkit agent show the requests
  (file selection, permissions, password, authentication) as system dialogs of the
  shell, built with the native framework (D-054).
- **Why:** R-10. It is the point where toolkits and the system services already ask for
  an interaction; replacing it there also covers software not written for Luán.

### D-007 — Own Wayland compositor · `confirmed` (2026-11-11)
- **What:** a minimal compositor written for Luán, in Rust on Smithay (D-013).
  Each app window is a separate Wayland surface; the shell (a native app of the
  framework, D-054) draws panels and decorations through *layer-shell* and decides
  window layout and animations through a private compositor ↔ shell protocol.
- **Why:** R-14 and the animations of the framework (D-050): windows isolated per
  process, animations under the control of the shell.
- **Discarded alternatives:** a single process drawing every app (weak isolation), an
  existing compositor (little control over animations).

### D-009 — Desktop boot menu: GRUB 2 with own theme · `confirmed` (2026-11-11)
- **What:** GRUB 2 (UEFI, and BIOS with the same disk, D-059) with a Luán theme:
  centered menu, logo at the top, own background and fonts (D-023, in the image since
  D-060). Windows and other systems are found by GRUB itself at every boot (D-060).
- **Secure Boot:** with no upstream distribution there is no `shim` already signed by
  Microsoft. Initial phase: Luán keys enrolled by the user
  (MOK) during installation; getting a shim signed by Microsoft is a long-term goal.
- **Logo:** the Luán logo (D-062), an SVG exported to PNG for the theme.
- **Why:** R-18. GRUB supports graphical themes, multiboot and Secure Boot.
- **Discarded alternatives:** systemd-boot (no graphical theme); rEFInd (to be
  re-evaluated if GRUB turns out awkward to integrate).

### D-010 — Desktop installation medium · `confirmed` (2026-11-11)
- **What:** a hybrid `.iso` installation image (D-056), for USB sticks and DVDs, that starts only the bare minimum (kernel,
  compositor, Lua runtime and framework, broker) and opens the installation wizard
  directly (a native app, D-054); no user session or apps. No web engine on the
  medium.
- **Why:** R-17 and R-19. The wizard needs the graphics stack running, so the
  installation environment has to boot; it stays a closed environment dedicated to
  installation, not a usable live system.
- **The wizard handles:** language, keyboard, disk and partitions (next to an existing
  Windows too, without touching its boot), disk encryption, user, GRUB installation.

### D-011 — Mobile installation: fastboot package and recovery zip · `confirmed` (the user's choice, 2026-11-13)
- **What:** for each supported model, a **fastboot package** (images plus a flashing
  script, like Google's factory images) that works with an unlocked bootloader alone,
  and, where the model has a custom recovery, a **zip** to install from it. Both come
  from the same build and carry the same signed system image (D-056). On first boot
  the setup app starts (see D-017 for the steps).
- **Why:** R-16. Fastboot works on every model with an unlockable bootloader, recent
  Pixels included, which often have no custom recovery; the recovery zip is the usual
  method where one exists.
- **Discarded alternatives:** recovery zip only (it needs a custom recovery for each
  model); fastboot only (less comfortable where a recovery is already installed).

### D-012 — System built from source with Yocto/OpenEmbedded · `confirmed` (2026-11-11)
- **What:** every component (toolchain, libc, libraries, WebKit, Skia, kernel) is compiled
  from source with Yocto/OpenEmbedded, on the current LTS branch. Our code lives in own
  layers: `meta-luan` (common user space, the same on all platforms),
  `meta-luan-desktop` and `meta-luan-mobile` (hardware layer, D-014), plus
  one layer for each mobile device.
- **Discarded alternatives:** Buildroot (struggles with WebKit and with many
  devices), own tool in Rust (all to be written and maintained).
- **Why:** R-20. Full control over what goes into the system and reproducible builds.
- **Important consequence:** **update security** becomes the project's responsibility.
  Without an upstream distribution, every known flaw (WebKit in particular, which has
  many every year) has to be tracked and fixed by us. A vulnerability monitoring
  process is needed from Phase 1. For WebKit see D-019.

### D-013 — Native components in Rust · `confirmed` (2026-11-11)
- **What:** compositor (on Smithay), Luau runtime host and graphics framework (D-049,
  D-050), broker, system daemons and own build tools in Rust. External C/C++ libraries
  (Luau, Skia, WPE WebKit, Mesa) are used through bindings.
- **Why:** R-22; memory safety in the most exposed components (R-14).
- **Discarded alternatives:** C with wlroots.

### D-014 — Single user space, per-platform hardware layer · `confirmed` (2026-11-11)
- **What:** everything above the kernel (libc, compositor, runtime, framework, shell,
  apps) is identical on desktop and mobile. Only the **hardware layer** changes:
  - **desktop (amd64):** mainline Linux kernel, Mesa for the GPU, linux-firmware
    firmware;
  - **mobile (arm64, Android base):** the phone vendor's kernel and firmware, Android
    drivers (GPU, modem, sensors, camera) reached through Halium/libhybris; where a model
    has good mainline support, that can be used.
- **Why:** R-21. The differences stay confined in one folder per platform and device;
  the rest is compiled twice (amd64, arm64) without changes.
- **Constraints:**
  - libhybris requires glibc (D-015);
  - the framework (D-050) and WPE WebKit (D-051) must work with EGL through libhybris:
    to be checked early, it is the main technical risk on the mobile side;
  - most phones do not boot a mainline kernel: a per-device kernel or the vendor's
    Android kernel through Halium/libhybris is needed, so phones are supported only from
    an explicit list of models (R-23), chosen one by one;
  - bootloader unlocking varies: generally possible on Pixels not tied to a carrier,
    limited or absent on several Samsung, Xiaomi and Oppo models.

### D-015 — C library: glibc · `confirmed` (2026-11-11)
- **Why:** needed for libhybris (Android drivers, D-014) and the best tested with WebKit.
- **Discarded alternatives:** musl (incompatible with libhybris, less tested with WebKit).

### D-016 — Init: systemd · `confirmed` (2026-11-11)
- **What:** systemd as init, with udev, logind and journald.
- **Why:** session and device management (logind/udev) is needed by the compositor;
  built-in service sandboxing; existing Halium support.
- **Alternatives:** lightweight inits (s6, dinit) or an own init in Rust: fewer
  dependencies, but udev/sessions/seats to be rebuilt.

### D-017 — Differentiated desktop / mobile setup · `confirmed` (2026-11-11)
- **What:** a single setup app (native framework, D-054) with steps enabled according to
  the platform (R-24).
  - **Desktop (from the USB image, D-010):** language → keyboard layout → time zone →
    network (optional) → disk: partitioning/formatting, next to Windows too → disk
    encryption → user and password → summary and installation (with GRUB and
    detection of other systems) → reboot → first boot: preferences.
  - **Mobile (first boot after the recovery):** language → Wi‑Fi/SIM network (PIN) →
    automatic time zone → user and unlock code (PIN/password, fingerprint if any) →
    system permissions (location, notifications) → preferences. No disk or physical
    keyboard step.
- **Why:** on mobile the system is already written by the recovery; on desktop the
  setup is also the installation.

### D-018 — Immutable system with A/B updates · `confirmed` (2026-11-11)
- **What:** read-only system partition, verified with dm-verity and signed; two slots
  (A/B): the update is written to the inactive slot and, if the boot fails, the system
  automatically goes back to the previous one. User data and apps on a separate
  (encrypted) partition. Apps are installed as signed packages (DA-05), outside the
  image. Candidate tool: RAUC (integrated in Yocto).
- **Why:** R-14 (the system cannot be altered at runtime) and atomic updates, the same
  on desktop and mobile, like Android and ChromeOS. Even the mediated "root" (D-005)
  cannot modify the system partition.
- **Discarded alternatives:** traditional package manager (less secure and predictable).

### D-019 — WebKit fork maintained by the project · `confirmed` (2026-11-11)
- **What (decided by the user):** WebKit is compiled from a fork of the project, on
  which we fix vulnerabilities ourselves. It is built as **WPE WebKit** (D-051).
- **Approach:** an *aligned* fork, not a diverging one:
  - the fork follows the official stable branch (`webkitglib/<version>`, shared by the
    WPE and GTK ports) and receives every official security release as soon as it
    comes out (WSA advisories);
  - our changes are in separate, documented commits, re-applied on top of each new
    stable version;
  - our own fixes: for known vulnerabilities without an official fix, for hardening
    (unneeded features disabled, more restrictive build options) and for the
    integration with the framework (D-050) and the broker;
  - each fix of ours, when of general interest, is proposed upstream.
- **Why:** a diverging fork loses the official fixes, which are the vast majority of
  those available (WebKit is a project of millions of lines with a dedicated security
  team); an aligned one adds a layer of ours without giving them up.
- **In Yocto:** the `wpewebkit` recipe of `meta-luan` points to the fork and to
  the tag released by us.
- **Repository:** `aptecstudio/WebKit`, fork of `WebKit/WebKit` with all branches.
  - `main`: copy of the official one, without our changes;
  - `luan/<version>`: our work branch, created from the stable branch
    `webkitglib/<version>`; at each new stable release the next branch is created and
    our patches are re-applied;
  - first branch: `project-os/2.54`, from `webkitglib/2.54` (commit `2b614de`, created
    on 2026-11-11; latest official release at that date: 2.54.2). It keeps the
    project's former name (D-062): renaming it would break the clones and links that
    already point to it; the next branches follow `luan/<version>`.

### D-020 — GPL-3.0 license · `confirmed` (2026-11-11)
- **What:** the Luán code is released under the GNU GPL v3 license (`LICENSE`
  file). The WebKit fork keeps WebKit's original licenses (LGPL/BSD).
- **Why:** the user's choice; whoever modifies and distributes the system must publish
  its code, avoiding closed forks.

### D-021 — Phases in sequence, not in parallel · `confirmed` (2026-11-11)
- **What:** work happens on one phase at a time, in roadmap order.
- **Why:** the user's request.

### D-022 — Bottom-up development · `confirmed` (2026-11-11)
- **What:** phase order: base system (Yocto, kernel, boot) → graphics stack → broker →
  app runtime → shell → system apps → mobile → installation.
- **Why:** the user's choice: each level is built and tested on the real system below
  it.
- **Accepted cost:** the application model (the newest part) is checked later; Yocto
  builds take hours and a robust build host (DA-11).
- **Discarded alternative:** starting from the runtime prototype on an existing
  distribution.

### D-023 — Logo images and GRUB theme · `confirmed` (2026-11-11)
- **What:**
  - the logo (D-062) in `branding/logo/luan-logo.svg`, **monochrome white** on a dark
    background, in the style of the elementary OS boot screen, as asked by the user;
    exported to `luan-logo-{256,96}.png` and, in night blue for light backgrounds such
    as the README on GitHub, to `luan-logo-dark-256.png`;
  - GRUB theme in `branding/grub-theme/`: logo and name at the top, centered entries
    520 px wide, selected entry highlighted by a light semi-transparent box, countdown
    and key help at the bottom;
  - all images are regenerated with `branding/tools/render.py` (SVG → PNG with
    `rsvg-convert`, background and boxes with Pillow/NumPy); `branding/previews/`
    holds an approximate preview, which does not go into the image.
- **Font:** Inter (OFL‑1.1 license). The `.pf2` files for GRUB are not in the
  repository: the `luan-grub-theme` recipe downloads Inter from the official
  project and makes them with `grub-mkfont` (Regular 14 and 18, Medium 18, SemiBold 28;
  D-060).
- **Background:** ordered dithering instead of noise, to avoid color banding with a
  light PNG (224 KB against 1.6 MB).
- **Menu texts:** English (D-037); the localization of the boot menu is to be decided
  later.
- **Why:** R-18; the theme lives in `branding/` as the single source, and the recipe
  will copy it into the image.

### D-024 — Yocto build configuration · `confirmed` (2026-11-11)
- **Pinned versions:** Yocto 6.0 "Wrynose" (LTS), OpenEmbedded-Core `2285da0`, bitbake
  2.18 `6e260eb`. They are updated only with a dedicated commit.
- **Tool:** [kas](https://kas.readthedocs.io): YAML files in `kas/` that describe
  repositories, versions, layers, machine and distribution; the build is recreated with
  a single command (`kas build kas/desktop-amd64.yml`). `kas/dev.yml` adds the
  development settings (passwordless root, testing in QEMU): **never** for released
  images. Discarded alternative: `bitbake-setup` (new in Yocto 6.0, still poorly
  documented).
- **Sources without poky:** OpenEmbedded-Core and bitbake directly, with our
  `luan` distribution (`layers/meta-luan/conf/distro/luan.conf`).
- **`luan-amd64` machine:** baseline x86-64 instructions (D-027); `linux-yocto` 6.18 LTS
  kernel with the reference configuration for 64-bit PCs (`common-pc-64`), UEFI boot
  with GRUB.
- **Excluded distribution features** (reasons in the distribution file): x11,
  pulseaudio, nfs, zeroconf, 3g, nfc, ptest, multiarch, debuginfod.
- **Check done:** bitbake reads configuration, image and kernel without errors or
  warnings (read-only check, no compilation). To check at the first build: download,
  compilation, `wic` partition layout, syntax of the kas files: all confirmed by the
  first full build (2026-11-11) and the QEMU tests (D-026).

### D-025 — Kernel and firmware for desktop hardware · `confirmed` (2026-11-11)
- **Configuration fragments** in
  `layers/meta-luan-desktop/recipes-kernel/linux/files/`, one per area: disks and
  file systems, graphics, audio, Bluetooth, Wi‑Fi, wired network, input and platform.
  147 options, all checked against the Kconfig files of Linux 6.18.
- **Built in (=y) only the boot drivers** (NVMe, SATA, ext4, FAT, UEFI framebuffer,
  keyboard, USB 3): the initramfs carries no kernel modules (D-043), so the system disk
  must be readable before loading modules. Everything else is a module, loaded only if the hardware is there.
- **Graphics:** Intel (i915, xe), AMD (amdgpu, the first GCN too, and radeon), NVIDIA
  only with the free nouveau driver; drivers for virtual machines (QEMU, VirtualBox,
  VMware, Hyper‑V).
- **Firmware:** `packagegroup-luan-desktop-hw`, 27 `linux-firmware` packages plus
  the Wi‑Fi frequency database; compressed with zstd.
- **Own recipes** for what OpenEmbedded-Core does not have: Intel SOF audio firmware
  (D-039) and Intel microcode, loaded early (D-043).
- **Tool:** `tools/check-kernel-fragments.py` checks that each option exists in the
  kernel version and that the value is allowed by the type; it already found an error
  (`TG3` instead of `TIGON3`). Options dropped for a missing dependency are caught by
  the build, which compares the fragments with the final configuration (D-041).
- **Checks done:** bitbake resolves the image dependency graph without errors;
  firmware, regdb and fragments enter the build; the kernel compiles and
  `do_kernel_configcheck` reports nothing (`MMC_SDHCI_ACPI` and `MMC_SDHCI_PLTFM` are
  declared `=m` in `storage.cfg`, as our `MMC=m` requires, D-038).
- **Base image:** includes `MACHINE_EXTRA_RRECOMMENDS`, otherwise the machine's modules
  and firmware would be left out.

### D-026 — A/B partitions, boot and data partition · `confirmed` (2026-11-12)
- **Disk layout (GPT)**, in `files/wic/luan-ab.wks.in` (`.in` extension: bitbake
  substitutes variables such as `${EFI_PROVIDER}` in it):
  | # | Name | Size | Contents |
  |---|---|---|---|
  | 1 | `bios_grub` | 1 MiB | GRUB for BIOS boot (step 4e) |
  | 2 | `esp` | 512 MiB | EFI partition: GRUB, menu, theme, slot state (`grubenv`), boot files of each slot (D-048); mounted on `/efi`, root-only access |
  | 3 | `root_a` | 4 GiB | system, copy A: erofs verified by dm-verity, read-only (D-047) |
  | 4 | `root_b` | 4 GiB | system, copy B, written by updates |
  | 5 | `data` | rest | data, created on first boot, encrypted, mounted on `/var` (`/home` → `/var/home`) by the initramfs (D-044) |
- **Slot selection:** GRUB (`files/wic/luan-grub.cfg`) boots the first valid slot
  of `ORDER` that has not been given up; every slot has 3 boot attempts (D-058), and
  `rauc-mark-good` gives them back once the system is up. After 3 boots that did not
  complete, it switches to the other slot. In the menu the active slot is called "Luán", the other one
  "Luán (previous version)". `grubenv` values are `1`/`0`, like RAUC's reference
  layout: RAUC writes them that way, and `true`/`false` made every slot unbootable after
  the first update (found in QEMU).
- **Updates:** RAUC (`recipes-core/rauc/files/system.conf`); bundles signed in *verity*
  format, zstd-compressed (`luan-bundle`). The CA certificate goes into the
  image; keys outside the repository (`LUAN_KEYS`, `tools/gen-dev-keys.sh`).
- **Data partition:** created by `systemd-repart` on the free space, LUKS2, works
  without TPM (R-27). Until step 4d the key is **empty** (placeholder, data not
  protected): the setup will enroll password and recovery key, and the TPM as an extra
  method where present (step 4d and Phase 8). `e2fsprogs-mke2fs` is needed: repart
  creates and encrypts the partition but formats it with `mkfs.ext4`.
- **EFI partition mount:** `efi.mount` (`luan-storage`) mounts it by the GPT label
  `esp`, like the slots and the data partition, so every slot mounts it the same way;
  the `/efi` directory is created at build time (`luan_efi_mountpoint`, 0700),
  because the read-only system cannot create it. Discarded: an fstab line written by
  wic (it is only on the first-installation disk, not in the slot image that updates
  write) or by the recipe (the FAT serial number changes at every build).
- **Kernel:** dm-crypt, dm-verity, AES-XTS, SHA-256, loop and zstd squashfs built in
  (`ab-crypt.cfg`).
- **Related decisions:** `systemd.gpt_auto=0` (partitions are mounted only as
  described, never by type); `/home` on the data partition; packages that put files in
  `/var` at build time are covered by the data partition mounted on top (the slot has
  only empty `/var/lib/{dbus,misc,systemd}` and base-files symlinks; systemd recreates
  what is needed).
- **Still open:** BIOS boot (OpenEmbedded does not install GRUB for BIOS in images; step
  4e); data unlocking (step 4d).
- **Checks done (QEMU):** first boot from a new disk, data persistent after reboot,
  signed A/B update to B confirmed by `rauc-mark-good`, interrupted boot of B →
  automatic rollback to A. Repeated for every change to the boot chain (§5).

### D-027 — Processors: baseline x86-64 · `confirmed` (2026-11-11)
- **What:** `DEFAULTTUNE = "x86-64"`: all 64-bit processors (Athlon 64, 64-bit Pentium
  4, Core 2 and later).
- **Why:** R-25, R-28. Accepted cost: slightly lower performance on modern processors.
- **Discarded alternatives:** x86-64-v2 (excludes PCs from before about 2008); 32-bit
  (WebKit on 32-bit is less and less supported, cost too high).

### D-028 — Tools for the build host and the emulator · `confirmed` (2026-11-12)
- **Guide:** `docs/development.md`, for whoever builds from their own PC.
- **Scripts:** `tools/setup-host.sh` (programs for Yocto, kas through pipx, QEMU, OVMF,
  development keys; asks for confirmation before touching AppArmor), `tools/build.sh`
  (development build, update, bitbake shell), `tools/run-qemu.sh` (emulator).
- **Emulator:** QEMU `q35` with OVMF UEFI firmware; **NVMe** disk; copy of the image with
  16 GB free for the data partition; KVM if available, otherwise the `qemu64`
  processor (baseline x86-64, D-027).
- **Recommended build host:** Ubuntu Server 24.04/26.04 LTS. On Ubuntu 24.04 and later
  bitbake needs user namespaces, restricted by AppArmor: the script explains the change
  and asks for confirmation.
- **Snap environments:** started from a snap app (e.g. VS Code installed as a snap),
  QEMU inherits the snap's GTK/GIO variables and does not open its window;
  `tools/run-qemu.sh` removes them when `SNAP` is set.
- **Checks done:** script syntax; run on the user's laptop; window opening checked with
  and without snap variables.

### D-029 — System APIs in the global `system` object · `confirmed` (name and principle), details `proposed`
- **What (R-29):** in the Lua context of every app there is a global **`system`**
  object, with one sub-object per area, like `chrome.*` in extensions. Initial proposal
  of the namespaces:
  | Namespace | Contents |
  |---|---|
  | `system.runtime` | information about the app, background workers and their messages |
  | `system.windows` | create, close, move the app's windows |
  | `system.ui` | the `systemui` component framework (R-34, D-045, D-050) |
  | `system.process` | the app's subprocesses (R-09) |
  | `system.fs` | files outside the app folder, within the granted limits (R-31) |
  | `system.storage` | private, persistent app data |
  | `system.devices` | devices (camera, audio, USB, Bluetooth…) |
  | `system.services` | system services (network, notifications, power…) |
  | `system.dialogs` | native system dialogs (R-10, D-054) |
  | `system.permissions` | granted permissions, requesting new permissions |
  | `system.root` | privileged operations mediated by the broker (R-13, D-005) |
- **Security rule:** a namespace exists in the `system` object only if the app declared
  it in `package.json` and the user granted it; otherwise it is `nil`, like the
  `chrome.*` APIs not declared in the manifest (AGENTS.md §5.1). Web content in web
  views never sees `system` (D-051).
- **Style:** the class and event model (R-35, D-045), with waiting calls that suspend
  the calling coroutine (D-053); errors raised with a code (`PermissionDenied`,
  `NotFound`…).
- **Why `system`:** the user's choice; independent of the final name of the system.
- **To be defined in Phase 4:** full list of functions, in `docs/api/`.

### D-030 — `include()` and `includeAsync()` · `confirmed` (principle), details `proposed`
- **What (R-30), in Lua (D-053):**
  - `include(url)` loads and runs a script and **returns its exports** (the table the
    chunk returns, or its `exports` table); `includeAsync(url)` does the same while
    suspending only the calling coroutine;
  - the included script runs in its own scope (it does not pollute the includer's
    variables) and sees `exports`, `include`, `includeAsync`, `class` and `system`;
  - **cache:** each script is run only once per VM; later inclusions of the same
    address return the same exports;
  - **cycles:** if a script includes another one that is still loading along the same
    chain, the inclusion fails with an `IncludeCycleError` that shows the chain (e.g.
    `app://a.lua → app://b.lua → app://a.lua`). This also applies to `includeAsync`:
    the chain of whoever requested the load is checked, so two asynchronous loads do
    not stay stuck waiting for each other (the user's choice: an error, not partial
    exports as in Node.js).
- **Allowed addresses (proposed):** only `app://`, i.e. the app folder or `.pak` (R-31,
  D-052); relative addresses are resolved against the including script. No scripts
  from the network: remote code must not be able to reach the native APIs
  (AGENTS.md §5.4). Lua's own `require` and `load` of bytecode are not available
  (D-049).

### D-031 — App folder and `app://` protocol · `confirmed` (principle), details `proposed`
- **What (R-31):** each app has an isolated root, a folder or a `.pak` file (D-052); its
  resources are reached with **`app://` followed by the path inside it**, for example
  `app://img/logo.png` or `app://lib/utils.lua`.
- **Only the app accesses its own resources (the user's choice):** the same address in
  two apps points to two different roots; an app has no way to refer to another one's
  resources. Implementation (proposed): the `app://` resolver lives in the native host
  of each app and is bound to its root; a web view of the app gets its own handler bound
  to the same root (D-051).
- **Security rules (proposed):**
  - normalized paths: no `..` or symbolic links that leave the root;
  - app root read-only (it is the installed package); the data the app writes lives
    elsewhere, through `system.storage` or `system.fs`;
  - no `file://`; external files only through `system.fs`, within the permission
    limits;
  - in web views `app://` is registered as a secure context, so the web APIs that
    require it work.

### D-032 — Windows 11, macOS Big Sur, Xiaomi MIUI hybrid design · `confirmed` (requirement), details in Phase 5
- **What (R-32):** the visual style combines the three references; it is defined in
  Phase 5 and recorded in §3.
- **Inspiration, not copying:** visual language and behaviors are taken up, not icons,
  logos, wallpapers or other protected graphic elements of the three systems.

### D-033 — Ecosystem of Luán devices · `proposed` (2026-11-11)
- **What:** a system service in Rust (*continuity daemon*) that connects the devices of
  the same user. Planned features, in priority order (to be confirmed, DA-12):
  1. **pairing** of devices with a QR code or a numeric code; a key pair per device;
     list of trusted devices in Settings;
  2. **sending files and links** between nearby devices;
  3. **shared clipboard**;
  4. the phone's **notifications, calls and text messages** shown and handled on the
     desktop;
  5. **app continuity** (*handoff*): an app picks up on the desktop what was being done
     on the phone and vice versa, through an API of the `system` object (D-029);
  6. **sync** of settings, contacts, calendar, passwords and Wi‑Fi networks;
  7. **instant hotspot** from the phone and **unlocking** the desktop with the phone
     nearby;
  8. later: tablet as a second screen, shared keyboard and mouse.
- **Principles (from the security constraints, AGENTS.md §5):**
  - end-to-end encryption between devices, on a channel authenticated by the pairing
    keys (candidate protocol: Noise); no data in the clear outside the device;
  - **no mandatory cloud**: everything works on the local network and Bluetooth; a
    relay service for distant devices is optional (DA-12);
  - apps reach the ecosystem **only through the broker** and only with the permission
    declared in `package.json` (e.g. `devices.handoff`, `devices.share`);
  - every device can be revoked; revocation invalidates its keys on all the others;
  - protocol with a version number and negotiation, so that devices with different
    Luán versions keep talking to each other (backward compatibility, R-25).
- **Device discovery:** Bluetooth LE for proximity, then local network. Today the
  distribution excludes `zeroconf` (Avahi): to decide whether to re-enable mDNS only for
  this service or to use an own announcement (DA-12).
- **Why:** R-33. It makes sense only with working desktop and mobile, so the phase comes
  after Phase 7; the earlier phases must however plan for it: broker permissions
  (Phase 3), runtime APIs (Phase 4), "Devices" panel in Settings (Phase 6).
- **References to study:** KDE Connect / GSConnect (open protocol with similar
  features), Apple Continuity, Google Quick Share.

### D-034 — Laptop as temporary build host · `confirmed` (2026-11-12)
- **What:** until the full build host exists (DA-11), Phase 1 can be built on the
  user's laptop: Debian 13, 4 cores, 7.4 GB of RAM, 42 GB free. `kas/low-resources.yml`
  sets 2 bitbake tasks and `make -j 3` (at most 6 compilations together, so RAM does
  not run out), `rm_work` (deletes the work files of each finished recipe) and a clean
  stop of the build below 5 GB free. Enabled with `--low-resources` (D-036).
- **Why:** the Phase 1 image should fit in about 30-40 GB with `rm_work` (estimate, to
  be measured at the first build); the first build is long, later ones reuse the
  `sstate` cache.
- **Measured at the first build (2026-11-11):** about 3 hours and 45 minutes of actual
  build, `build/` 26 GB and `sources/` 0.4 GB; RAM never below 3 GB available; `wic`
  image of 8.6 GB nominal (4 GB slots A and B) and 695 MB actually used.
- **Measured in QEMU (2026-11-12):** system 612 MB used in the slot; idle memory in use
  about 70 MB out of 2 GB. Incremental build after a fix: 2-3 minutes.
- **Limitations:** not enough for WPE WebKit and Skia (Phase 2), which want more than
  2 GB of RAM per compilation process and much more disk. DA-11 stays open.
- **Discarded alternative:** a separate preparation script for the laptop:
  `tools/setup-host.sh` already covers Debian 13.

### D-035 — Downloads from the Yocto mirror, no QEMU built by Yocto · `confirmed` (2026-11-12)
- **Problem (first build on the laptop, 2026-11-11):**
  - the `git.yoctoproject.org` git server serves clones at about 17 KB/s, even those
    reduced to the last commit: the `linux-yocto` kernel (several GB) would have taken
    days. The connection is not the cause: from kernel.org downloads run at 13 MB/s,
    from the Yocto HTTP mirror at about 3 MB/s;
  - the `qemuboot` class (included by the machine through `qemuboot-x86.inc` and by
    `kas/dev.yml`) and the `ovmf` recipe made bitbake build QEMU with graphics, hence
    Mesa, LLVM and Clang: hours of compilation and a risk of running out of RAM, for
    tools we do not use.
- **What:**
  - `kas/base.yml`: `PREMIRRORS` maps the `git.yoctoproject.org` repositories to the
    archives of the official mirror `downloads.yoctoproject.org/mirror/sources/`. The
    commit stays the one pinned in the recipe, verified by git; if the archive is older,
    bitbake fetches only the missing commits from the git server;
  - machine and `kas/dev.yml` without `qemuboot` and without `ovmf`: testing uses
    `tools/run-qemu.sh` with the QEMU and OVMF of the build host. The `QB_*` variables,
    which served only `runqemu`, are gone too.
- **Effect:** compilation tasks go from about 838 to 682; `qemu-native` (small, needed
  by the package installation scripts) and `qemuwrapper-cross` remain.
- **Discarded alternatives:** shallow clone (`BB_GIT_SHALLOW`), which stays slow on the
  same server; keeping `runqemu`, which is not needed because there is
  `tools/run-qemu.sh`.

### D-036 — Two build modes: full-performance default, low resources on request · `confirmed` (2026-11-12)
- **What (user's request):** `tools/build.sh` builds by default at full performance
  (`kas/desktop-amd64.yml:kas/dev.yml`, bitbake settings: all cores, work files kept).
  The low-resources mode (`kas/low-resources.yml`, D-034) stays as a second choice and
  is enabled only explicitly with `tools/build.sh --low-resources` or
  `LUAN_LOW_RESOURCES=1`.
- **Resource check:** the script measures RAM and free space. In default mode it warns
  below 15 GB of RAM (a 16 GB PC shows a bit less) and, at the first build, below
  100 GB free (estimate: without `rm_work`; to be measured on the build host); with
  `--low-resources`, below 45 GB free (about 27 GB measured, D-034). From a terminal it
  asks for confirmation, from scripts (CI) it warns and continues.
- **Why:** the repository is public and anyone must be able to reproduce the build
  without help: the recommended configuration is the default, the choices are explicit
  and documented (`docs/development.md` §3, with the equivalent kas commands), errors
  say what to do. A hidden automatic switch made the build less predictable and did not
  reflect the reference machine.
- **Discarded alternatives:** two separate scripts (duplicated checks and keys); a
  dedicated kas file for the default mode (not needed: they are bitbake's settings);
  stopping the build below the threshold (whoever knows what they are doing must be
  able to go on).
- **Checks done:** syntax; with a fake `kas`, all cases (help, unknown option, default,
  update, shell, `--low-resources`, variable, terminal confirmation answered yes and no,
  RAM and disk warnings at the first build); real incremental build in low-resources
  mode.

### D-037 — Repository in English · `requirement` (2026-11-12)
- **What (user's request, AGENTS.md §6):** everything in the repository is written in
  **English**: identifiers, comments, script options and messages, recipes,
  configurations, systemd units, GRUB menu and theme texts, documentation and commit
  messages. Italian only where it is needed for the user's language, that is in
  translation files (language packs) and in the locale lists of the distribution. No
  Italian aliases of options or commands.
- **Why:** the repository is public and must be readable and reproducible by anyone.

### D-038 — Phase 1 cleanup: package inventory, trimming, EFI partition check · `confirmed` (2026-11-12)
- **Why:** AGENTS.md §5.5 requires a recorded reason for every package in the image;
  before it only kernel modules and firmware (D-025) had one. The review also closed
  the checks left open "for the first build" (D-024, D-025, D-026).
- **Removed** (each one checked with a build and a full QEMU test):
  - `busybox-syslog`: second system log next to systemd-journald
    (`VIRTUAL-RUNTIME_base-utils-syslog = ""` in the distribution);
  - `busybox-udhcpc`: second DHCP client, systemd-networkd already does DHCP
    (`BAD_RECOMMENDATIONS`);
  - `kbd-keymaps-pine`: keyboard layouts for Pine64 devices only (`BAD_RECOMMENDATIONS`);
  - `libssh`, `libgcrypt`, `libgpg-error`: pulled only by cryptsetup's LUKS2 SSH token
    plugin, which keeps unlock keys on a remote SSH server (`PACKAGECONFIG:remove =
    "ssh-token"`);
  - volatile bind mounts: `VOLATILE_BINDS = ""`. The `volatile-binds` package stays
    (systemd depends on it) but installs no units; before, its units for `/var/lib`,
    `/var/cache`, `/var/spool` were inactive only because `/var` was already writable,
    and `/srv` was bound to a tmpfs;
  - `/var/volatile` tmpfs line removed from fstab (`base-files` bbappend) and OE's
    `00-create-volatile.conf` masked (`/etc/tmpfiles.d/… → /dev/null`): it made
    `/var/tmp` a link into `/var/volatile` while `/var/log` was already a real
    directory. Both are real directories on the data partition.
- **Added:** `dosfstools` (`fsck.vfat`): `efi.mount` requires
  `systemd-fsck@dev-disk-by\x2dpartlabel-esp.service`, so the EFI partition is checked
  and repaired at every boot before being mounted. GRUB writes `grubenv` there at every
  boot: a power loss can leave the FAT file system dirty (seen during the QEMU tests).
- **Kernel:** `CONFIG_MMC_SDHCI_ACPI=m` and `CONFIG_MMC_SDHCI_PLTFM=m` in `storage.cfg`;
  `do_kernel_configcheck` reports nothing.
- **Inventory of the image** (816 packages: 552 kernel modules and 121 firmware
  packages, reasons in D-025; the other 143 below, grouped by purpose; `-locale-it`
  packages are the Italian translations of each program, installed by
  `IMAGE_LINGUAS`):
  | Purpose | Packages | Reason |
  |---|---|---|
  | Kernel | `kernel-base`, `kernel-modules` (meta-package of the modules) | the Linux kernel's modules; the kernel itself is on the EFI partition, in each slot's boot files (D-014, D-048) |
  | Hardware | `packagegroup-luan-desktop-hw`, `wireless-regdb-static` | firmware group and Wi‑Fi regulatory database (D-025) |
  | Boot | `grub-efi`, `grub-common`, `grub-bootconf`, `grub-editenv`, `grub-locale-it` | GRUB boot menu (D-009); `grub-editenv` for RAUC (D-026) |
  | Init and devices | `systemd`, `systemd-conf`, `systemd-extra-utils`, `systemd-udev-rules`, `systemd-vconsole-setup`, `systemd-serialgetty`, `systemd-mime`, `udev`, `udev-hwdb`, `kmod`, `libkmod2`, `libsystemd0`, `libsystemd-shared`, `libudev1`, `libseccomp`, `libnss-myhostname2`, `libnss-resolve2`, `libnss-systemd2`, `volatile-binds` | systemd as init (D-016) and its direct dependencies; `systemd-serialgetty` for the serial console |
  | Network | `systemd-networkd`, `netbase` | network configuration (DHCP included); protocol and service tables |
  | IPC | `dbus-1`, `dbus-common`, `dbus-tools`, `libdbus-1-3`, `libexpat1` | D-Bus, needed by systemd and by RAUC's service |
  | Encryption and storage | `cryptsetup`, `systemd-crypt`, `libdevmapper`, `luan-storage`, `e2fsprogs-mke2fs`, `e2fsprogs-e2fsck`, `libext2fs2`, `libe2p2`, `libcom-err2`, `dosfstools`, `util-linux-fsck`, `util-linux-mount`, `util-linux-umount`, `libmount1`, `libblkid1`, `libfdisk1`, `libsmartcols1`, `libuuid1` | LUKS2 data partition, repart, mounts and file system checks (D-026, D-038) |
  | Updates | `rauc`, `rauc-conf`, `rauc-service`, `rauc-mark-good`, `libglib-2.0-0`, `libjson-glib-1.0-0`, `libnl-3-200`, `libnl-genl-3-200`, `libcurl4`, `libnghttp2-14`, `libidn2-0`, `libunistring5`, `libffi8`, `libpcre2`, `shared-mime-info`, `shared-mime-info-data`, `libxml2` | signed A/B updates (D-018, D-026). `libcurl` (with `nghttp2`, `idn2`) and `libnl` come from RAUC's default `network` and `streaming` features: kept for installing updates directly over HTTPS (Phase 8); `shared-mime-info` and `libxml2` are required by GLib |
  | Crypto and certificates | `libssl3`, `libcrypto3`, `openssl`, `openssl-bin`, `openssl-conf`, `ca-certificates` | bundle signature checking (RAUC), HTTPS for updates; certificate authorities for HTTPS |
  | Login and accounts | `libpam`, `libpam-runtime`, `pam-plugin-*` (deny, env, faildelay, group, keyinit, limits, loginuid, mail, motd, namespace, nologin, permit, rootok, securetty, shells, umask, unix, warn), `shadow-base`, `shadow-securetty`, `util-linux-agetty`, `util-linux-sulogin`, `libcrypt2` | authentication (`pam` distribution feature, logind), text login, emergency shell |
  | Console | `kbd`, `kbd-keymaps`, `kbd-consolefonts`, `keymaps` | keyboard layouts and fonts of the text console |
  | Base system | `base-files`, `busybox`, `os-release`, `ldconfig`, `libc6`, `libgcc1`, `libstdc++6`, `libacl1`, `libattr1`, `libz1`, `libzstd1`, `liblzma5`, `libpopt0`, `libjson-c5`, `util-linux-flock`, `packagegroup-core-boot` | file system layout and basic tools (BusyBox, until our own shell exists), C/C++ runtime, compression libraries, dependencies of the packages above |
  | Swap tools | `util-linux-mkswap`, `util-linux-swapon`, `util-linux-swapoff`, `util-linux-swaponoff` | hard dependency of systemd; no swap is configured today (to be decided with the memory budget) |
  | Locales | `locale-base-it-it`, `locale-base-en-us`, `glibc-locale-it` | Italian and English for the users (§6 of AGENTS.md allows Italian here) |
- **Measured (QEMU, 2026-11-12):** system 610 MB in the slot (612 MB before), idle
  memory in use about 77 MB out of 2 GB.
- **Checks done:** three builds (low-resources mode), full QEMU test from a new disk:
  first boot (`running`, no failed units, EFI partition checked, data partition
  created), A/B update to B confirmed by `rauc-mark-good`, boot of B interrupted by a
  reset → automatic rollback to A, EFI partition clean after the reset.
- **Seen, not fixed (noted in ROADMAP):** `dbus-daemon: Failed to drop supplementary
  groups: Operation not permitted` at every boot, harmless so far; RAUC's "No bootable
  slot found" message during `rauc-mark-good`, expected (the slot is marked as tried
  until it is confirmed); the kernel warns that the GPT backup header is not at the end
  of the disk on the first boot in QEMU (the emulator disk is enlarged after the image
  is written).

### D-039 — Intel SOF audio firmware from sof-bin · `confirmed` (2026-11-12)
- **What:** own recipe `sof-bin` (`layers/meta-luan-desktop/recipes-bsp/sof-bin/`),
  version 2026.09.2, from the official releases of the SOF project
  (`github.com/thesofproject/sof-bin`), added to `packagegroup-luan-desktop-hw`.
  The tarball is pinned by SHA-256, the same digest GitHub publishes for the release
  asset. Installed in `/lib/firmware/intel` with the upstream layout (`sof`,
  `sof-ipc4`, `sof-ipc4-lib`, `sof-ipc4-tplg`, `sof-tplg`, `sof-ace-tplg` link).
- **Why:** R-04. Internal speakers and microphones of most Intel laptops from the 11th
  generation on go through the audio DSP, which needs this firmware; the kernel drivers
  were already enabled (D-025). linux-firmware 20260410 contains only the older `avs`
  firmware, not SOF.
- **Left out (R-02):** the debugging tools (`tools/`: sof-logger and others), the
  debug-log dictionaries (`*.ldc`, read only by sof-logger), the topologies for NXP
  i.MX and MediaTek ARM DSPs and the AMD topologies (the AMD driver looks in `amd/`, and
  sof-bin has no AMD firmware). Only the Intel licence remains (BSD-3-Clause with
  Intel's patent grant); the NXP licence covered only the i.MX files.
- **Compression:** every file compressed with zstd like the rest of the firmware
  (D-025); symbolic links re-pointed to the `.zst` names, repeating until nothing
  changes because some links point to other links (e.g. `arl` → `mtl`); the build
  stops if a broken link remains. Result: 570 files and 70 links, 17 MB installed
  (about 57 MB uncompressed), 12.7 MB package.
- **AMD:** the kernel also enables SOF for recent AMD laptops (Rembrandt, ACP 6.3/7.0),
  but neither linux-firmware 20260410 nor sof-bin ships AMD SOF firmware. Most AMD
  laptops use the ACP drivers without SOF; to be checked on real hardware.
- **Updates:** a new sof-bin release is a new recipe version with its new digest; the
  release notes of the SOF project are part of vulnerability monitoring (D-012).
- **Discarded alternatives:** using upstream `install.sh` (it installs the tools and
  needs rsync); installing only the platforms enabled in the kernel (saves little and
  is easy to get wrong when new platforms are enabled).
- **Checks done:** package contents (all files compressed and valid zstd, no broken
  links, no `.ldc` or ARM files); image boots in QEMU (`running`, no failed units) with
  the firmware in `/lib/firmware/intel`; system 627 MB in the slot (610 MB before),
  idle memory unchanged (about 76 MB). Real
  check on an Intel laptop in the hardware test session (ROADMAP step 6.8, D-040; QEMU
  has no audio DSP).

### D-040 — Real hardware checks in one test session · `requirement` (2026-11-12)
- **What (user's request):** the checks that need real PCs (QEMU cannot do them: audio
  DSP, Wi‑Fi, Bluetooth, GPUs, laptop platform, BIOS and Windows dual boot, TPM…) are
  not done step by step: they are gathered in a list, step 6 of Phase 1 in
  `ROADMAP.md`, and done all together in one session, after steps 3b–5b.
- **How to apply:** every step that leaves something to check on real hardware adds a
  row to the step 6 table (check, hardware needed, originating step or decision) and
  says so in its own entry; the step itself is closed when its QEMU checks pass.
- **Why:** fewer sessions on physical machines, the same image tested on all of them,
  and a single place to see what is still unproven.

### D-041 — Kernel options checked against the final configuration; VM guests and laptop GPIO/I2C · `confirmed` (2026-11-12)
- **Problem (found while reviewing the video drivers):** some options of our fragments
  never reached the kernel, and no check noticed:
  - `DRM_VMWGFX` (VMware) and `DRM_HYPERV` (Hyper‑V) depend on `HYPERVISOR_GUEST`,
    which was off;
  - `I2C_DESIGNWARE_PLATFORM`, the I2C controller of the touchpads and touchscreens of
    most recent laptops, depends on `I2C_DESIGNWARE_CORE`, which was off; on top of
    that `GPIOLIB` and every Intel/AMD pin-control driver were off, so touchpad
    interrupts, buttons and sensors on GPIO lines could not work.
  `do_kernel_configcheck` does not report options dropped for a missing dependency, and
  `tools/check-kernel-fragments.py` checks only names and types (D-025).
- **What:**
  - new task `do_luan_configcheck` in the kernel bbappend, after
    `do_kernel_configcheck` and before `do_compile`: every `CONFIG_…` line (and every
    "is not set") of our fragments must be in the final `.config` with the same
    value, otherwise the build stops listing file, line, requested and actual value;
  - new fragment `virt-guest.cfg`: `HYPERVISOR_GUEST`, paravirtualization and KVM guest
    support; Hyper‑V core, VMBus and synthetic disk built in (`=y`: Generation 2 VMs
    boot from it and there is no initramfs), network, integration services, balloon,
    mouse and keyboard; VMware paravirtual SCSI built in, vmxnet3, VMCI, balloon;
  - `input-platform.cfg`: DesignWare I2C core, platform and PCI front ends, Intel LPSS
    (PCI and ACPI, plus the LPSS clocks of older Atom devices), `GPIOLIB` and the
    pin-control drivers built in (`=y`, so GPIO interrupts exist when I2C-HID devices
    are probed) for AMD and for consumer Intel platforms from Haswell/Bay Trail to
    Meteor Lake and the generic platform driver of newer ones; server platforms left
    out.
- **Checks done:** `tools/check-kernel-fragments.py`: 200 options, 0 errors; the new
  task finds all of them in the final configuration; `do_kernel_configcheck` reports
  nothing. QEMU: system `running`, no failed units, "Hypervisor detected: KVM" and
  kvm-clock in use, the new modules (`vmwgfx`, `hyperv_drm`, DesignWare I2C, Intel
  LPSS) in the image; system 629 MB, idle memory about 76 MB after a normal boot
  (104 MB right after the first boot, which creates and encrypts the data partition).
  Touchpads, buttons and VMware/Hyper‑V are checked in the hardware test
  session (ROADMAP step 6.14 and 6.20, D-040).
- **Discarded alternatives:** raising `KCONF_AUDIT_LEVEL` of linux-yocto (it reports
  many options of yocto-kernel-cache that are not ours, and only as warnings); a
  separate script to run by hand (it would be forgotten, like the dependency check).

### D-042 — Plan of step 3b + 4c: initramfs, persistent /etc, erofs + dm-verity, UKI · `confirmed` (choices of the user, 2026-11-12), details `proposed`
- **Sub-steps**, each tested in QEMU with boot, A/B update and rollback:
  1. **4c.1** systemd initramfs, with Intel (new recipe, from Intel's official files)
     and AMD microcode loaded early (**3b**);
  2. **4c.2** persistent `/etc`;
  3. **4c.3** erofs system verified by dm-verity (a corrupted block stops the boot);
  4. **4c.4** unified kernel image (UKI) per slot.
- **`/etc` (user's choice):** an **overlay** — the `/etc` of the image stays read-only
  as the lower layer, changes go to an upper layer on the encrypted data partition,
  mounted by the initramfs. Against the known risk (a modified file hides the new
  version brought by an update), every update compares the changed files with the new
  image and reports the conflicts. Discarded: stateless `/etc` (every program that
  writes to `/etc` would need its own configuration).
- **UKI and BIOS (user's choice):** for each slot the EFI partition holds both a UKI
  (UEFI, ready for Secure Boot in Phase 8) and separate kernel + initramfs (used by
  GRUB when the PC boots from BIOS, R-26); RAUC updates them together with the slot.
  Cost: about 2 × 40 MB more on the 512 MB EFI partition. Discarded: separate kernel
  only until Phase 8 (the UKI would come later, with a second change of the boot
  chain).

### D-043 — systemd initramfs and early microcode (steps 4c.1 and 3b) · `proposed` (2026-11-12, on the `build/verified-boot` branch)
- **initramfs** (`luan-initramfs`, in `meta-luan`): systemd in initrd mode
  (`/init` → systemd, `/etc/initrd-release` from `os-release`). It opens the slot with
  dm-verity (D-047), checks and mounts it on `/sysroot`, prepares the data partition and
  the `/etc` overlay (D-044) and switches to it. Packages: `systemd`, `udev`, udev
  rules, `mount`, `fsck`, `e2fsck`, `os-release`, BusyBox, without recommendations;
  systemd's hard dependencies (PAM, D-Bus, OpenSSL, kbd, cryptsetup libraries…) come
  along. `cpio.zst`: about 19 MB — to be slimmed in the size budget.
- **Microcode** (`luan-microcode`, in `meta-luan-desktop`): builds
  `microcode.cpio`, an uncompressed archive with `kernel/x86/microcode/GenuineIntel.bin`
  (all of `intel-ucode/` from Intel's official release `microcode-20261110`, pinned to
  the commit of its tag; `intel-ucode-with-caveats/` left out, as Intel advises) and
  `AuthenticAMD.bin` (the `amd-ucode` containers of linux-firmware 20260410, the same
  file and digest as OE-Core's recipe). Reproducible: fixed times and owner, sorted
  entries. 19.5 MB.
- **Boot:** the machine lists early archives in `LUAN_EARLY_INITRD`; they are put
  uncompressed and first, before the initramfs, in each slot's UKI and in the BIOS boot
  files on the EFI partition (D-048): the kernel finds the microcode at the start of
  the first archive, as early loading requires.
- **Not in the image:** `linux-firmware-microcode-amd` (late loading is not needed).
- **Why:** microcode loaded early fixes processor bugs and vulnerabilities before any
  code runs (late loading is unsafe on many processors); the initramfs is needed for
  the encrypted `/etc` overlay and dm-verity.
- **Discarded alternatives:** OE's shell-based `initramfs-framework` (a second init
  system to maintain, while systemd already handles fsck, crypttab and veritysetup);
  `iucode-tool` to build the Intel file (concatenation is what the kernel loader
  expects, no extra tool needed); microcode built into the kernel
  (`CONFIG_EXTRA_FIRMWARE`, it would tie every microcode update to a kernel rebuild).
- **Checks done (QEMU):** boot through the initramfs ("Switching root" at about 2 s),
  system `running`, no failed units; A/B update and rollback. In a virtual machine the
  kernel skips microcode updates (the hypervisor handles them): the real check is in
  the hardware test session (ROADMAP step 6.17, D-040).

### D-044 — Persistent /etc overlay, data partition handled by the initramfs (step 4c.2) · `proposed` (2026-11-12, on the `build/verified-boot` branch)
- **Data partition in the initramfs:** `/etc` is needed before the system starts, so
  creation, unlocking and mounting of the data partition move from the system to the
  initramfs (package `luan-storage-initrd`, added by the machine through
  `LUAN_INITRD_INSTALL`):
  - `luan-repart.service`: after `/sysroot` is mounted, `systemd-repart
    --root=/sysroot` reads the partition definition of the system
    (`/usr/lib/repart.d/50-data.conf`, which stays in one place) and works on the disk
    of the slot. systemd's own initrd repart service looks inside the initramfs and
    runs before `/sysroot`, so it does nothing here; on the system it is masked;
  - `crypttab` in the initramfs, `systemd-cryptsetup@data` after repart;
  - `sysroot-var.mount`: fsck of the data partition, then mount on `/sysroot/var`; the
    mount stays after the switch as `/var`. The system itself has no `crypttab` or
    `var.mount`.
- **`/etc` overlay** (`luan-etc-overlay.service`, before `initrd-fs.target`):
  lower layer the read-only `/etc` of the slot, upper and work directories in
  `/var/lib/luan/etc-overlay/` on the encrypted data partition. Kernel:
  `CONFIG_OVERLAY_FS=y` (built in, no modules in the initramfs). BusyBox added to the
  initramfs (`mkdir`, and `/bin/sh` for the emergency shell).
- **Update conflicts** (`/usr/lib/luan/etc-overlay-conflicts`, RAUC
  post-install handler): mounts the booted slot without the overlay (non-recursive
  bind mount of `/`) and the new slot read-only, and for every file changed or deleted
  locally (upper layer) checks whether the update changes it; the list goes to
  `/var/lib/luan/etc-conflicts` and to RAUC's log. The local version is kept; the
  update never fails because of it.
- **`ldconfig.service` masked:** with a writable `/etc` it wrote `ld.so.cache` into the
  overlay, a copy that could go stale after an update and hide the cache of the new
  slot. The image already has the right cache. systemd's other "needs update" services
  stay (e.g. `systemd-sysusers` adds new system users after an update even if
  `/etc/passwd` was changed locally).
- **Checks done (QEMU, new disk):** first boot creates, unlocks, checks and mounts the
  data partition and the overlay before the switch, system `running`; host name, a new
  user, a network file and an edit of `/etc/issue` survive a reboot; RAUC runs the
  handler during the update (empty report, no differences in a same-build bundle); a
  change to `/etc/issue` written into slot B is reported as a conflict; slot B boots
  with all local changes and keeps the local `/etc/issue`; interrupted boot of B →
  rollback to A with all changes. Slot 665 MB, initramfs 19.3 MB, idle memory about
  81 MB.
- **Memory of the key derivation:** the empty key that systemd-repart creates uses
  Argon2i with up to 893 MB of RAM (2 GB VM); it is removed when the password is set,
  and the password's derivation has a memory limit for old PCs (R-25, D-058).
- **Discarded alternatives:** keeping repart and unlocking in the system and mounting
  the overlay later (programs read `/etc` from the first moment); one mount unit for
  the overlay (its directories must exist first, a mount unit cannot create them).

### D-045 — `systemui` component framework and class/event model of the APIs · `requirement` (R-34, R-35, R-36), details `proposed`
- **What the user fixed:** `system.ui.*` is our UI framework (R-34), drawn natively
  (D-050) and used from Lua or XML (R-40, D-053); an app declares `systemui` in
  `package.json` to use it; built-in components (buttons, headers, footers, text
  fields…) plus custom components; no HTML; classes and events. The other `system.*`
  APIs use the same class and event model (R-35).
- **First reading of the design (to be defined in Phase 4, `docs/api/ui.md`):**
  - a base class (`system.ui.Component`) that every component extends, built-in and
    custom alike: it owns its node of the framework, its children and its listeners;
    removing a component removes its subtree and releases listeners and resources, so
    apps do not leak memory or leave orphan nodes;
  - events with one uniform interface on components and APIs (`on(name, handler)` /
    `off(name, handler)`); waiting calls suspend the calling coroutine (D-053);
  - the visual style of Phase 5 (D-032) applied by default, so apps look like the
    system without styling code; themes and light/dark from the system;
  - security rule of D-029: `system.ui` exists only if `systemui` is declared in
    `package.json`; the framework gives no extra native access;
  - exact name and form of the `package.json` field defined with the manifest
    specification (`docs/manifest.md`).
- **Consequences:** the system dialogs (R-10), the shell (Phase 5) and the system apps
  (Phase 6) are built with `systemui` (D-054); so the framework comes before the shell.
- **Developer guide (R-36):** `docs/systemui/`, in English (AGENTS.md §6): an index
  (`README.md`) linking every page; getting started (declaring `systemui` in
  `package.json`, first window, in Lua and in XML); one page per component with
  purpose, properties, XML attributes, methods, events and examples; pages on custom
  components and on the component lifecycle (tree, removal). Each component ships with
  its page, so code and guide stay in step. The other `system.*` APIs get the same kind
  of guide in `docs/api/` (the user's choice, R-36): one page per namespace
  (`system.fs`, `system.windows`…) with its classes, methods, events, the permission to
  declare in `package.json`, errors and examples.
- **Why:** the user's choice; a single way to build interfaces for us and for
  third-party developers, consistent look, no low-level drawing in app code.

### D-046 — Code style checked by standard tools · `requirement` (AGENTS.md §7, 2026-11-12), details `proposed`
- **What (user's request):** standard naming and style conventions of every language,
  readable layout, comments that explain the why, written into `AGENTS.md` §7 as a fixed
  rule; all the code written so far reviewed against them.
- **Tools** (run together by `tools/lint.sh`, installed by `tools/setup-host.sh` through
  pipx, no root needed): ShellCheck (`shellcheck-py`, `.shellcheckrc`), ruff for PEP 8
  and PEP 257 (`ruff.toml`), oelint-adv for the OpenEmbedded style guide
  (`tools/oelint-constants.json` declares the RAUC and Luán variables it does not
  know). Rust (`cargo fmt`, `clippy`), Luau (StyLua, selene,
  `luau-analyze`), XML layouts (schema validation) and JavaScript (ESLint, Prettier)
  are run as soon as the repository has code in that language (AGENTS.md §7).
  `tools/lint.sh` checks the files tracked by git: new files are added (`git add`)
  before running it, otherwise they are skipped (a ShellCheck finding in a new script
  of step 4d was found only in step 4e this way).
- **oelint-adv rules left out**, each with its reason in `tools/lint.sh`:
  `suggestedvar.SECTION/BUGTRACKER/CVE_PRODUCT` and `bbclassextend` (meant for
  recipes of software published elsewhere), `licenseremotefile` (our recipes have no
  upstream license file). Single exceptions are marked in the recipe with
  `# nooelint:` and the reason (bundle without sources, generated `grubenv`, two
  download sources of the microcode, kernel check task without override).
- **Review of the existing code (2026-11-12):**
  - shell: ShellCheck clean; script-level variables that change renamed to
    `lower_snake_case` (`reset`, `text_mode`, `userns_restriction`);
  - Python: descriptive names instead of one-letter ones, PEP 257 docstrings, ruff
    formatting; `branding/tools/render.py` checked by regenerating the theme images:
    all 19 identical, pixel by pixel;
  - BitBake: multi-line values without leading space (except `:append`, where it is
    needed), descriptions within 88 columns, `HOMEPAGE`, alphabetical dependencies,
    `DEPENDS +=`, `${localstatedir}`, `[doc]` for every custom task and function,
    recipe files with a version (`luan-storage_1.0.bb`,
    `luan-boot-config_1.0.bb`); **bbappends limited to our distribution or
    machine** (`:luan`, `:luan-amd64`), so the layers stay usable next to
    others ("Yocto Project compatible" rule). Final values of 23 affected variables
    compared before and after: same effect (only order and wording differ).
- **Why:** the repository is public and must be understandable by any developer; tools
  make the rule checkable instead of a matter of taste.

### D-047 — erofs system verified by dm-verity (step 4c.3) · `confirmed` (2026-11-12, on the `build/verified-boot` branch)
- **Slot image:** the system is an **erofs** image (lz4hc, D-048) with the **dm-verity
  hash tree appended** (`erofs-lz4hc.verity`), made by meta-oe's `image_types_verity`
  (no verity superblock, salt fixed in the machine as `VERITY_SALT`: the same system
  always gives the same root hash). wic copies that file into slot A (`rawcopy`), and
  the update bundle writes the same file into the inactive slot (RAUC slot
  `type=raw`). Kernel: `CONFIG_EROFS_FS=y`.
- **Root hash:** in the kernel command line of each slot's boot files on the EFI
  partition (the UKI and `boot.env`, D-048), generated at build time by
  `luan_slot_boot.bbclass` from the parameters of `image_types_verity`.
- **Kernel command line:** `root=/dev/mapper/root rootfstype=erofs roothash=…
  systemd.verity_root_data=PARTLABEL=root_x systemd.verity_root_hash=PARTLABEL=root_x
  systemd.verity_root_options=…`: systemd-veritysetup-generator in the initramfs
  (already there with systemd's `cryptsetup` feature) opens the slot before mounting
  it.
- **Updates:** the bundle hook (`luan-bundle-hook`, `slot-post-install`) writes the
  slot's boot files (D-048). RAUC runs slot hooks after writing the slot and **before**
  marking it bootable, while the system post-install handler runs only after the
  marking (checked in RAUC 1.15.2's source): if the hook fails, the slot stays not
  bootable. The `/etc` conflict handler mounts the new slot with `-t erofs`, without
  dm-verity (just written from the signed bundle).
- **Corrupted block:** dm-verity's default answer, a read error. A system file that
  does not match the tree is not run; the boot stops, and `systemd.crash_action=reboot`
  (the user's choice) restarts the PC after 10 s when PID 1 cannot go on, so GRUB moves
  to the other slot by itself after the slot's 3 attempts (D-058). Discarded: staying frozen with
  the message on screen (a PC far from its user would wait forever).
- **Boot menu tracked by the build:** `grub.cfg` reaches wic only through the
  `bootloader --configfile` line, which bitbake does not track; the machine adds the
  file to `do_image_wic[file-checksums]`, through `LUAN_DESKTOP_LAYERDIR` set in
  `layer.conf`.
- **Discarded alternatives:** ext4 with dm-verity (it works only if ext4 never tries
  to write, e.g. no journal replay; erofs is read-only by design and has no unused
  free space in the image); separate hash partitions per slot (a different partition
  layout and a tree over the whole partition, not just over the image); root hash in
  `grubenv` (it would mix RAUC's state with the slot's data, and GRUB rewrites
  `grubenv` at every boot); writing boot data from the system post-install handler (it
  runs after RAUC has already marked the slot bootable); `panic-on-corruption` /
  `restart-on-corruption` (with a corrupted block read only later, after
  `rauc-mark-good`, the PC would restart over and over).
- **Not covered yet:** the root hash and the boot files on the EFI partition are
  protected only by root-only access, like `grubenv` and `grub.cfg`: the chain is
  trusted only from Secure Boot on (Phase 8).
- **Checks done (QEMU, new disk):** host check of the tree (`veritysetup verify`); boot
  of A with `/dev/mapper/root` *verified*, A/B update to B verified and confirmed,
  interrupted boot of B → A; one corrupted block in B (inside
  `/usr/lib/systemd/systemd`), one `reboot` and no other action: B stops, the PC
  restarts twice by itself and A reaches the login; a new installation of the bundle
  repairs B.

### D-048 — Unified kernel image per slot on the EFI partition, lz4hc slots (step 4c.4) · `confirmed` (2026-11-12, on the `build/verified-boot` branch)
- **Boot files out of the slot:** each slot's boot files live on the EFI partition, in
  `EFI/luan/A` and `EFI/luan/B`, built by `luan_slot_boot.bbclass`
  as `<image>.slot-boot/`:
  - `luan.efi`: **unified kernel image (UKI)** made with `ukify` (systemd 259):
    systemd-boot stub, kernel, CPU microcode then initramfs (the microcode must be
    first and uncompressed), `os-release`, and the kernel command line with the
    dm-verity root hash. GRUB starts it with `chainloader … @0` (slot A) or `@1`;
  - `bzImage`, `microcode.cpio`, `initramfs.cpio.zst` and `boot.env` (GRUB
    environment block, 2048 bytes, with `cmdline_a` and `cmdline_b`): the same as
    separate files, for GRUB when the PC boots from BIOS (step 4e, R-26).
  The slot holds no kernel (`kernel-image` removed from the image; the machine drops
  `kernel-base`'s recommendation of it, which the modules brought in).
- **Two profiles in one UKI (multi-profile, systemd-stub 257+):** the same system can
  be installed in either slot, and the command line must name the slot's partition
  (`PARTLABEL=root_a`/`root_b`, `rauc.slot`). The UKI itself is profile 0, slot A (its
  own `.cmdline`), and the profile of slot B is joined as profile 1. The stub reads the
  `@N` argument even with Secure Boot, where any other argument from the loader is
  ignored, so the line that runs is always the one in the (future signed) UKI.
  Profile 0 is also what runs if the UKI is started with no argument. Found while
  building: joining both slots as separate profiles makes `ukify` add an empty base
  profile (`ID=main`, no command line) as `@0`.
- **One command line, from the build:** `LUAN_KERNEL_CMDLINE` in the machine, with
  the reason of each option; the class adds root hash, tree parameters and the slot's
  part. `grub.cfg` composes no kernel options: it reads `cmdline_x` from each slot's `boot.env` (only that name) and never chooses a
  slot without it.
- **GRUB reads only the EFI partition:** no `erofs` or `regexp` module in
  `GRUB_BUILDIN`; wic puts no kernel at the root of the EFI partition (`install-kernel-into-boot-dir=false`).
- **Updates:** the bundle carries the `slot-boot` directory; the hook (slot
  post-install, before RAUC marks the slot bootable) removes the old files of that
  slot, copies the new ones to `<bootname>.new` and renames it. Removing first keeps
  the EFI partition at two sets of boot files plus the one being written.
- **lz4hc erofs (the user's choice, 2026-11-12):** GRUB does not read the slot (its
  erofs driver refuses compressed images), so the slot can be compressed. Measured on the system without `/boot`: uncompressed
  600 MB, lz4hc 472–483 MB, lzma 444 MB (397 MB are firmware already compressed with
  zstd). lz4hc: fast decompression even on old processors (R-25), the usual choice of
  erofs (Android); lzma discarded (10–20 times slower to decompress), zstd not
  available in the erofs-utils of the build. Default 4 KiB clusters (483 MB against
  472 MB with 64 KiB): a random read decompresses one block at most. Kernel:
  `CONFIG_EROFS_FS_ZIP=y`. The decompressor only reads data already verified by
  dm-verity.
- **Discarded alternatives:** one UKI per slot built twice (two signed files of 52 MB
  in every bundle instead of one); root partition found from the root hash (systemd's
  convention: GPT partition UUID = first half of the hash; it would mean editing the
  partition table at every update, and two slots with the same system would share a
  UUID); OE's `uki` class (a single initrd, so no early microcode, and a single
  command line); GRUB passing the slot's options to the UKI (ignored with Secure
  Boot).
- **Sizes:** slot 512 MB (507 MB erofs + tree); UKI 52 MB; boot files per slot 104 MB;
  EFI partition with both slots 199 MB of 511 MB; bundle 584 MB (system and boot
  files).
- **Still open:** the slot's `/boot` keeps `EFI/BOOT/bootx64.efi` and `grub.cfg` from
  the `grub-efi` package, not used (GRUB on the EFI partition is written by wic) — to
  remove with the size budget; GRUB and `grub.cfg` on the EFI partition are not
  updated by RAUC yet; signing of UKI and GRUB with Secure Boot in Phase 8.
- **Checks done (QEMU, new disk, 2026-11-12):** UKI sections checked (base `.cmdline`
  slot A, profiles `slot-a` and `slot-b`, the second with its own `.cmdline`). Slot A
  boots through the UKI (no `BOOT_IMAGE=` from GRUB), `/dev/mapper/root` verified on
  `nvme0n1p3`, erofs lz4hc, system `running`, no failed units, free memory as before
  (about 1.87 GB of 2 GB). A/B update: the hook writes `EFI/luan/B`, B boots with
  profile `@1` of its own UKI (`root_b`, `rauc.slot=B`) and is confirmed. Interrupted
  boot of B → A. One corrupted block in B (block 119138, the first compressed block of
  `/usr/lib/systemd/systemd`), B re-armed, one `reboot`: the firmware starts twice by
  itself and A is at the login in 42 s; from A, `veritysetup verify` of B fails
  exactly at that block. BIOS path tried from GRUB's command line on UEFI
  (`linux …/A/bzImage $A_CMDLINE`, `initrd` microcode + initramfs): boots, verified,
  `running`.

### D-049 — Native application model, Luau as the main language · `requirement` (R-37, 2026-11-13), Luau `confirmed` (the user's choice, 2026-11-13), details `proposed`
- **What:** the main script of every app, of the shell and of the system interfaces is
  Lua, run by **Luau** (the Lua dialect made by Roblox for untrusted code, MIT
  license), embedded in a native host in Rust through the `mlua` crate (D-013). One Luau
  VM per app process, created empty: only the granted `system` namespaces (D-029) and
  the language's safe standard library are in it.
- **Why Luau (the user's choice, among Luau, Lua 5.4 and LuaJIT):**
  - **made for sandboxing:** no `io`, `os.execute`, `debug` or file loading in the
    language; `luaL_sandbox` makes built-in libraries and globals read-only, so one
    script cannot change what another one sees;
  - **backward compatibility as a policy** (R-25): Luau does not break existing code
    between versions, while PUC Lua changes semantics between minor versions
    (5.1 → 5.2 → 5.3 → 5.4);
  - optional **types** (`--!strict`) checked by `luau-analyze`: large apps and the
    framework API are checked before they run;
  - fast interpreter without a JIT: no writable and executable memory needed (W^X
    stays on). Luau's optional native code generation stays **off** (to be measured
    later, only for system code if ever).
- **Security rules (proposed):** only Lua **source** is loaded, never bytecode supplied
  by the app (bytecode is not verified by the VM); the host compiles and may cache the
  bytecode itself, outside the app's reach. A memory limit and an interrupt callback
  per VM stop runaway scripts. Web content never reaches the VM (AGENTS.md §5.4,
  D-051).
- **Process model (proposed):** one process per app (R-09: subprocesses stay), one
  main thread that runs the Lua VM and the UI of its windows (D-050); background work in
  separate VMs (`system.runtime` workers) that exchange only copied messages, no shared
  Lua state. Windows are native and belong to the app's process (R-09).
- **Discarded alternatives:** Lua 5.4 (standard, but breaking changes between minor
  versions, R-25); LuaJIT (fastest, but stuck at Lua 5.1 and its JIT needs writable and
  executable memory); JavaScript on JavaScriptCore (R-37: the main language is Lua).

### D-050 — Graphics framework on EGL + OpenGL ES, drawn with Skia · `requirement` (R-38, EGL, 2026-11-13), details `proposed`
- **What:** the framework that draws the components of `systemui` (R-34) in every
  app, in the shell and in the system dialogs. Layers, from the bottom:
  1. **Wayland + EGL + OpenGL ES 2.0/3.x**: Mesa on desktop, the Android drivers
     through libhybris on mobile (D-014); the app draws into its own Wayland surface;
  2. **Skia** (Ganesh GL backend, Rust bindings `skia-safe`) for shapes, images,
     gradients, blur, text; **CPU raster fallback** in Skia when there is no usable
     GPU (virtual machines, old PCs, R-25), the same drawing code;
  3. **text:** Skia's paragraph module with HarfBuzz and ICU (shaping, bidirectional
     text, line breaking), fonts through fontconfig;
  4. **layout:** flexbox and grid with the `taffy` crate;
  5. **our components**, input (mouse, touch, keyboard, gestures), focus, animations
     (property animations with curves and springs, run on the frame clock of the
     compositor) and accessibility (`accesskit` crate) — written by us, in Rust, with
     the Lua API on top.
- **Why Skia:** the same 2D engine of Android, Chrome and Flutter, so it runs on the
  same GPUs and drivers we target on both devices; mature text; long fuzzing history
  (R-14); a CPU path for hardware without GPU acceleration.
- **Discarded alternatives:** own renderer directly on GLES (antialiasing, text and
  blur are years of work); `femtovg` (light, but less complete text and effects);
  `vello` and Skia Graphite (need Vulkan or compute shaders: they would exclude older
  GPUs and many phone drivers, R-25).
- **Costs and risks:** Skia is a large C++ build (gn and ninja, inside a Yocto recipe:
  `skia-safe` must build from source, never download prebuilt binaries); on mobile the
  EGL path through libhybris is the main technical risk (Phase 7 feasibility check,
  for the framework and WPE together).
- **Compositor (D-007):** the shell is a native app of the framework (D-054) that draws panels and decorations through *layer-shell*, and the
  private compositor ↔ shell protocol stays.

### D-051 — WPE WebKit for web views and the browser, on both targets · `confirmed` (the user's choice, 2026-11-13)
- **What (R-41):** web content is shown with **WPE WebKit**, the WebKit port made for
  embedding without GTK, instead of WebKitGTK. Through its platform API (WPEPlatform,
  the stable default since 2.54) it hands its frames to the embedder as GPU buffers
  (`WPEBufferDMABuf` on desktop, `WPEBufferAndroid` on Android), which the framework
  draws as a texture inside its own scene (D-050): a `WebView` component like any
  other, with no GTK in the image. How WPE is kept from showing UI of its own: D-055.
- **Same fork:** WPE and WebKitGTK are built from the same WebKit tree, from the same
  `webkitglib/<version>` stable branches and with the same security advisories, so the
  fork `aptecstudio/WebKit` and its `project-os/2.54` branch (D-019) stay valid; only
  the build changes (`-DPORT=WPE`).
- **Mobile:** the same WPE on the libhybris EGL path; fallback if that fails: Igalia's
  WPE port for Android (to be evaluated in the Phase 7 feasibility check). Chromium/CEF
  and Android's WebView were set aside: another engine to maintain, or one that needs
  Android's Java runtime.
- **Security rules:** web content never sees `system` or the Lua VM (AGENTS.md §5.4);
  an app talks to its own web view only through a message channel it declares
  (`webview` permission in `package.json`); each web view has its own WebKit context
  (storage, cookies) bound to its app.
- **Why:** one engine, one build and one set of fixes for the browser and the web views
  on desktop and mobile; GTK 4 only to host a widget would be a large extra surface
  (AGENTS.md §5.5).
- **Discarded alternatives:** WebKitGTK on both targets (GTK 4 in the image only for
  the web view, and a GTK widget does not fit into our EGL scene); WebKitGTK on desktop
  and another library on mobile (two engines); Servo (embeddable and in Rust, but not
  yet mature enough for a full browser; to be watched).

### D-052 — App folders and `.pak` packages · `requirement` (R-39, 2026-11-13), details `proposed`
- **What:** an app is either a folder or a `.pak` file; in both cases its resources
  are reached with `app://` (R-31, D-031) and the manifest is `package.json` at the
  root (R-11, data and not code: it is read without running any script).
- **`.pak` format (proposed):** a zip archive read **in place**, never extracted: the
  `app://` resolver opens entries directly (stored or deflate only). Rules checked at
  installation and when the package is opened:
  - entry names normalized: no `..`, no absolute paths, no backslashes, no symbolic
    links, no duplicate names, no encrypted entries;
  - central directory and local headers must agree (no two readings of the same
    archive);
  - limits on number of entries, size and compression ratio (no zip bombs);
  - **signature over the whole file**, in a block placed before the central directory,
    like Android's APK signature scheme v2, not per entry like JAR signing (per-entry
    signing left room for flaws such as Android's "Janus"). Closes DA-05 if approved.
- **Folders (proposed):** for development; an unsigned folder app runs only in
  developer mode, after an explicit choice of the user; installed apps are signed
  `.pak` files.
- **Why:** R-39; reading in place keeps the app read-only (D-031) and avoids a second
  copy on disk.

### D-053 — Lua programming model: classes, events, coroutines, XML layouts · `requirement` (R-30, R-35, R-40), details `proposed` (2026-11-13)
- **Classes:** a built-in `class()` function, since Lua has no classes:
  `local Card = class("Card", system.ui.Component)` with an `init` constructor,
  `super` calls, observable properties (for data binding) and `on`/`off`/`emit`
  events (R-35); Luau types describe them for `luau-analyze`.
- **Asynchronous calls:** every event handler runs in a coroutine, and the `system`
  functions that wait (files, network, dialogs) suspend only that coroutine: the code
  reads straight (`local text = system.fs.readText(path)`) without blocking the
  interface or chaining callbacks.
- **`include(url)` and `includeAsync(url)` (R-30, D-030):** unchanged rules (own scope,
  cache, `IncludeCycleError` with the chain, only `app://`); in Lua the included chunk
  returns its exports as a table (an `exports` table is also provided, for R-30).
  `includeAsync` suspends the calling coroutine. Lua's `require` is not available.
- **XML layouts (R-40):** a file per screen or component, e.g. `app://layout/main.xml`:
  elements are components (`<Column>`, `<Button>`), attributes are their properties,
  `id` names an element, `@string/…` and `@drawable/…` point to the app's resources
  (translations, images), `on:click="onSave"` binds an event to a method of the
  controller class. Parsed by the Rust host (`quick-xml`) and checked against the
  framework's schema; no scripts inside XML. In Lua the same tree is built with
  constructors, and `self:find("id")` reaches an element in both cases.
- **Why:** the user's requirements; coroutines are Lua's natural way to wait, and XML
  keeps the layout separate from the logic, as on Android.

### D-054 — Shell, system dialogs and setup in the native framework · `confirmed` (the user's choice, 2026-11-13)
- **What:** the shell (Phase 5), the system dialogs (R-10, D-006: the portal backend
  and polkit agent show native dialogs), the desktop installation
  wizard (D-010) and the first-boot setup (D-017) are Lua apps of the framework, like
  every other app. Web content lives only in web views and in the browser (D-051).
- **Why:** a single framework for everything; the installation medium (D-010) needs
  only the framework and no web engine, so it is smaller and starts faster.

### D-055 — Web views show only our system UI · `requirement` (the user, 2026-11-13), details `proposed`
- **What (the user's requirement):** WPE WebKit must never show dialogs, menus or windows
  of its own: every request of a web page for UI goes through the system dialogs (R-10)
  and the components of the framework.
- **Why it is possible:** unlike WebKitGTK, which builds GTK dialogs and menus by itself
  when a signal is not handled, WPE has no toolkit and passes these requests to the
  embedder through signals of `WebKitWebView`; WebKit's Wayland, DRM and headless
  outputs are only *platform implementations* of WPEPlatform, and an embedder can
  provide its own by subclassing `WPEDisplay`, `WPEView` and `WPEToplevel`.
- **How (proposed):**
  1. **Own WPE platform:** the framework implements `WPEDisplay`, `WPEView` and
     `WPEToplevel` (Rust, through bindings) and sets it as the primary display, so the
     web process renders off-screen and WPE never opens a Wayland window or talks to the
     compositor: its frames reach us as `WPEBuffer`s, and input comes only from our
     component. The built-in Wayland and DRM platforms are left out of the build in the
     fork (headless kept only for tests), so no code path can create a window of its
     own.
  2. **Every UI request handled** by the `WebView` component, which answers it and
     stops the default handler (the signal returns `TRUE`):
     | WebKit signal | Shown with |
     |---|---|
     | `script-dialog` (`alert`, `confirm`, `prompt`, leave-page confirmation) | system dialog (`system.dialogs`) |
     | `show-option-menu` (`<select>` lists) | popup menu of the framework |
     | `context-menu` | context menu of the framework |
     | `run-file-chooser` | system file dialog through the broker (D-005, D-006); the page receives only the chosen files |
     | `permission-request` (location, notifications, camera, microphone, clipboard, pointer lock…) | system permission dialog; denied when unanswered, as WebKit's own default |
     | `authenticate` (HTTP login, client certificates) | system credentials dialog |
     | `load-failed-with-tls-errors` | error page of the framework; no bypass by default (AGENTS.md §5.6) |
     | `show-notification` | system notifications |
     | `create`, `ready-to-show`, `close` (`window.open`), `enter-fullscreen`, `leave-fullscreen` | windows of the framework, decided by the app |
     | `decide-policy` (downloads, new windows, navigation) | the app, then the system download and permission rules |
  3. **Portal requests:** whatever WebKit asks through `xdg-desktop-portal` (e.g. the
     file chooser from its sandbox) reaches our portal backend, which shows the same
     native dialogs (D-006).
  4. **Guard for new WebKit versions:** a test lists the signals of `WebKitWebView`
     and fails if one that can ask for UI is not handled by the component; it runs at
     every rebase of the fork (D-019), so a new kind of request cannot slip through
     with WebKit's default. A set of test pages triggers each request and checks that
     our handler answers and that the app has no surface other than its own windows.
- **Inside the page:** buttons, check boxes, scroll bars and media controls are drawn
  by WebKit in the page itself, with its own theme; they are not dialogs. Restyling
  them to the system style (D-032) is a patch of the fork's theme, to be decided in
  Phase 5. `<input type=color>` has no picker in WPE today; if enabled, it uses ours.
- **Discarded alternatives:** WebKit's built-in Wayland platform (it creates its own
  toplevel windows on the compositor); leaving signals to their defaults (behaviour
  that changes between WebKit versions, and outside our style and permission model).

### D-056 — Published release images · `requirement` (R-42, 2026-11-13), formats `confirmed` (the user's choice), details `proposed`
- **What gets published at every release:**
  | Target | File | Use |
  |---|---|---|
  | Desktop amd64 | `luan-<version>-amd64.iso` | installer (D-010): **hybrid ISO**, boots from USB stick and DVD, UEFI and BIOS (R-26); written with Rufus, Etcher, Ventoy or `dd` |
  | Each phone model | `luan-<version>-<device>-fastboot.zip` | images plus flashing script (D-011) |
  | Each phone model with a custom recovery | `luan-<version>-<device>-recovery.zip` | install from the recovery (D-011) |
  | All | `SHA256SUMS` and its signature | integrity of every file, signed with the project's release key |
  No ready-made virtual machine images (the user's choice): in a VM the system is
  installed from the `.iso`, like on a PC. The `.wic` image stays a development output
  for QEMU (D-028), not a release file.
- **One signed system, every path (proposed):** the installer and the phone packages
  carry the same signed system image as the RAUC update bundle (D-026, D-047), and the
  installer checks its signature before writing slot A. Installing and updating write
  the same verified file, so the installation is tested by the same checks as the
  updates.
- **Desktop ISO (proposed):** GRUB for both UEFI (an EFI system partition image inside
  the ISO) and BIOS (El Torito), MBR and GPT for USB booting, made with `xorriso`; the
  medium starts only what the wizard needs (D-010) and no live session (R-19). Secure
  Boot with Luán keys in Phase 8 (D-009).
- **Phones (proposed):** the fastboot package flashes the boot images with the vendor
  kernel (D-014), the system image and the verified-boot metadata (`vbmeta`); on models
  that allow a custom verified-boot key (Pixels: `avb_custom_key`), the package installs
  the project's key, so the bootloader can be locked again with Luán on it. The
  flashing script is POSIX `sh` (Linux and macOS); for Windows, the plain `fastboot`
  commands in the guide, or a script if a language for it is added to AGENTS.md §7.
- **Where:** GitHub Releases of `aptecstudio/luan` (proposed); the release key
  stays outside the repository (AGENTS.md §4).
- **Why:** R-42: users must be able to install Luán without building it.

### D-057 — One-command setup of a build host · `confirmed` (the user's request and approval, 2026-11-14)
- **What:** `tools/setup-host.sh` (D-028) is the only command a developer runs on a new
  Debian 13 or Ubuntu 24.04/26.04 machine to install everything the repository needs:
  - apt: the Yocto 6.0 host packages (Reference Manual list, `lz4` for
    `liblz4-tool`), QEMU and OVMF, `pipx`/`python3-venv`, `openssl`,
    `ca-certificates`, `curl`, and for `branding/tools/render.py` `librsvg2-bin`,
    `python3-pil`, `python3-numpy`, `fonts-inter`;
  - pipx: kas and the style tools of `tools/lint.sh` (D-046);
  - development keys, `en_US.UTF-8`, `kvm` group, AppArmor user namespaces (as before).
- **Checks added:**
  - **file system of the repository**, from `findmnt` (`stat` reports NTFS through
    ntfs-3g only as `fuse`): NTFS, FAT, exFAT, FUSE and network shares are reported
    with the command to clone into a Linux file system. The setup goes on, because the
    packages are needed anyway. Found on the user's second PC, where the repository is
    on an NTFS disk shared with Windows;
  - **git "dubious ownership"** (repository owned by another user, as on that NTFS
    disk): the script offers `safe.directory` for that path only, after asking;
  - **final verification** of every command, Python module, locale, OVMF, font and
    key, with the list of what is missing and a non-zero exit; RAM and free space
    compared with the two build modes (D-036), suggesting `--low-resources`.
- **`--yes`:** answers every question, for unattended setups; it includes the AppArmor
  change, so it is documented in the help and in the README.
- **Discarded:** a second script next to `setup-host.sh` (two entry points for the same
  job); `sudo VAR=value` (refused by the default sudo policy, `sudo env` is used);
  stopping on an unsuitable file system (the packages would still be missing after
  cloning elsewhere).
- **Why:** other developers must be able to prepare a machine without help; the
  dependencies were partly implicit (branding tools, `python3-venv`) and an NTFS
  checkout failed only hours into the build.
- **Checks done (2026-11-14), on the user's second PC** (Debian 13, Intel i5-3470,
  4 cores, 7 GB of RAM, repository cloned again on ext4):
  - the script installed everything; its final checks all pass (19 commands, Python
    modules, `en_US.UTF-8`, OVMF, Inter, keys); `tools/lint.sh` clean;
  - first build from zero there, of `main` (before the script was run): 3809 tasks,
    about 3 hours in low-resources mode, no errors; then the build of this branch
    reused 3647 of its 3966 tasks (about 50 minutes, mostly the kernel) and the
    update bundle;
  - full QEMU test (§5), with the window visible: new disk on slot A (erofs root
    verified by dm-verity, `/etc` overlay, UKI with the slot's profile, system
    `running`, no failed units, about 81 MB of RAM in use), update to slot B
    confirmed by `rauc-mark-good`, a file written in `/etc` on A still there on B,
    boot of B interrupted by a reset 3 s after GRUB started it → automatic rollback
    to A (B marked bad), EFI partition clean;
  - seen on a new disk only: `rauc` logs "No bootable slot found in ORDER 'A B'"
    until the first update, because slot B is still empty (`B_OK=0`); expected, not
    an error.


### D-058 — Data unlocking with password and recovery key, 3 boot attempts per slot (step 4d) · `confirmed` (the user's choices and approval, 2026-11-14)
- **What the user chose:** the password is set **by a command after the first boot**,
  until the setup of Phase 8 exists; the **TPM is postponed to Phase 8**, together with
  Secure Boot; the **development image behaves like the release** (it asks the
  password too); every slot gets **3 boot attempts**, given back at every boot that
  completes.
- **`luan-data-key`** (`luan-storage`, POSIX sh): `status`, `setup`,
  `password`, `recovery-key`.
  - `setup`: recovery key from `systemd-cryptenroll --recovery-key` (unlocking with the
    empty key), shown and typed back to confirm it was saved (dashes, spaces and case
    ignored); password asked twice, at least 8 characters, added with
    `cryptsetup luksAddKey` (Argon2id, memory a quarter of the RAM, at most 1 GiB:
    505 MB in a 2 GB VM instead of up to 893 MB, D-044); both keys checked with
    `cryptsetup open --test-passphrase`, **then** the empty key is removed. If the setup
    stops before that, the new recovery key is removed, so it can be run again.
  - `password` accepts the current password or the recovery key; `recovery-key` asks
    the password. The new key is checked before the old one is removed.
  - Secrets only in a private directory in `/run` (RAM), removed on exit; key files
    without a final newline (a key file is used byte by byte: the recovery key printed
    with its newline was refused).
  - Why the checks before every removal: `systemd-cryptenroll --wipe-slot` removed the
    empty key even with a wrong unlock key (seen in QEMU), which would leave the data
    with keys nobody knows.
- **At boot:** unchanged `crypttab` in the initramfs (`try-empty-password=yes`, then
  `systemd-ask-password` on the screen console): the prompt accepts the password or
  the recovery key and asks again after a wrong one. Keyboard layout: US, like the
  system's console (`/etc/vconsole.conf` is on the encrypted partition, so the
  initramfs cannot read a local choice); the recovery key types the same on every
  layout. The layout chosen in the setup (Phase 8) must reach the initramfs.
- **Cost of the empty-key try:** after the setup, trying the empty key costs one
  Argon2id derivation of the password slot, about 1.9 s at every boot (QEMU). Kept
  while the partition is created with an empty key; to be removed when the setup of
  Phase 8 creates it with the password.
- **3 boot attempts per slot** (`luan-grub.cfg`, `X_LEFT` in `grubenv`): GRUB uses
  one attempt at every boot of a slot; the third sets `X_TRY=1` and the slot is given
  up after it. `rauc-mark-good` clears `X_TRY` and `luan-boot-attempts`
  (`ExecStartPost`, `rauc-conf`) puts `X_LEFT` back to 3. An empty or `0` count with
  `X_TRY=0`, as after an installation, counts as 3. Why: with one attempt, a PC
  switched off at the password prompt fell back to the previous version and the
  newer slot was never tried again (seen in QEMU); a corrupted slot still falls back,
  after 3 restarts (D-047). Like systemd-boot's boot counting.
- **Discarded:** asking the password in the initramfs on first boot, before the data
  partition is created (the user chose the command); TPM unlocking now (without Secure
  Boot the boot chain is not signed end to end); an empty key only in development
  images (the release path would be tested less); counting attempts only for slots
  not yet confirmed (a corrupted confirmed slot would restart forever, against D-047);
  confirming the slot in the initramfs before the password (failures after the
  password would no longer roll back); re-encrypting the partition at setup (data
  written before the setup stays readable to whoever copied the disk in that time:
  hours of rewriting for a case the Phase 8 setup removes).
- **Checks done (QEMU, 2026-11-14, window visible; the password prompt is on the screen
  console, so the tests type on it with QEMU's `sendkey`):**
  - new disk: `status` reports the partition not protected; `setup` refuses a wrong
    recovery key, a password shorter than 8 characters and two different passwords,
    then leaves one password (Argon2id, 505 MB) and one recovery key (PBKDF2, as
    systemd-cryptenroll sets it for a random key); a second `setup` is refused;
    nothing left in `/run`;
  - boot: a wrong password and then the right one; the recovery key at the prompt;
    `password` with the recovery key as the current key, `recovery-key` refusing the
    old password: afterwards the old password and the old recovery key no longer
    open the partition, the new ones do;
  - boot attempts: a reset at the password prompt keeps the slot (A again at the next
    boot, `A_LEFT` back to 3 after the login); update to B, B confirmed with
    `B_LEFT=3`; B interrupted at the prompt 3 times → A at the fourth boot (`B_TRY=1`,
    `B_LEFT=0`), system `running`, EFI partition clean.

### D-059 — BIOS boot with GRUB in the same disk image (step 4e) · `confirmed` (the user's approval, 2026-11-14)
- **What:** the disk that boots from UEFI also boots from a legacy BIOS (R-26), with the
  same `grub.cfg`, `grubenv`, slots and boot files on the EFI partition.
  `luan_bios_boot.bbclass` runs `files/bios/luan-bios-boot` at the end of
  `IMAGE_CMD:wic`, before the `.wic.bmap` map is made:
  - `core.img` built with `grub-mkimage -O i386-pc` (modules of `grub-native`) with only
    the modules the menu needs on BIOS: `biosdisk part_gpt fat normal configfile echo
    test loadenv linux minicmd search` (148 KB, 290 sectors), prefix
    `(,gpt2)/EFI/BOOT` (the EFI partition of the disk the BIOS booted from), written into
    the 1 MiB `bios_grub` partition;
  - `boot.img` into the protective MBR, keeping the BPB area and, from 0x1b8, the disk
    signature, the protective partition entry and `0x55aa`; then the sector of
    `core.img` (0x5c), boot drive 0xff (0x64), NOPs over the drive check (0x66), and
    the blocklist of `core.img` (sector after the first, count), as GRUB 2.14's
    `util/setup.c` does for a `bios_grub` partition.
  - On BIOS `grub.cfg` loads `bzImage`, `microcode.cpio` and `initramfs.cpio.zst` of the
    slot with the command line of its `boot.env` (prepared in step 4c.4, D-048); the
    update bundle already writes them for the slot it installs.
- **`tools/run-qemu.sh --bios`:** the same disk with QEMU's SeaBIOS instead of OVMF. On
  BIOS, GRUB and the kernel write only on the screen: automated tests check every boot
  with a screenshot.
- **Discarded:** `grub-bios-setup` and `grub-install` (they look for the real disk of
  their working directory and fail on an image file in the build: "failed to get
  canonical path", "disk does not exist"); a wic source plugin (more code bound to wic
  internals for the same few writes); copying the i386-pc module directory to the EFI
  partition (about 600 files; built-in modules are enough, the theme's ones too,
  D-060); the work in the class
  itself (BitBake's shell parser does not accept arithmetic expansion: the build stopped
  at parsing). Reed-Solomon codes left out (`--no-rs-codes` behaviour): they only help
  recover a `core.img` damaged on disk.
- **Still open:** updates do not rewrite `boot.img` and `core.img` yet (with
  GRUB and `grub.cfg` on the EFI partition, ROADMAP). Real BIOS and CSM firmwares in the
  hardware session (step 6.2): some old BIOSes boot a GPT disk only if the protective
  MBR entry is marked active.
- **Checks done (QEMU, 2026-11-14, window visible):** new disk from SeaBIOS: no EFI
  firmware (`/sys/firmware/efi` missing), GRUB menu without the UEFI entry, slot A from
  `/EFI/luan/A/bzImage`, dm-verity root, encrypted data and `/etc` overlay,
  system `running`, `grubenv` written by GRUB on BIOS (`A_LEFT` back to 3); keys set up,
  update to B, slot B from its own `bzImage` and confirmed; B interrupted 3 times at the
  password prompt (screenshots) → A at the fourth boot, `B_TRY=1`, EFI partition clean.
  Then a new disk of the same image from UEFI: slot A, system `running`. The disk made
  by the script is identical, byte for byte, to the one first tested by hand.
### D-060 — Boot menu theme in the image, other systems found by GRUB (step 5b) · `confirmed` (the user's approval, 2026-11-14)
- **What:**
  - `luan-grub-theme` recipe: the theme of `branding/grub-theme` (D-023, single
    source, read from outside the layer) with the Inter 4.1 fonts of the official
    release converted to `.pf2` by `grub-mkfont` (Regular 14 and 18, Medium 18,
    SemiBold 28), only ASCII, Latin-1, Latin Extended-A, punctuation and arrows;
    Inter's OFL license next to them. Deployed and copied by wic to
    `EFI/BOOT/themes/luan` on the EFI partition, where `grub.cfg` already looked.
  - `grub-mkfont` enabled only in `grub-native` (bbappend, with `freetype-native`): the
    GRUB of the image does not change, nothing is added to the system.
  - `grub-mkfont` names a font "<name> <style> <size>" and reads the style only from the
    bold and italic flags, so the Medium and SemiBold files are named "Inter Medium
    Regular 18" and "Inter SemiBold Regular 28" in `theme.txt`.
  - `grub.cfg` loads the four fonts by name (the old `*.pf2` loop would have loaded
    nothing: GRUB expands `*` in file names only with the `regexp` module).
  - Video through the firmware only: `efi_gop` and `efi_uga` on UEFI, `vbe` in the BIOS
    `core.img` (with `font gfxterm gfxterm_background gfxmenu png`), so the menu looks
    the same from both. Not `all_video`: it also brings `video_bochs` and
    `video_cirrus`, which program QEMU's video card directly; under OVMF the screen
    became 8x32 pixels and `gfxterm` failed ("glyphs too large to fit on screen").
  - **Other systems (the user's choice):** at every boot from UEFI GRUB looks on all the
    partitions for the boot loader of known systems and adds an entry that chainloads
    it: Windows (`/EFI/Microsoft/Boot/bootmgfw.efi`), Ubuntu, Debian, Fedora, openSUSE
    (their shim), systemd-boot, and GRUB installed as `EFI/GRUB`. A system installed
    later shows up with nothing to update.
    - The search is `for loader in (*)/path` with the `regexp` module built in: `(*)`
      expands only to the partitions that have the file, then `[ -f ]` checks it.
      `search --file` prints an error on the screen for every loader it does not find.
      `regexp` changes nothing else in `grub.cfg`: only words with `*` or `?` expand.
    - The entry sets `root` to the loader's partition before `chainloader`: GRUB's EFI
      chainloader tells the started loader that it comes from the root device, and
      Windows looks for its boot configuration there. Without it the loaders found
      started as if from our own EFI partition.
    - Only FAT is built into GRUB, so it reads only EFI partitions, never the file
      systems of the other systems.
  - No decompressor messages on the screen from BIOS: `CONFIG_X86_VERBOSE_BOOTUP` off
    (`input-platform.cfg`). GRUB starts the kernel from BIOS through its 32-bit entry,
    which skips the setup code that reads `quiet`.
  - `tools/run-qemu.sh --with-disk=FILE` attaches a second disk, to see another system
    in the menu.
- **Discarded:** `os-prober` (planned in D-009): no recipe in our layers, it would be a
  package in the system run as root that mounts the file systems of other systems, and
  its entries go stale until it runs again; `os-prober` only in the installer (Phase 8),
  for the same staleness; the whole Inter font (each `.pf2` ten times bigger, slower to
  load); `.pf2` files made on the host and kept in the repository (D-023: generated
  files are not kept, and the build would depend on the host's GRUB version).
- **Still open:** from BIOS no entries for other systems (Windows on BIOS needs the
  `ntfs` and `chain` modules and its own disk mapping): they start from the firmware's
  boot menu; with Secure Boot (Phase 8) the chainloaded loaders must pass shim's checks
  (Microsoft's and the distributions' are signed); localized menu texts (D-023).
- **Checks done (QEMU, 2026-11-14, window visible):**
  - Build: four `.pf2` fonts with the names of `theme.txt` (53 KB in all); BIOS
    `core.img` 353 sectors of 2048; kernel fragments in the final configuration.
  - UEFI with a second disk (`--with-disk`) holding two FAT partitions with fake loaders
    (copies of systemd-boot at the Windows and systemd-boot paths): themed menu with
    "Windows" and "Linux (systemd-boot)"; each entry started the loader of its own
    partition (systemd-boot found `bootmgfw.efi` only when started from the "Windows"
    one); no GRUB errors; normal boot to `running`, theme and fonts on the EFI
    partition.
  - BIOS: same themed menu, without the UEFI entry; black screen while the kernel
    starts and a clean password prompt (no decompressor messages); `running`.
  - Full test (new disk from SeaBIOS): keys set up, update to B, B confirmed with
    `B_LEFT=3`, B interrupted 3 times at the password prompt (screenshots) → A at the
    fourth boot (`B_TRY=1`, `B_LEFT=0`), EFI partition clean; then a new disk of the same
    image from UEFI: slot A, `running`.
  - Not tested: a real Windows (hardware session, step 6.3).

### D-061 — Hardware services: NetworkManager, ModemManager, BlueZ, PipeWire (step 3c) · `proposed` (2026-11-14)
- **What (the user's request: the hardware side complete before the hardware
  session, step 6):** the services that make network, Bluetooth and audio usable,
  in `packagegroup-luan-services` (`meta-luan`, shared with mobile); their
  build options in the distribution configuration, trimmed to what is used.
  - **Network: NetworkManager** for wired, Wi‑Fi and mobile networks, with
    **wpa_supplicant** for Wi‑Fi and **ModemManager** (MBIM and QMI) for mobile
    broadband, plus the provider database for the APN. DNS goes to
    `systemd-resolved`, already in the system. `systemd-networkd` is turned off in
    systemd: two managers on the same interfaces would fight over them. No polkit:
    only root (later the broker, D-005) changes the network. No `dnsmasq`, PPP,
    `ifupdown`, Bluetooth tethering, and no `nftables` (NetworkManager's firewall for
    sharing a connection): not used yet.
  - **Bluetooth: BlueZ** with the profiles for keyboards, mice, audio and LE Audio;
    without OBEX file transfer, PAN networking and the deprecated tools.
  - **Audio: PipeWire with WirePlumber**, started by systemd for each user session (no
    system-wide service), with ALSA devices, Bluetooth audio (SBC; AAC needs a
    commercial license) and the ALSA plugin that routes ALSA programs to PipeWire;
    `alsa-ucm-conf` for the laptops with an audio DSP (Intel SOF, AMD ACP). No
    GStreamer, JACK, camera, Avahi, Flatpak, FFmpeg: they come with the phases that
    use them.
  - **Kernel:** `wwan.cfg` (desktop): USB modems (MBIM, QMI, NCM, serial AT ports), M.2
    modems on PCIe (Qualcomm MHI, Intel XMM7360, MediaTek T7xx), internet shared by a
    phone over USB (Android RNDIS and NCM, iPhone).
  - **Layers:** `meta-networking` (NetworkManager) and `meta-multimedia` (PipeWire,
    WirePlumber) of meta-openembedded, and `meta-python` because both depend on it.
  - **Build trimming:** PipeWire's recipe sets its defaults with the `class-target`
    override, which wins over a `pn-pipewire` assignment (the first build compiled
    Vulkan, Wayland, X11 and GStreamer tools): the unused options are removed with
    `:remove` instead, checked with `bitbake -e` and the dependency graph.
    `gobject-introspection-data` is opted out of the distribution (bindings for other
    languages, unused, made by running each library under emulation); the BlueZ
    bbappend drops the run-time dependencies of the never-installed Python test
    scripts, which made the build compile PyGObject.
  - **Development images only** (`kas/dev.yml`): `packagegroup-luan-dev-tools`
    with `nmcli`, `iw`, `speaker-test`/`aplay`/`amixer`, `lspci`, `lsusb`, to test the
    hardware by hand; `bluetoothctl` and `wpctl` come with their services.
  - **`tools/run-qemu.sh --audio-file=FILE`:** an HD Audio sound card whose output is
    recorded into a WAV file, to check the audio chain in the emulator.
- **Why NetworkManager (the user left the choice, asking to consider wired and mobile
  networks on every platform):** it covers wired, Wi‑Fi, mobile broadband, VPN and
  hotspot with one D-Bus API, which the shell and the settings will use (Phases 5–6);
  the Halium-based phone systems (Ubuntu Touch, Droidian) use it too, so desktop and
  mobile (D-014) share it; ModemManager is its standard companion for modems.
- **Discarded:** iwd with systemd-networkd (lighter, but no mobile broadband or VPN,
  and iwd does not work with many Android vendor Wi‑Fi drivers); NetworkManager with
  iwd (the same driver problem on phones; one Wi‑Fi backend everywhere); ConnMan with
  oFono (smaller community, oFono is fading out in favor of ModemManager); a
  system-wide PipeWire (one audio server for all users, against the isolation of
  D-005).
- **Still open:** hotspot and connection sharing (`dnsmasq`, `nftables`) and the
  firewall; captive-portal detection (it contacts a server: to be decided); on mobile,
  the modem through Halium (oFono or ModemManager, Phase 7); PipeWire for apps
  (PulseAudio compatibility, GStreamer) with WebKit (Phase 2).
- **Checks done:** dependency graph and effective build options (2026-11-14). Build
  and QEMU test (`tools/run-qemu.sh --audio-file`: wired network with DNS, ModemManager
  and BlueZ without hardware, a 440 Hz tone recorded in the WAV file) still to do.

### D-062 — Final name Luán and logo · `confirmed` (the user's choice, 2026-11-22)
- **What:**
  - the system is called **Luán** (it settles DA-06b; "project-os" was the working
    name). Text for people (documentation, comments, boot menu, `DISTRO_NAME`, UKI
    titles, systemd unit descriptions) writes **Luán**;
  - every technical name uses the ASCII form **`luan`**: layers `meta-luan` and
    `meta-luan-desktop`, distribution `luan`, machine `luan-amd64`, recipes and files
    `luan-*`, paths such as `/var/lib/luan` and `/EFI/luan`, variables `LUAN_*`,
    BitBake functions and classes `luan_*` (AGENTS.md §7), host name `luan`,
    repository `aptecstudio/luan`; messages printed by scripts start with `luan:`, and
    the development certificates use `O=Luan` (ASCII, no `-utf8` needed);
  - **logo:** a crescent moon with two four-pointed stars in its hollow, a large one
    and a small one above it (the user removed the lower third star of the draft),
    **white** on night blue (the user asked for white instead of the first yellow
    draft), night blue `#1B2559` on light backgrounds. The final file is
    `branding/logo/luan-logo.svg`: the crescent is one path (outer circle minus the
    bite circle) instead of an SVG mask, so `rsvg-convert` and any other renderer draw
    it the same way;
  - **concept:** the design canvas the logo was chosen on is kept in
    `branding/concept/` (`canvas.json` and one `.dc.html` file per artboard: main
    logo with the wordmark, and dark, light, monochrome and app icon variants). Its
    wordmark uses the Outfit font (light weight); the boot menu keeps Inter (D-023)
    until the visual style of Phase 5 decides the system fonts. On the smallest app
    icons the small stars are dropped (one star at 48 px, the crescent alone at
    24 px), so the mark stays readable.
- **Why:** the user's choice. The accented letter is kept only where people read it:
  file names, package names, host names, variables and URLs must stay ASCII, and one
  form everywhere (`luan`) avoids mixing `luan`, `luán` and `lu-an`.
- **Not renamed:** the `project-os/2.54` branch of the WebKit fork (D-019), which
  already exists; the next branches follow `luan/<version>`.
- **Effects of the rename:** the development keys moved from
  `~/.config/project-os/keys` to `~/.config/luan/keys`; on a build host prepared
  before the rename, `tools/setup-host.sh` installs `/etc/sysctl.d/60-luan-bitbake.conf`
  and the old `60-project-os-bitbake.conf` can be deleted; a build directory made
  before the rename rebuilds the recipes whose names, distribution or machine changed.
- **Discarded alternatives:** `luan-os` as the technical name (longer, and the project
  needs no suffix to be told apart); `luán` in identifiers (not valid in most of them).

---

## 3. Visual style

*To be defined in Phase 5.* Record here: palette, typography, spacing, radii, shadows,
animation durations and curves, icons, light/dark and adaptive behavior (desktop ↔
mobile).

**References (R-32, D-032):** a hybrid of Windows 11, macOS Big Sur and Xiaomi MIUI.
First reading of the traits to combine, to be confirmed in Phase 5:
- from **Windows 11**: translucent and blurred materials (Mica/Acrylic style), rounded
  corners, floating menus and panels, snappable window layouts;
- from **macOS Big Sur**: strong translucency ("vibrancy") of bars and sidebars, very
  rounded corners, soft icons and controls, fluid animations;
- from **MIUI**: on mobile, control center with large tiles, rounded cards, large and
  bold typography, gestures.

**Starting point (from the boot theme, D-023; provisional):**
- Background `#0B0D12`, glow `#2A2F6B`. Logo and brand: **monochrome white** `#FFFFFF`;
  on light backgrounds, night blue `#1B2559` (D-062).
- Main text `#F2F4F8`, secondary `#9AA3B2`, dimmed `#7D8597`, minimal `#596173`.
- Font: Inter. Radius of selectable elements: 10 px.

---

## 4. Code structure (proposed)

```
luan/
├── AGENTS.md  MEMORY.md  ROADMAP.md
├── README.md     # project presentation (requested by the user on 2026-11-11)
├── layers/       # Yocto layers (D-012)
│   ├── meta-luan/           # common user space: recipes, images, GRUB theme
│   ├── meta-luan-desktop/   # amd64 hardware layer: mainline kernel, Mesa, firmware
│   ├── meta-luan-mobile/    # common arm64 hardware layer: Halium/libhybris
│   └── meta-device-<name>/  # one layer per phone: kernel, firmware, recovery
│                            # package (pixel-…, samsung-…, oppo-…)
├── kas/          # Yocto build configuration (D-024): versions, layers, machine
├── tools/        # development tools (e.g. checking kernel fragments)
├── build/        # build output (not versioned)
├── sources/      # external repositories fetched by kas (not versioned)
├── branding/     # logo and its concept, GRUB theme, generation script, previews
├── runtime/      # app host: Luau VM, `include`, `app://` resolver, `.pak` reader
├── framework/    # graphics framework: EGL/GLES, Skia, layout, components, web view
├── broker/       # permission daemon and native APIs
├── portal/       # xdg-desktop-portal backend and polkit agent (native dialogs)
├── shell/        # system shell: panels, launcher, notifications, dialogs
├── apps/         # system applications (settings, files, terminal,
│                 # desktop installer, first-boot setup…)
├── sdk/          # Luau type definitions of the `system` object and of `systemui`
└── docs/         # specifications (package.json format, APIs, permission model)
```

---

## 5. Syntax conventions

**Code style (AGENTS.md §7, D-046):** standard conventions of each language, checked
by `tools/lint.sh` before every commit. Already fixed (AGENTS.md §6,
D-037): **everything in English** — identifiers, comments, script options and messages,
documentation and commits; Italian only in translation files. Conventional Commits.

**Testing in QEMU (convention approved by the user, 2026-11-12):** every change is
tested in QEMU before its commit, with the QEMU window visible to the user. How much
depends on what the change touches:

| The change touches… | Test |
|---|---|
| GRUB, partitions, RAUC, initramfs, kernel command line, mounts at boot | boot from a new disk + A/B update to slot B + boot of B interrupted 3 times (its attempts, D-058) with automatic rollback to A |
| only packages or files inside the system (firmware, programs, configuration) | boot from a new disk and checks of the system (`running`, no failed units, the change in place) |

Why the full test for the boot chain: slot B comes from a different file (the update
bundle, not the full disk image), uses other GRUB entries and the state in `grubenv`,
and the automatic rollback is the safety net of every installed PC. Errors found only
this way: `/efi` not mounted in slot B, the bundle missing its `ext4` image,
`true`/`false` against RAUC's `1`/`0` in `grubenv` (D-026). Checks that need real
hardware go to the hardware test session (D-040).

**Work branches (the user's preference, 2026-11-11):** work happens on **one branch at
a time**, the one open for review (today `build/hw-services`). New steps and updates to
`MEMORY.md` and `ROADMAP.md` go there as subsequent commits; no parallel branches
are opened. A new branch is opened only after the merge into `main`. Before starting,
`git fetch` and start again from the updated remote branch: work happens from several
devices.
