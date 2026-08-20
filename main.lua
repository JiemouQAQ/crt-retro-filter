-- ============================================================
-- CRT Retro Filter - Main Entry Point
-- Registers plugin commands and menu items
-- Requires Aseprite v1.3.0+ (API version 21+)
-- ============================================================

local DialogUI = require("ui.dialog")
local Lang = require("utils.lang")
local MathUtils = require("utils.math")

function init(plugin)
  -- Check API version: v1.3.0 = apiVersion 21, v1.3.11 = apiVersion 31
  if app.apiVersion == nil or app.apiVersion < 21 then
    app.alert(
      "CRT Retro Filter requires Aseprite v1.3.0 or newer.\n\n" ..
      "Detected API version: " .. tostring(app.apiVersion or "pre-1.2.10") .. "\n" ..
      "Please update Aseprite to continue."
    )
    return
  end

  -- Seed the RNG once with high-entropy state so consecutive
  -- Randomize clicks never produce identical results.
  MathUtils.seedRandom()

  -- Menu organization: group all commands under a "CRT Retro Filter"
  -- submenu when the API supports it; fall back to the flat Edit menu
  -- on older Aseprite versions. Command ids stay stable, so user-bound
  -- keyboard shortcuts keep working regardless of menu layout.
  local menuGroup = "edit_fx"
  if plugin.newMenuGroup then
    plugin:newMenuGroup{
      id = "CRT_Retro_Filter_Menu",
      title = "CRT Retro Filter",
      group = "edit_fx"
    }
    menuGroup = "CRT_Retro_Filter_Menu"
  end

  -- Register the main command: open the filter dialog
  plugin:newCommand{
    id = "CRT_Retro_Filter",
    title = "Open Dialog...",
    group = menuGroup,
    onenabled = function()
      return app.activeCel ~= nil
    end,
    onclick = function()
      DialogUI.show(plugin)
    end
  }

  -- Separate the main entry from the quick actions
  if plugin.newMenuSeparator then
    plugin:newMenuSeparator{ group = menuGroup }
  end

  -- Register a quick-apply command: re-apply with last saved settings.
  -- No default shortcut is assigned; bind one in Edit → Keyboard Shortcuts.
  plugin:newCommand{
    id = "CRT_Retro_Filter_QuickApply",
    title = "Quick Apply",
    group = menuGroup,
    onenabled = function()
      return app.activeCel ~= nil
    end,
    onclick = function()
      local cel = app.activeCel
      local T = Lang.get(plugin.preferences)
      if not cel then
        app.alert(T.no_image)
        return
      end

      local prefs = plugin.preferences
      if not prefs.params then
        app.alert("No saved settings. Use 'CRT Retro Filter' first to configure.")
        return
      end

      DialogUI.applyToActiveLayer(app.activeSprite, prefs.params, T, prefs.dup_layer or false, prefs.sel_only or false, prefs.all_frames or false)
    end
  }

  -- Register a randomize command. No default shortcut is assigned;
  -- bind e.g. Ctrl+Shift+R in Edit → Keyboard Shortcuts.
  plugin:newCommand{
    id = "CRT_Retro_Filter_Randomize",
    title = "Randomize",
    group = menuGroup,
    onenabled = function()
      return app.activeCel ~= nil
    end,
    onclick = function()
      local cel = app.activeCel
      local T = Lang.get(plugin.preferences)
      if not cel then
        app.alert(T.no_image)
        return
      end

      local params = DialogUI.generateRandomParams()
      local prefs = plugin.preferences
      -- keep the user's global strength dial when randomizing from the menu
      local savedParams = prefs.params
      params.global_strength = (savedParams and savedParams.global_strength) or 100

      app.transaction("CRT Randomize", function()
        DialogUI.applyToActiveLayer(app.activeSprite, params, T, false, prefs.sel_only or false, prefs.all_frames or false)
      end)
      app.refresh()
    end
  }
end

function exit(plugin)
  -- Cleanup if needed
end