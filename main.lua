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

  -- Register the main command: apply CRT filters
  plugin:newCommand{
    id = "CRT_Retro_Filter",
    title = "CRT Retro Filter",
    group = "edit_fx",
    onenabled = function()
      return app.activeCel ~= nil
    end,
    onclick = function()
      DialogUI.show(plugin)
    end
  }

  -- Register a quick-apply command: re-apply with last saved settings
  plugin:newCommand{
    id = "CRT_Retro_Filter_QuickApply",
    title = "CRT Retro Filter (Quick Apply)",
    group = "edit_fx",
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

      DialogUI.applyToActiveLayer(app.activeSprite, prefs.params, T, prefs.dup_layer or false, prefs.sel_only or false)
    end
  }

  -- Register a randomize command for keyboard shortcut binding
  plugin:newCommand{
    id = "CRT_Retro_Filter_Randomize",
    title = "CRT Retro Filter (Randomize)",
    group = "edit_fx",
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

      app.transaction("CRT Randomize", function()
        DialogUI.applyToActiveLayer(app.activeSprite, params, T, false, prefs.sel_only or false)
      end)
      app.refresh()
    end
  }
end

function exit(plugin)
  -- Cleanup if needed
end