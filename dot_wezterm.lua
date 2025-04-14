local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local function get_mise_path(tool)
  local handle = io.popen("mise which " .. tool)
  if handle then
    local result = handle:read("*a")
    handle:close()

    result = result:gsub("^%s+", ""):gsub("%s+$", "")
    if result ~= "" then
      return result
    end
  end
  return nil
end

local zoxide_path = get_mise_path("zoxide") or "/usr/bin/zoxide"

config.tab_bar_at_bottom = true

config.font = wezterm.font("JetBrainsMono NF")

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

tabline.setup({
  options = {
    tabs_enabled = false,
  },
})

tabline.apply_to_config(config)

local workspace_switcher = wezterm.plugin.require("https://github.com/MLFlexer/smart_workspace_switcher.wezterm")

workspace_switcher.zoxide_path = zoxide_path

workspace_switcher.apply_to_config(config)

-- This has to come after the call to `tabline.apply_to_config`
-- as the plugin will override it
config.window_decorations = "TITLE | RESIZE"

local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

wezterm.on("augment-command-palette", function(window, pane)
  return {
    {
      brief = "Rename tab",
      icon = "md_rename_box",
      action = act.PromptInputLine({
        description = "Enter new name for tab",
        action = wezterm.action_callback(function(window, pane, line)
          if line then
            window:active_tab():set_title(line)
          end
        end),
      }),
    },
  }
end)

config.color_scheme = "Bamboo"

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
  {
    key = ",",
    mods = "LEADER",
    action = act.PromptInputLine({
      description = "Enter new name for tab",
      -- initial_value = 'My Tab Name',
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }),
  },
  {
    key = "l",
    mods = "LEADER|SHIFT",
    action = act.ActivateLastTab,
  },
  {
    key = "c",
    mods = "LEADER",
    action = act.SpawnTab("CurrentPaneDomain"),
  },
  {
    key = "n",
    mods = "LEADER",
    action = act.ActivateTabRelative(1),
  },
  {
    key = "p",
    mods = "LEADER",
    action = act.ActivateTabRelative(-1),
  },
  {
    key = "|",
    mods = "LEADER|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "-",
    mods = "LEADER",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "h",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Left"),
  },
  {
    key = "l",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Right"),
  },
  {
    key = "k",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Up"),
  },
  {
    key = "j",
    mods = "LEADER",
    action = act.ActivatePaneDirection("Down"),
  },
  -- Send "CTRL-A" to the terminal when pressing CTRL-A, CTRL-A
  {
    key = "a",
    mods = "LEADER|CTRL",
    action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
  },
  {
    key = "s",
    mods = "LEADER",
    action = workspace_switcher.switch_workspace(),
  },
  {
    key = "S",
    mods = "LEADER",
    action = workspace_switcher.switch_to_prev_workspace(),
  },
  {
    key = "PageUp",
    mods = "",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "PageUp",
    action = wezterm.action.ScrollByPage(-1),
  },
  {
    key = "PageDown",
    action = wezterm.action.ScrollByPage(1),
  },
  {
    key = "PageUp",
    mods = "ALT",
    action = wezterm.action.ScrollByPage(-1),
  },
  {
    key = "PageDown",
    mods = "ALT",
    action = wezterm.action.ScrollByPage(1),
  },
  {
    key = "UpArrow",
    mods = "ALT",
    action = wezterm.action.ScrollByLine(-1),
  },
  {
    key = "DownArrow",
    mods = "ALT",
    action = wezterm.action.ScrollByLine(1),
  },
  {
    key = "[",
    mods = "LEADER",
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = "w",
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  {
    key = "W",
    mods = "ALT",
    action = resurrect.window_state.save_window_action(),
  },
  {
    key = "T",
    mods = "ALT",
    action = resurrect.tab_state.save_tab_action(),
  },
  {
    key = "s",
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
      resurrect.window_state.save_window_action()
    end),
  },
  {
    key = "r",
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)") -- match before '/'
        id = string.match(id, "([^/]+)$") -- match after '/'
        id = string.match(id, "(.+)%..+$") -- remove file extention
        local opts = {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        }
        if type == "workspace" then
          local state = resurrect.state_manager.load_state(id, "workspace")
          win:perform_action(
            wezterm.action.SwitchToWorkspace({
              name = state.workspace,
            }),
            pane
          )
          resurrect.workspace_state.restore_workspace(state, opts)
        elseif type == "window" then
          local state = resurrect.state_manager.load_state(id, "window")
          resurrect.window_state.restore_window(pane:window(), state, opts)
        elseif type == "tab" then
          local state = resurrect.state_manager.load_state(id, "tab")
          resurrect.tab_state.restore_tab(pane:tab(), state, opts)
        end
      end)
    end),
  },
  {
    key = "d",
    mods = "ALT",
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
        resurrect.state_manager.delete_state(id)
      end, {
        title = "Delete State",
        description = "Select State to Delete and press Enter = accept, Esc = cancel, / = filter",
        fuzzy_description = "Search State to Delete: ",
        is_fuzzy = true,
      })
    end),
  },
}

return config
