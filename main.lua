-- ============================================================
-- CRT Retro Filter - Main Entry Point
-- Registers plugin commands and menu items
-- Requires Aseprite v1.3.0+ (API version 21+)
-- ============================================================

local DialogUI = require("ui.dialog")
local Lang = require("utils.lang")

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

      DialogUI.applyToActiveLayer(app.activeSprite, prefs.params, T, prefs.dup_layer or false)
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

      math.randomseed(os.time())
      local params = {
        scanlines_enabled = math.random() > 0.5,
        scanlines_intensity = math.random(30, 100),
        scanlines_thickness = math.random(1, 3),
        scanlines_offset = math.random(0, 1),
        curvature_enabled = math.random() > 0.5,
        curvature_amount = math.random(-100, 100),
        curvature_corner_radius = math.random(0, 15),
        aberration_enabled = math.random() > 0.5,
        aberration_shift_r = math.random(-5, 5),
        aberration_shift_b = math.random(-5, 5),
        aberration_falloff = math.random(0, 100),
        vignette_enabled = math.random() > 0.5,
        vignette_intensity = math.random(0, 60),
        vignette_radius = math.random(20, 80),
        vignette_softness = math.random(20, 80),
        bloom_enabled = math.random() > 0.5,
        bloom_threshold = math.random(80, 200),
        bloom_radius = math.random(1, 5),
        bloom_intensity = math.random(0, 60),
        noise_enabled = math.random() > 0.5,
        noise_intensity = math.random(0, 30),
        noise_grain_size = math.random(1, 3),
        noise_monochrome = math.random() > 0.5,
        color_temp_enabled = math.random() > 0.5,
        color_temp_value = math.random(3000, 9000),
        color_temp_intensity = math.random(10, 80),
        pixelation_enabled = math.random() > 0.5,
        pixelation_block_size = math.random(2, 6),
        rgb_mask_enabled = math.random() > 0.5,
        rgb_mask_intensity = math.random(10, 60),
        rgb_mask_type = ({"grille", "shadow", "slot"})[math.random(1, 3)],
        rgb_mask_width = math.random(1, 3),
        ripple_enabled = math.random() > 0.5,
        ripple_amplitude = math.random(1, 5),
        ripple_frequency = math.random(10, 60),
        ripple_phase = math.random(0, 360),
        ripple_falloff = math.random(0, 100),
        jitter_enabled = math.random() > 0.5,
        jitter_intensity = math.random(5, 40),
        jitter_direction = math.random() > 0.5 and "horizontal" or "vertical",
        persistence_enabled = math.random() > 0.5,
        persistence_intensity = math.random(10, 50),
        persistence_threshold = math.random(100, 200),
      }

      app.transaction("CRT Randomize", function()
        DialogUI.applyToActiveLayer(app.activeSprite, params, T)
      end)
      app.refresh()
    end
  }
end

function exit(plugin)
  -- Cleanup if needed
end