# Contributing

Contributions must preserve compatibility with standard Android stylus events and Linux `uinput`. Model-specific behavior belongs behind capability detection.

## Commit messages

Use a short, imperative subject that describes one change, such as `Handle USB reconnections`. Add a body when it explains the reason or a compatibility constraint. Avoid vague subjects such as `update` or `fixes`.

## Checks

Before submitting a change, run:

```sh
cargo fmt --manifest-path linux/Cargo.toml -- --check
cargo clippy --manifest-path linux/Cargo.toml -- -D warnings
cargo test --manifest-path linux/Cargo.toml
cd android
./gradlew assembleDebug lint
```

New dependencies must be necessary, actively maintained, and licensed under terms compatible with GPL-3.0-or-later. Keep comments for non-obvious constraints and decisions.
