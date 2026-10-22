# spenblet

[![CI](https://github.com/FyrmzDevMx/spenblet/actions/workflows/ci.yml/badge.svg)](https://github.com/FyrmzDevMx/spenblet/actions/workflows/ci.yml)

Use a Samsung Galaxy phone with an S Pen as a wired drawing tablet on Linux.

spenblet pairs a lightweight Android companion app with a Rust daemon. Pen events travel over a USB connection through Android Debug Bridge (ADB); the daemon exposes them to Linux as a virtual tablet using `uinput`. Drawing applications such as Krita can then receive standard pen input through libinput.

**Project status:** Beta 1.0 · **License:** GPL-3.0-or-later · **Platforms:** Android + Linux

## Features

- Absolute pen position and pressure (up to 4096 levels)
- Hover, contact, distance, tilt, and side-button events
- Virtual Linux pen device compatible with libinput
- USB transport through a local ADB port forward
- Automatic reconnection after transport interruptions

## How it works

```text
Samsung phone with S Pen
        │
        ▼
Android companion app (Kotlin)
        │  USB · ADB port forward
        ▼
Linux daemon (Rust)
        │  /dev/uinput
        ▼
libinput → Krita and other Linux applications
```

The Android app listens on device loopback only and accepts one client, reached through the USB ADB port forward. The Linux daemon connects to `127.0.0.1:27183`; neither side opens a listener on the Wi-Fi network. The virtual device is named `spenblet Pen`.

## Compatibility

The first beta was validated with:

- Samsung Galaxy S24 Ultra
- CachyOS with KDE Wayland
- Krita 6

Other Samsung Galaxy Note and S devices may work when their Android input stack exposes S Pen events. Compatibility with other models and desktop environments has not yet been verified.

## Requirements

- A compatible Samsung phone with an S Pen
- USB debugging enabled and the computer authorized in Android
- Linux with the `uinput` kernel module
- Permission to access `/dev/uinput`
- Android Platform Tools (`adb`)

## Install the beta

Connect the phone over USB, enable USB debugging, and authorize the computer. Then run the installer:

```sh
git clone https://github.com/FyrmzDevMx/spenblet.git
cd spenblet
./scripts/oneliner.sh
```

The installer supports systems using `pacman`, `apt`, `dnf`, `yum`, `zypper`, `apk`, `xbps`, or `emerge` when the required packages are available in the repositories configured for that distribution. It refreshes repository metadata before installing missing tools, then builds the Linux daemon and configures `uinput`.

On CachyOS, it also runs `cachyos-rate-mirrors` when available before updating packages. Arch-based systems require a full system upgrade when pacman refreshes package databases; Void Linux uses a full XBPS upgrade as well. The installer prints a warning before either operation. Other package managers use their configured repositories and mirror settings; the installer does not replace a distribution's mirror configuration.

The beta has only been tested on CachyOS. If no authorized phone is connected, the installer saves the APK in the project directory so it can be installed later. Other distributions may need their own Android USB udev rules, kernel `uinput` support, or a package repository that provides Android Platform Tools. If your distribution uses another package manager, install `adb`, `cargo`, `rustc`, `curl`, `udev`, and Android USB udev rules manually, then rerun `./scripts/oneliner.sh`.
