# Per-PC settings

Keep hardware-dependent files separate from the shared profile. The repo ignores `host-local/` so these files remain on the PC and are not committed by accident.

## Suggested local layout

```text
host-local/
└── <pc-name>/
    ├── caelestia/monitors/<output-name>/shell.json
    └── hardware.md
```

Use the monitor output names reported by that PC's Hyprland session. Keep output names, resolution, and scaling values in that PC's local configuration. The original PC's monitor files were empty (`{}`), so no monitor settings were copied.

## NVIDIA driver selection

Do not copy another PC's driver package as a shared requirement. For each PC:

1. Identify the GPU and kernel in use, then check the current [ArchWiki NVIDIA guide](https://wiki.archlinux.org/title/NVIDIA) for the matching family and package.
2. Choose a driver package that supports both that GPU and kernel. Kernel variants can require a DKMS package and matching kernel headers.
3. Keep the selected package and any needed local notes in that PC's `host-local/<pc-name>/hardware.md`.

As of 2026-10-12, the ArchWiki lists the RTX 3070's Ampere family and RTX 4070's Ada family among the generations supported by `nvidia-open`; for the standard `linux` kernel it lists `nvidia-open`, and for other kernels it lists `nvidia-open-dkms`. The guide also notes an Ampere laptop caveat. Recheck the live guide when installing because package names and support can change. Do not pin a driver version in the shared package list.

The old PC's package inventory and monitor settings live under the ignored `host-local/this-pc/` directory. Their presence there does not make them portable defaults.
