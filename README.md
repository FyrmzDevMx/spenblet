# spenblet

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

The daemon connects to `127.0.0.1:27183`; it does not expose a network service. The virtual device is named `spenblet Pen`.

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
git clone https://github.com/FDevMx/spenblet.git
cd spenblet
./scripts/oneliner.sh
```

The installer supports Arch-based, Debian, and Ubuntu-based distributions. It detects the package manager, installs the required tools, builds the Linux daemon, configures the `uinput` rule, and installs the Android app when an authorized device is connected.

After installation, open the Android app and start the daemon:

```sh
spenblet
```

In Krita, select `spenblet Pen` as the tablet device if necessary. On KDE Wayland, run Krita with its native Wayland backend when your distribution starts it through XWayland:

```sh
QT_QPA_PLATFORM=wayland krita
```

## Build from source

Install the Android and Rust build tools, connect an authorized device, and build the Linux daemon:

```sh
cargo build --manifest-path linux/Cargo.toml --release
```

For the Android companion app:

```sh
cd android
./gradlew assembleDebug
```

For the complete manual setup and development checks, see [CONTRIBUTING.md](CONTRIBUTING.md) and the [CachyOS test procedure](docs/cachyos-test.md).

## Current limitations

- Linux installation and ADB forwarding use command-line tools.
- Display selection and tablet calibration are not configurable yet.
- Debian and Ubuntu packages are not available yet.
- Hardware and desktop compatibility beyond the validated setup is still being tested.

See [Beta 1.0 notes](docs/beta-1.0.md) for the release scope.

## Repository layout

| Path | Description |
| --- | --- |
| `android/` | Kotlin companion app that captures S Pen input |
| `linux/` | Rust daemon that creates the virtual tablet |
| `packaging/` | Linux device permission rules |
| `scripts/` | Installer and launch helpers |
| `docs/` | Protocol, release notes, and test instructions |

## License

spenblet is licensed under the [GNU General Public License v3.0 or later](LICENSE).
