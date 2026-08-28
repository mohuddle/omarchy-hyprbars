# hyprbars on Omarchy Quattro

Notes from adding **server-side titlebars** (hide + close) to windows on [Omarchy](https://omarchy.org/) Linux **Quattro**, Hyprland **0.56.2**, Quickshell bar.

Omarchy themes recolor borders, the shell, terminals, and wallpapers. They do **not** draw a titlebar. Hyprland itself has no titlebar either: a window is a 2px border. Close is `Super+W`. Hide sends the window to the **scratchpad** (`Super+Alt+S`); `Super+S` toggles that overlay. There is no Windows-style minimize-to-taskbar.

The compositor plugin that actually draws the chrome is [hyprbars](https://github.com/hyprwm/hyprland-plugins/tree/main/hyprbars). I worked through install, Lua config, and Tokyo Night colors with [Grok](https://x.ai/grok) in the Omarchy terminal.

This is a field note, not an Omarchy support document. Plugin `.so` files are compiled against one Hyprland ABI. An `omarchy update` that bumps Hyprland will need a rebuild.

## What you get

A 22px bar on every window:

| Control | Color | Action |
| --- | --- | --- |
| Title (left) | `#c0caf5` | Window title |
| Hide (yellow) | `#e0af68` | Send window to `special:scratchpad`, stay on the current workspace (`Super+Alt+S`) |
| Close (red) | `#f7768e` | Clean close (`hl.dsp.window.close()`, same as `Super+W`) |

Icons show on hover. Unfocused windows dim the buttons to `#414868`.

Hide is **not** minimize. The app keeps running. `Super+S` toggles the scratchpad overlay; `Super+S` again puts those windows away. Several hidden windows come back together.

## Machine this was done on

| Piece | Value |
| --- | --- |
| Distro | Omarchy Quattro (Arch + Hyprland Lua config) |
| Hyprland | `0.56.2-1`, commit `efb50993780079460b0cbed1363e2166a2de1d9f` |
| hyprbars source | [hyprwm/hyprland-plugins](https://github.com/hyprwm/hyprland-plugins) pin `7644cecdb947060682891a0db2a0cdc5c0b9e704` (`hyprpm.toml` entry for 0.56.2) |
| Config | Lua (`~/.config/hypr/*.lua`), not `hyprland.conf` |
| Theme | Tokyo Night |
| Font | JetBrainsMono Nerd Font |
| Plugin path | `~/.local/share/hyprland/plugins/hyprbars.so` |

Confirm:

```bash
hyprctl version | head -1
pacman -Q hyprland
omarchy theme current
omarchy font current
```

## Why not hyprpm

`hyprpm` is the official installer. On this box it was a poor fit:

1. First `hyprpm list` wants `/var/cache/hyprpm/$USER/headersRoot` created with **sudo** (`mkdir -p`). A pkexec prompt is easy to dismiss; without it hyprpm dies with `ensureStateStoreExists: Failed to run a superuser cmd`.
2. Later it `install -o 0 -g 0` every `.so` as **root**, so every enable/update is another sudo.
3. `hyprpm update` clones Hyprland sources into that cache even though Arch already ships headers at `/usr/include/hyprland` (`pkg-config hyprland` works).

Hyprland 0.56.2 already had complete headers (hundreds of files, `hyprland.pc`). Building hyprbars with `make` against those headers is enough.

`cmake`, `meson`, and `ninja` were installed so a future meson build still works. The pin we used builds with the plugin `Makefile`.

```bash
sudo pacman -S --needed cmake meson ninja
```

gcc, git, pkgconf, cpio were already present.

## 1. Build and install the plugin

```bash
mkdir -p ~/.local/src ~/.local/share/hyprland/plugins
git clone --filter=blob:none https://github.com/hyprwm/hyprland-plugins.git ~/.local/src/hyprland-plugins
cd ~/.local/src/hyprland-plugins

# Pin for Hyprland 0.56.2 (from hyprpm.toml: Hyprland commit → plugins commit)
git fetch --depth 1 origin 7644cecdb947060682891a0db2a0cdc5c0b9e704
git checkout --detach 7644cecdb947060682891a0db2a0cdc5c0b9e704

make -C hyprbars all
cp -f hyprbars/hyprbars.so ~/.local/share/hyprland/plugins/hyprbars.so
```

Load once into the running compositor (absolute path required):

```bash
hyprctl plugin load "$HOME/.local/share/hyprland/plugins/hyprbars.so"
hyprctl plugin list
# Plugin hyprbars by Vaxry, version 1.0
```

`PLUGIN_INIT` reloads Hyprland config so the Lua in the next section can call `hl.plugin.hyprbars.add_button`.

After a Hyprland package bump, use [`scripts/rebuild-hyprbars.sh`](scripts/rebuild-hyprbars.sh). It reads the running `hyprctl version` commit, looks up the pin in `hyprpm.toml`, rebuilds, unloads, and loads.

## 2. Config (Lua, after Omarchy defaults)

Omarchy loads user files **after** `$OMARCHY_PATH/default/hypr`, so personal chrome goes in `~/.config/hypr/`, never `/usr/share/omarchy/`.

| File | Role |
| --- | --- |
| [`files/looknfeel-hyprbars.lua`](files/looknfeel-hyprbars.lua) | Append to `~/.config/hypr/looknfeel.lua` |
| [`files/autostart-hyprbars.lua`](files/autostart-hyprbars.lua) | Append to `~/.config/hypr/autostart.lua` |

### Titlebar, colors, buttons

Wrapped in `if hl.plugin and hl.plugin.hyprbars then`. If that guard is omitted, the first config parse (plugin not loaded yet) reports `unknown config key 'plugin.hyprbars.*'`.

hyprbars buttons are **right to left**. First `add_button` is the rightmost control (close), second is hide.

```lua
if hl.plugin and hl.plugin.hyprbars then
  hl.config({
    plugin = {
      hyprbars = {
        enabled = true,
        bar_height = 22,
        bar_color = "rgb(24283b)",
        ["col.text"] = "rgb(c0caf5)",
        bar_text_font = "JetBrainsMono Nerd Font",
        bar_text_size = 11,
        bar_text_align = "left",
        bar_buttons_alignment = "right",
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        bar_padding = 8,
        bar_button_padding = 8,
        icon_on_hover = true,
        inactive_button_color = "rgb(414868)",
      },
    },
  })

  hl.plugin.hyprbars.add_button({
    bg_color = "rgb(f7768e)",
    fg_color = "rgb(1a1b26)",
    size = 12,
    icon = "",
    action = "hyprctl dispatch 'hl.dsp.window.close()'",
  })
  hl.plugin.hyprbars.add_button({
    bg_color = "rgb(e0af68)",
    fg_color = "rgb(1a1b26)",
    size = 12,
    icon = "",
    action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:scratchpad", follow = false })']],
  })
end
```

On Hyprland 0.56, `hyprctl dispatch` is a shorthand for `hl.dispatch(...)`. Legacy names (`killactive`, `movetoworkspacesilent`) fail with a Lua parse error. `hl.dsp.window.close()` is the xdg close request (same as `Super+W`), not `SIGKILL`.

Scratchpad dispatchers already bound by Omarchy:

| Key | Action |
| --- | --- |
| `Super+Alt+S` | Move window to scratchpad (same as the yellow button) |
| `Super+S` | Toggle scratchpad visibility |

`hide_special_on_workspace_change` is on, so changing workspaces also hides the scratchpad.

### Autoload on login

`hyprland.start` only fires once. `PLUGIN_INIT` reloads config, so buttons register after the `.so` is in.

```lua
local hyprbars_so = os.getenv("HOME") .. "/.local/share/hyprland/plugins/hyprbars.so"
o.exec_on_start(
  "test -f "
    .. o.shell_quote(hyprbars_so)
    .. " && { hyprctl plugin list | grep -q hyprbars || hyprctl plugin load "
    .. o.shell_quote(hyprbars_so)
    .. "; }"
)
```

Validate after edits:

```bash
hyprctl reload
hyprctl configerrors
# empty = clean
```

Omarchy does not set `ecosystem.enforce_permissions`, so `hyprctl plugin load` does not pop a permission dialog. If you turn that on later, allow this plugin path (not a blanket allow for `hyprctl`):

```lua
hl.permission({
  binary = os.getenv("HOME") .. "/.local/share/hyprland/plugins/hyprbars.so",
  type = "plugin",
  mode = "allow",
})
```

## 3. Theme support

**What we did:** hardcoded Tokyo Night in `looknfeel.lua`. `omarchy theme set` will **not** restyle the titlebar.

Omarchy themes write border colors from `colors.toml` through `$OMARCHY_PATH/default/themed/hyprland.lua.tpl` into the current theme’s `hyprland.lua`. That template only sets `general.col.active_border` / `inactive_border` and the group-bar equivalents. hyprbars keys are not in it.

Mapping used (Tokyo Night `colors.toml`):

| hyprbars key | Theme token | Hex |
| --- | --- | --- |
| `bar_color` | `lighter_background` | `#24283b` |
| `col.text` | `bright_foreground` | `#c0caf5` |
| close `bg_color` | `red` | `#f7768e` |
| hide `bg_color` | `yellow` | `#e0af68` |
| button `fg_color` | `background` | `#1a1b26` |
| `inactive_button_color` | `muted` | `#414868` |

**If you want it to follow themes later**, either:

1. Overlay per theme: `~/.config/omarchy/themes/<slug>/hyprland.lua` with a `hl.config({ plugin = { hyprbars = { ... } } })` using that theme’s colors, then `omarchy theme set <slug>`. User theme files win over stock. hyprbars still has to be loaded for those keys to apply.
2. Override the generated template: `~/.config/omarchy/themed/hyprland.lua.tpl` copied from the stock template, with hyprbars color lines added from `colors.toml` tokens. That runs for every theme.

Neither is in place on this machine. Buttons (`add_button`) stay in `looknfeel.lua`; only colors need to move into the theme path.

## Caveats

- **Double chrome.** GTK/Qt/Chromium client-side decorations plus hyprbars means two bars. Per-class skip (once the plugin is loaded):

  ```lua
  hl.window_rule({
    match = { class = "chromium" },
    ["hyprbars:no_bar"] = true,
  })
  ```

  Effect names are `hyprbars:no_bar`, `hyprbars:bar_color`, `hyprbars:title_color`. They error if the plugin is not loaded, which is why they were left out of the first pass.

- **Quickshell bar is unrelated.** Hidden windows do not appear as minimized icons there. They live on the scratchpad.
- **`Super+G` groupbar** is Hyprland tab grouping, not this titlebar.
- **ABI.** `HASH != CLIENT_HASH` in `PLUGIN_INIT` refuses to load after a Hyprland upgrade until you rebuild against the new headers.
- **Do not edit** `/usr/share/omarchy/`. Updates overwrite it.

## Unload / undo

```bash
hyprctl plugin unload "$HOME/.local/share/hyprland/plugins/hyprbars.so"
```

Remove the two Lua blocks and the autostart `exec_on_start` so login does not load it again. Deleting the `.so` is enough if autostart already tests `-f`.

## Upstream

- Plugin: https://github.com/hyprwm/hyprland-plugins/tree/main/hyprbars
- Using plugins (Lua): https://wiki.hypr.land/Plugins/Using-Plugins/
- Window rules: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
- Omarchy Hyprland layout: `~/.config/hypr/` after `$OMARCHY_PATH/default/hypr`
