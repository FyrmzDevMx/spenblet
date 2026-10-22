#!/bin/sh
set -eu

fail() {
    printf 'spenblet installer: %s\n' "$1" >&2
    exit 1
}

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail 'root privileges are required; install sudo or run this script as root.'
    fi
}

has_android_rules() {
    for rules_file in \
        /usr/lib/udev/rules.d/51-android.rules \
        /lib/udev/rules.d/51-android.rules \
        /etc/udev/rules.d/51-android.rules; do
        if [ -f "$rules_file" ]; then
            return 0
        fi
    done
    return 1
}

if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
fi

if command -v pacman >/dev/null 2>&1; then
    package_manager=pacman
    adb_package=android-tools
    rules_package=android-udev
    curl_package=curl
    rust_package=rust
elif command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
    adb_package=adb
    rules_package=android-sdk-platform-tools-common
    curl_package=curl
    rust_package=cargo
elif command -v dnf >/dev/null 2>&1; then
    package_manager=dnf
    adb_package=android-tools
    rules_package=
    curl_package=curl
    rust_package=cargo
elif command -v yum >/dev/null 2>&1; then
    package_manager=yum
    adb_package=android-tools
    rules_package=
    curl_package=curl
    rust_package=cargo
elif command -v zypper >/dev/null 2>&1; then
    package_manager=zypper
    adb_package=android-tools
    rules_package=
    curl_package=curl
    rust_package=cargo
elif command -v apk >/dev/null 2>&1; then
    package_manager=apk
    adb_package=android-tools
    rules_package=android-udev-rules
    curl_package=curl
    rust_package=cargo
elif command -v xbps-install >/dev/null 2>&1; then
    package_manager=xbps
    adb_package=android-tools
    rules_package=android-udev-rules
    curl_package=curl
    rust_package=cargo
elif command -v emerge >/dev/null 2>&1; then
    package_manager=emerge
    adb_package=dev-util/android-tools
    rules_package=dev-util/android-udev-rules
    curl_package=net-misc/curl
    rust_package=dev-lang/rust
else
    for required_command in adb cargo rustc curl; do
        command -v "$required_command" >/dev/null 2>&1 || fail "unsupported package manager and '$required_command' is missing. Install adb, curl, cargo, rustc, udev, and Android USB udev rules manually."
    done
    printf '%s\n' 'No supported package manager found; using the manually installed build tools and ADB.'
    if ! has_android_rules; then
        printf '%s\n' 'Android USB udev rules were not found. If adb cannot access the phone, install the Android udev rules package for this distribution.' >&2
    fi
    exit 0
fi

# Include only missing tools so an existing rustup installation is not replaced.
set --
if ! command -v adb >/dev/null 2>&1; then
    set -- "$@" "$adb_package"
fi
if ! has_android_rules && [ -n "$rules_package" ]; then
    set -- "$@" "$rules_package"
fi
if ! command -v curl >/dev/null 2>&1; then
    set -- "$@" "$curl_package"
fi
if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
    set -- "$@" "$rust_package"
fi

if [ "$#" -eq 0 ]; then
    printf '%s\n' 'Build tools and ADB are already installed; skipping package refresh.'
    if ! has_android_rules; then
        printf '%s\n' 'Android USB udev rules were not found. If adb cannot access the phone, install the Android udev rules package for this distribution.' >&2
    fi
    exit 0
fi

case "$package_manager" in
    pacman)
        if [ "${ID:-}" = cachyos ] && command -v cachyos-rate-mirrors >/dev/null 2>&1; then
            printf '%s\n' 'Checking and updating the CachyOS mirror list.' >&2
            as_root cachyos-rate-mirrors
        elif [ "${ID:-}" = cachyos ]; then
            printf '%s\n' 'cachyos-rate-mirrors is not installed; continuing with the configured mirror list.' >&2
        fi
        printf '%s\n' 'Arch-based systems require a full system upgrade when refreshing package databases.' >&2
        printf '%s\n' 'The next command can update installed packages before installing spenblet dependencies.' >&2
        as_root pacman -Syu --needed "$@"
        ;;
    apt)
        as_root apt-get update
        as_root apt-get install -y "$@"
        ;;
    dnf)
        as_root dnf makecache --refresh
        as_root dnf install -y "$@"
        ;;
    yum)
        as_root yum makecache --refresh
        as_root yum install -y "$@"
        ;;
    zypper)
        as_root zypper --non-interactive refresh --force
        as_root zypper --non-interactive install --no-recommends "$@"
        ;;
    apk)
        as_root apk update
        as_root apk add "$@"
        ;;
    xbps)
        printf '%s\n' 'XBPS will refresh repositories and perform a full system upgrade before installing dependencies.' >&2
        as_root xbps-install -Syu "$@"
        ;;
    emerge)
        as_root emerge --sync
        as_root emerge --ask=n --oneshot "$@"
        ;;
esac

if ! has_android_rules; then
    printf '%s\n' 'Android USB udev rules were not found. If adb cannot access the phone, install the Android udev rules package for this distribution.' >&2
fi
