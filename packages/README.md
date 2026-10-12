# Package notes

This repo does not carry a fixed NVIDIA package or a system-wide Arch installer. `setup-caelestia.sh` offers optional `easyeffects`, `discord`, and `steam` packages, and installs this repo's EasyEffects presets when selected. Steam requires Arch's `[multilib]` repository. Install Caelestia components and their current dependencies from upstream setup guidance in `docs/setup.md`.

Select GPU driver packages per PC and kernel using `docs/per-machine.md`. Keep the original PC's installed package versions under the ignored `host-local/this-pc/` directory.
