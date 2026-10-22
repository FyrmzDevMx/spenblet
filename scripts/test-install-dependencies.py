#!/usr/bin/env python3
"""Exercise dependency selection without running a real package manager."""

import pathlib
import subprocess
import tempfile

SCRIPT = pathlib.Path(__file__).with_name("install-dependencies.sh").resolve()
CASES = {
    "pacman": ["pacman -Syu --needed android-tools android-udev curl rust"],
    "apt-get": [
        "apt-get update",
        "apt-get install -y adb android-sdk-platform-tools-common curl cargo",
    ],
    "dnf": ["dnf makecache --refresh", "dnf install -y android-tools curl cargo"],
    "yum": ["yum makecache --refresh", "yum install -y android-tools curl cargo"],
    "zypper": [
        "zypper --non-interactive refresh --force",
        "zypper --non-interactive install --no-recommends android-tools curl cargo",
    ],
    "apk": ["apk update", "apk add android-tools android-udev-rules curl cargo"],
    "xbps-install": [
        "xbps-install -Syu android-tools android-udev-rules curl cargo"
    ],
    "emerge": [
        "emerge --sync",
        "emerge --ask=n --oneshot dev-util/android-tools "
        "dev-util/android-udev-rules net-misc/curl dev-lang/rust",
    ],
}


def run_manager_case(manager, expected):
    with tempfile.TemporaryDirectory(prefix="spenblet-installer-") as temp:
        root = pathlib.Path(temp)
        bindir = root / "bin"
        bindir.mkdir()
        log = root / "calls"
        stubs = {
            "id": "#!/bin/sh\nprintf '0\\n'\n",
            "modprobe": "#!/bin/sh\nexit 0\n",
            "udevadm": "#!/bin/sh\nexit 0\n",
            manager: (
                "#!/bin/sh\n"
                f"printf '%s\\n' '{manager} '\"$*\" >> \"$TEST_LOG\"\n"
            ),
        }
        for name, contents in stubs.items():
            executable = bindir / name
            executable.write_text(contents)
            executable.chmod(0o755)

        result = subprocess.run(
            ["/bin/sh", str(SCRIPT)],
            env={"PATH": str(bindir), "TEST_LOG": str(log)},
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            raise AssertionError(f"{manager} failed: {result.stderr}")
        actual = log.read_text().splitlines()
        if actual != expected:
            raise AssertionError(f"{manager}: expected {expected}, got {actual}")


def test_manual_dependencies():
    with tempfile.TemporaryDirectory(prefix="spenblet-manual-") as temp:
        bindir = pathlib.Path(temp) / "bin"
        bindir.mkdir()
        for name in ("adb", "cargo", "rustc", "curl"):
            executable = bindir / name
            executable.write_text("#!/bin/sh\nexit 0\n")
            executable.chmod(0o755)
        result = subprocess.run(
            ["/bin/sh", str(SCRIPT)],
            env={"PATH": str(bindir)},
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0 or "No supported package manager found" not in result.stdout:
            raise AssertionError(f"manual dependency path failed: {result.stdout} {result.stderr}")


def main():
    for manager, expected in CASES.items():
        run_manager_case(manager, expected)
    test_manual_dependencies()
    print(f"Validated {len(CASES)} package managers and the manual dependency path.")


if __name__ == "__main__":
    main()
