-- Append to ~/.config/hypr/looknfeel.lua
-- hyprbars: small titlebar with hide (scratchpad) and close.
-- Plugin binary: ~/.local/share/hyprland/plugins/hyprbars.so
-- Applied only after the plugin is loaded so unknown-key errors stay gone.
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

  -- Rightmost first: close, then hide.
  -- Hyprland 0.56: hyprctl dispatch is Lua (`hl.dsp.*`). Legacy names like
  -- killactive / movetoworkspacesilent fail with a parse error.
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
