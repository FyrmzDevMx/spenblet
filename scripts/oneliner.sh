#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
release_url=https://github.com/FyrmzDevMx/spenblet/releases/download/v1.0.0-beta.1/spenblet-1.0.0-beta.1.apk

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

sh "$project_dir/scripts/install-dependencies.sh"

cargo build --manifest-path "$project_dir/linux/Cargo.toml" --release
as_root modprobe uinput
as_root "$project_dir/scripts/install-udev.sh"
as_root install -Dm755 "$project_dir/linux/target/release/spenblet-daemon" /usr/local/bin/spenblet-daemon
as_root install -Dm755 "$project_dir/scripts/spenblet" /usr/local/bin/spenblet
printf '%s\n' 'uinput' | as_root tee /etc/modules-load.d/spenblet.conf >/dev/null

if adb get-state >/dev/null 2>&1; then
    apk_path=${TMPDIR:-/tmp}/spenblet-1.0.0-beta.1.apk
    curl -fL "$release_url" -o "$apk_path"
    adb install -r "$apk_path"
    rm -f "$apk_path"
else
    apk_path=$project_dir/spenblet-1.0.0-beta.1.apk
    curl -fL "$release_url" -o "$apk_path"
    printf '%s\n' 'APK installation skipped: connect and authorize the phone, then run:' >&2
    printf 'adb install -r "%s"\n' "$apk_path" >&2
fi

printf '%s\n' 'Installation complete. Open spenblet on the phone, then run:'
printf '%s\n' 'spenblet'
