-- Shared keyboard layout preference.
-- Monitor layouts and GPU settings belong in the local host configuration.
hl.config({
    input = {
        kb_layout = "se",
    },
})

-- Open the wallpaper carousel without replacing Caelestia's Super+W browser bind.
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("qs -p \"$HOME/.local/share/arch-install-home/wallpaper-selector/shell.qml\""))
