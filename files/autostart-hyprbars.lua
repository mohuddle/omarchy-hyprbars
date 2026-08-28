-- Append to ~/.config/hypr/autostart.lua
-- Load hyprbars if the plugin .so is present. PLUGIN_INIT reloads config so
-- looknfeel.lua can register the hide/close buttons.
local hyprbars_so = os.getenv("HOME") .. "/.local/share/hyprland/plugins/hyprbars.so"
o.exec_on_start(
  "test -f "
    .. o.shell_quote(hyprbars_so)
    .. " && { hyprctl plugin list | grep -q hyprbars || hyprctl plugin load "
    .. o.shell_quote(hyprbars_so)
    .. "; }"
)
