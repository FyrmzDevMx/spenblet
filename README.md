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

The installer supports Arch-based distributions (including CachyOS). It installs the required tools, builds the Linux daemon, configures the `uinput` rule, and installs the Android app when an authorized device is connected. On Arch-based systems, pacman requires a full system upgrade when refreshing package databases, so the installer warns before running `pacman -Syu`.

Debian and Ubuntu are not supported by the current beta installer.
