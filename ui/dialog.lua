-- ============================================================
-- CRT Retro Filter - UI Dialog
-- Single-window layout: preview canvas on top, tabs below
-- Fixed dialog width via bounds; all widgets hexpand for alignment
-- Uses Dialog:canvas() and Dialog:tab() (Aseprite v1.3+)
-- Bilingual EN/ZH support via utils/lang.lua
-- ============================================================

local Scanlines = require("filters.scanlines")
local Curvature = require("filters.curvature")
local Aberration = require("filters.aberration")
local Vignette = require("filters.vignette")
local Bloom = require("filters.bloom")
local Noise = require("filters.noise")
local ColorTemp = require("filters.color_temperature")
local Pixelation = require("filters.pixelation")
local RGBMask = require("filters.rgb_mask")
local Ripple = require("filters.horizontal_ripple")
local Jitter = require("filters.interlacing_jitter")
local Persistence = require("filters.phosphor_persistence")
local Lang = require("utils.lang")

local DialogUI = {}

-- ============================================================
-- Preview state
-- ============================================================
local originalPreview = nil
local previewImg = nil
local lastPreviewParams = nil  -- for change detection

-- ============================================================
-- Default parameters
-- ============================================================
local defaults = {
  scanlines_enabled = true, scanlines_intensity = 70, scanlines_thickness = 1, scanlines_offset = 0,
  curvature_enabled = true, curvature_amount = 30, curvature_corner_radius = 0,
  aberration_enabled = true, aberration_shift_r = 2, aberration_shift_b = -2, aberration_falloff = 50,
  vignette_enabled = true, vignette_intensity = 40, vignette_radius = 50, vignette_softness = 50, vignette_ratio = "auto",
  bloom_enabled = true, bloom_threshold = 128, bloom_radius = 3, bloom_intensity = 30,
  noise_enabled = true, noise_intensity = 15, noise_grain_size = 1, noise_monochrome = true,
  color_temp_enabled = false, color_temp_value = 6500, color_temp_intensity = 50,
  pixelation_enabled = false, pixelation_block_size = 2,
  rgb_mask_enabled = false, rgb_mask_intensity = 30, rgb_mask_type = "grille", rgb_mask_width = 1,
  ripple_enabled = false, ripple_amplitude = 2, ripple_frequency = 30, ripple_phase = 0, ripple_falloff = 0,
  jitter_enabled = false, jitter_intensity = 20, jitter_direction = "horizontal",
  persistence_enabled = false, persistence_intensity = 30, persistence_threshold = 160,
}

local paramKeys = {
  "scanlines_enabled", "scanlines_intensity", "scanlines_thickness", "scanlines_offset",
  "curvature_enabled", "curvature_amount", "curvature_corner_radius",
  "aberration_enabled", "aberration_shift_r", "aberration_shift_b", "aberration_falloff",
  "bloom_enabled", "bloom_threshold", "bloom_radius", "bloom_intensity",
  "vignette_enabled", "vignette_intensity", "vignette_radius", "vignette_softness", "vignette_ratio",
  "noise_enabled", "noise_intensity", "noise_grain_size", "noise_monochrome",
  "color_temp_enabled", "color_temp_value", "color_temp_intensity",
  "pixelation_enabled", "pixelation_block_size",
  "rgb_mask_enabled", "rgb_mask_intensity", "rgb_mask_type", "rgb_mask_width",
  "ripple_enabled", "ripple_amplitude", "ripple_frequency", "ripple_phase", "ripple_falloff",
  "jitter_enabled", "jitter_intensity", "jitter_direction",
  "persistence_enabled", "persistence_intensity", "persistence_threshold",
}

-- ============================================================
-- Presets (names are keys into Lang.t, resolved at dialog build time)
-- ============================================================
local presets = {
  {
    name_key = "preset_arcade_name",
    desc_key = "preset_arcade_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 60, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = true, curvature_amount = 35, curvature_corner_radius = 8,
      aberration_enabled = false,
      vignette_enabled = true, vignette_intensity = 45, vignette_radius = 55, vignette_softness = 40, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 140, bloom_radius = 3, bloom_intensity = 25,
      noise_enabled = true, noise_intensity = 10, noise_grain_size = 1, noise_monochrome = true,
    }
  },
  {
    name_key = "preset_80s_name",
    desc_key = "preset_80s_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 50, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = true, curvature_amount = 20, curvature_corner_radius = 4,
      aberration_enabled = true, aberration_shift_r = 1, aberration_shift_b = -1, aberration_falloff = 40,
      vignette_enabled = true, vignette_intensity = 35, vignette_radius = 50, vignette_softness = 50, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 160, bloom_radius = 2, bloom_intensity = 20,
      noise_enabled = true, noise_intensity = 12, noise_grain_size = 1, noise_monochrome = true,
    }
  },
  {
    name_key = "preset_tv_name",
    desc_key = "preset_tv_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 30, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = true, curvature_amount = 50, curvature_corner_radius = 12,
      aberration_enabled = true, aberration_shift_r = 3, aberration_shift_b = -3, aberration_falloff = 60,
      vignette_enabled = true, vignette_intensity = 50, vignette_radius = 40, vignette_softness = 30, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 120, bloom_radius = 4, bloom_intensity = 40,
      noise_enabled = true, noise_intensity = 20, noise_grain_size = 2, noise_monochrome = false,
    }
  },
  {
    name_key = "preset_subtle_name",
    desc_key = "preset_subtle_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 85, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = false,
      aberration_enabled = false,
      vignette_enabled = true, vignette_intensity = 15, vignette_radius = 60, vignette_softness = 60, vignette_ratio = "auto",
      bloom_enabled = false,
      noise_enabled = true, noise_intensity = 5, noise_grain_size = 1, noise_monochrome = true,
    }
  },
  {
    name_key = "preset_monitor_name",
    desc_key = "preset_monitor_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 75, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = true, curvature_amount = 15, curvature_corner_radius = 3,
      aberration_enabled = true, aberration_shift_r = 1, aberration_shift_b = -1, aberration_falloff = 30,
      vignette_enabled = true, vignette_intensity = 25, vignette_radius = 55, vignette_softness = 50, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 150, bloom_radius = 2, bloom_intensity = 15,
      noise_enabled = true, noise_intensity = 8, noise_grain_size = 1, noise_monochrome = true,
      rgb_mask_enabled = true, rgb_mask_intensity = 25, rgb_mask_type = "shadow", rgb_mask_width = 1,
    }
  },
  {
    name_key = "preset_vhs_name",
    desc_key = "preset_vhs_desc",
    params = {
      scanlines_enabled = false,
      curvature_enabled = false,
      aberration_enabled = true, aberration_shift_r = 3, aberration_shift_b = -2, aberration_falloff = 80,
      vignette_enabled = true, vignette_intensity = 30, vignette_radius = 40, vignette_softness = 40, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 180, bloom_radius = 3, bloom_intensity = 20,
      noise_enabled = true, noise_intensity = 25, noise_grain_size = 2, noise_monochrome = false,
      jitter_enabled = true, jitter_intensity = 30, jitter_direction = "horizontal",
      ripple_enabled = true, ripple_amplitude = 2, ripple_frequency = 25, ripple_phase = 0, ripple_falloff = 30,
      color_temp_enabled = true, color_temp_value = 5500, color_temp_intensity = 40,
    }
  },
  {
    name_key = "preset_trinitron_name",
    desc_key = "preset_trinitron_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 55, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = true, curvature_amount = 20, curvature_corner_radius = 5,
      aberration_enabled = false,
      vignette_enabled = true, vignette_intensity = 35, vignette_radius = 50, vignette_softness = 45, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 130, bloom_radius = 2, bloom_intensity = 20,
      noise_enabled = true, noise_intensity = 6, noise_grain_size = 1, noise_monochrome = true,
      rgb_mask_enabled = true, rgb_mask_intensity = 40, rgb_mask_type = "grille", rgb_mask_width = 2,
      persistence_enabled = true, persistence_intensity = 20, persistence_threshold = 150,
    }
  },
  {
    name_key = "preset_pixel_perfect_name",
    desc_key = "preset_pixel_perfect_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 90, scanlines_thickness = 1, scanlines_offset = 0,
      curvature_enabled = false,
      aberration_enabled = false,
      vignette_enabled = true, vignette_intensity = 10, vignette_radius = 65, vignette_softness = 70, vignette_ratio = "auto",
      bloom_enabled = false,
      noise_enabled = false,
      rgb_mask_enabled = false,
    }
  },
  {
    name_key = "preset_glitch_name",
    desc_key = "preset_glitch_desc",
    params = {
      scanlines_enabled = true, scanlines_intensity = 40, scanlines_thickness = 2, scanlines_offset = 1,
      curvature_enabled = true, curvature_amount = 45, curvature_corner_radius = 10,
      aberration_enabled = true, aberration_shift_r = 5, aberration_shift_b = -5, aberration_falloff = 90,
      vignette_enabled = true, vignette_intensity = 55, vignette_radius = 30, vignette_softness = 20, vignette_ratio = "auto",
      bloom_enabled = true, bloom_threshold = 100, bloom_radius = 5, bloom_intensity = 50,
      noise_enabled = true, noise_intensity = 35, noise_grain_size = 3, noise_monochrome = false,
      color_temp_enabled = true, color_temp_value = 4000, color_temp_intensity = 60,
      pixelation_enabled = true, pixelation_block_size = 3,
      rgb_mask_enabled = true, rgb_mask_intensity = 35, rgb_mask_type = "slot", rgb_mask_width = 2,
      ripple_enabled = true, ripple_amplitude = 4, ripple_frequency = 40, ripple_phase = 90, ripple_falloff = 50,
      jitter_enabled = true, jitter_intensity = 40, jitter_direction = "horizontal",
      persistence_enabled = true, persistence_intensity = 40, persistence_threshold = 120,
    }
  },
}

-- ============================================================
-- Scale image to preview size (nearest-neighbor, preserves aspect ratio)
-- ============================================================
local function scaleToPreviewSize(img, maxDim)
  maxDim = maxDim or 160
  local w = img.width
  local h = img.height
  local cur_max = math.max(w, h)
  if cur_max == 0 then return img:clone() end

  local scale = 1.0
  if cur_max < 96 then
    scale = 96.0 / cur_max
  elseif cur_max > maxDim then
    scale = maxDim / cur_max
  end

  local new_w = math.max(1, math.floor(w * scale))
  local new_h = math.max(1, math.floor(h * scale))

  if new_w == w and new_h == h then
    return img:clone()
  end

  local result = Image(new_w, new_h, img.colorMode)
  for it in result:pixels() do
    local sx = math.max(0, math.min(w - 1, math.floor(it.x / scale)))
    local sy = math.max(0, math.min(h - 1, math.floor(it.y / scale)))
    it(img:getPixel(sx, sy))
  end
  return result
end

-- ============================================================
-- Sync dialog data -> params
-- ============================================================
local function syncParams(dlg, params)
  local d = dlg.data
  for _, k in ipairs(paramKeys) do
    local v = d[k]
    if v ~= nil then
      if k == "rgb_mask_type" then
        params[k] = (v == "Shadow Mask" or v == "点阵遮罩") and "shadow"
          or (v == "Slot Mask" or v == "槽状遮罩") and "slot" or "grille"
      elseif k == "jitter_direction" then
        params[k] = (v == "Vertical" or v == "垂直") and "vertical" or "horizontal"
      else
        params[k] = v
      end
    end
  end
end

-- ============================================================
-- Apply preset to dialog
-- ============================================================
local function applyPresetToDialog(dlg, preset_params, params, T)
  -- Step 1: reset all params to defaults
  for k, v in pairs(defaults) do
    params[k] = v
  end
  -- Step 2: apply preset values on top
  for k, v in pairs(preset_params) do
    params[k] = v
  end
  -- Step 3: update all dialog controls
  for k, v in pairs(params) do
    if k == "rgb_mask_type" then
      local label = (v == "shadow") and T.mask_shadow or (v == "slot") and T.mask_slot or T.mask_grille
      pcall(function() dlg:modify{ id = k, text = label } end)
    elseif k == "jitter_direction" then
      local label = (v == "vertical") and T.dir_vertical or T.dir_horizontal
      pcall(function() dlg:modify{ id = k, text = label } end)
    elseif k == "vignette_ratio" then
      local label = (v == "1:1" and T.ratio_1_1 or v == "4:3" and T.ratio_4_3 or v == "16:9" and T.ratio_16_9 or T.ratio_auto)
      pcall(function() dlg:modify{ id = k, text = label } end)
    elseif type(v) == "boolean" then
      pcall(function() dlg:modify{ id = k, selected = v } end)
    else
      pcall(function() dlg:modify{ id = k, text = tostring(v) } end)
    end
  end
end

-- ============================================================
-- Apply all filters (passes full params table to each filter)
-- ============================================================
function DialogUI.applyFilters(image, params)
  local img = image

  if params.pixelation_enabled and params.pixelation_block_size > 1 then
    img = Pixelation.apply(img, params)
  end
  if params.curvature_enabled and params.curvature_amount > 0 then
    img = Curvature.apply(img, params)
  end
  if params.aberration_enabled then
    Aberration.apply(img, params)
  end
  if params.ripple_enabled and params.ripple_amplitude > 0 then
    Ripple.apply(img, params)
  end
  if params.jitter_enabled and params.jitter_intensity > 0 then
    Jitter.apply(img, params)
  end
  if params.scanlines_enabled then
    Scanlines.apply(img, params)
  end
  if params.rgb_mask_enabled then
    RGBMask.apply(img, params)
  end
  if params.bloom_enabled and params.bloom_intensity > 0 then
    img = Bloom.apply(img, params)
  end
  if params.persistence_enabled and params.persistence_intensity > 0 then
    Persistence.apply(img, params)
  end
  if params.vignette_enabled then
    Vignette.apply(img, params)
  end
  if params.color_temp_enabled and params.color_temp_intensity > 0 then
    ColorTemp.apply(img, params)
  end
  if params.noise_enabled then
    Noise.apply(img, params)
  end

  return img
end

-- ============================================================
-- Build and show the dialog
-- ============================================================
function DialogUI.show(plugin)
  local cel = app.activeCel
  local prefs = plugin.preferences
  local T = Lang.get(prefs) -- current language strings

  if not cel then
    app.alert(T.no_image)
    return
  end

  if cel.image.colorMode == ColorMode.INDEXED then
    app.alert(T.indexed_error)
    return
  end
  if cel.image.colorMode == ColorMode.GRAY then
    app.alert(T.grayscale_error)
    return
  end

  -- Ensure language preference exists
  if not prefs.lang then prefs.lang = "en" end

  -- Initialize params
  if not prefs.params then
    prefs.params = {}
    for k, v in pairs(defaults) do prefs.params[k] = v end
  end
  local params = prefs.params

  -- Scale original to preview size (preserves aspect ratio)
  originalPreview = scaleToPreviewSize(cel.image, 160)
  previewImg = originalPreview:clone()
  previewImg = DialogUI.applyFilters(previewImg, params)

  -- Canvas = preview image size + margin (auto-adjusts to image aspect ratio)
  local margin = 12
  local canvasW = originalPreview.width + margin * 2
  local canvasH = originalPreview.height + margin * 2

  local dlg = Dialog(T.dialog_title)

  -- ===== Preview canvas (top, always visible) =====
  dlg:canvas{
    id = "preview_canvas",
    width = canvasW,
    height = canvasH,
    autoscaling = true,
    onpaint = function(ev)
      local gc = ev.context
      gc:fillRect(Rectangle(0, 0, canvasW, canvasH), app.pixelColor.rgba(12, 12, 18, 255))
      if previewImg then
        local x = math.floor((canvasW - previewImg.width) / 2)
        local y = math.floor((canvasH - previewImg.height) / 2)
        gc:drawImage(previewImg, x, y)
      end
    end
  }

  -- ===== Real-time preview update with change detection =====
	local function updatePreview()
	  if not originalPreview then return end
	  syncParams(dlg, params)

	  -- Skip recomputation if no params changed since last preview
	  if lastPreviewParams then
	    local changed = false
	    for _, k in ipairs(paramKeys) do
	      if params[k] ~= lastPreviewParams[k] then
	        changed = true
	        break
	      end
	    end
	    if not changed then return end
	  end

	  -- Snapshot current params for next comparison
	  if not lastPreviewParams then lastPreviewParams = {} end
	  for _, k in ipairs(paramKeys) do
	    lastPreviewParams[k] = params[k]
	  end

	  previewImg = originalPreview:clone()
	  previewImg = DialogUI.applyFilters(previewImg, params)
	  dlg:repaint()
	end

  -- Build preset names in current language
  local preset_names = {}
  for _, p in ipairs(presets) do
    table.insert(preset_names, T[p.name_key])
  end

  -- ===== Tab: Presets =====
  dlg:tab{ id = "tab_presets", text = T.tab_presets }

  -- Language selector
  dlg:combobox{
    id = "lang_select",
    label = T.lang_label,
    option = Lang.names[prefs.lang] or "English",
    options = { "English", "中文" },
    hexpand = true,
    onchange = function()
      local chosen = dlg.data.lang_select
      local new_lang = (chosen == "中文") and "zh" or "en"
      if new_lang ~= prefs.lang then
        prefs.lang = new_lang
        dlg:close()
        DialogUI.show(plugin)
      end
    end
  }

  dlg:combobox{
    id = "preset_select",
    label = T.preset_label,
    option = T.preset_custom, hexpand = true,
    options = preset_names,
    onchange = function()
      local selected = dlg.data.preset_select
      for _, p in ipairs(presets) do
        if T[p.name_key] == selected then
          applyPresetToDialog(dlg, p.params, params, T)
          updatePreview()
          break
        end
      end
    end
  }

  dlg:label{ text = "" }
  dlg:check{ id = "dup_layer", label = T.dup_layer, selected = prefs.dup_layer or false }

  dlg:button{ id = "disable_all", text = T.disable_all_btn, hexpand = false,
    onclick = function()
      local enabled_keys = {
        "scanlines_enabled", "curvature_enabled", "aberration_enabled",
        "vignette_enabled", "bloom_enabled", "noise_enabled",
        "color_temp_enabled", "pixelation_enabled", "rgb_mask_enabled",
        "ripple_enabled", "jitter_enabled", "persistence_enabled"
      }
      for _, k in ipairs(enabled_keys) do
        params[k] = false
        pcall(function() dlg:modify{ id = k, selected = false } end)
      end
      updatePreview()
      dlg:repaint()
    end
  }
  dlg:button{ id = "reset_default", text = T.reset_default_btn, hexpand = false,
    onclick = function()
      applyPresetToDialog(dlg, {}, params, T)
      updatePreview()
      dlg:repaint()
    end
  }

  -- ===== Custom Presets =====
  if not prefs.custom_presets then prefs.custom_presets = {} end

  dlg:separator{ text = T.custom_presets }

  -- Build custom preset name list
  local custom_names = {}
  for name, _ in pairs(prefs.custom_presets) do
    table.insert(custom_names, name)
  end
  table.sort(custom_names)

  local custom_options = {}
  for _, name in ipairs(custom_names) do
    table.insert(custom_options, name)
  end

  if #custom_options > 0 then
    dlg:combobox{
      id = "custom_preset_select",
      label = T.preset_label,
      option = custom_options[1],
      options = custom_options,
      hexpand = true,
      onchange = function()
        local selected = dlg.data.custom_preset_select
        local cp = prefs.custom_presets[selected]
        if cp then
          applyPresetToDialog(dlg, cp, params, T)
          updatePreview()
        end
      end
    }
    dlg:button{ id = "delete_custom", text = T.delete_preset, hexpand = false,
      onclick = function()
        local selected = dlg.data.custom_preset_select
        if selected and prefs.custom_presets[selected] then
          prefs.custom_presets[selected] = nil
          app.alert(T.preset_deleted .. selected)
          dlg:close()
          DialogUI.show(plugin)
        else
          app.alert(T.preset_not_found)
        end
      end }
  else
    dlg:label{ text = "  " .. T.no_custom_presets }
  end

  dlg:button{ id = "save_custom", text = T.save_preset, hexpand = false,
    onclick = function()
      syncParams(dlg, params)
      local nameDlg = Dialog(T.preset_name_prompt)
      nameDlg:entry{ id = "preset_name", label = T.preset_label, text = "", hexpand = true }
      nameDlg:button{ id = "confirm", text = T.apply, focus = true }
      nameDlg:button{ id = "abort", text = T.cancel }
      nameDlg:show()
      local nameData = nameDlg.data
      if nameData.confirm and nameData.preset_name and nameData.preset_name ~= "" then
        local pname = nameData.preset_name
        if prefs.custom_presets[pname] then
          app.alert(T.preset_name_exists)
          return
        end
        -- Deep copy current params
        local saved = {}
        for _, k in ipairs(paramKeys) do
          saved[k] = params[k]
        end
        prefs.custom_presets[pname] = saved
        app.alert(T.preset_saved .. pname)
        dlg:close()
        DialogUI.show(plugin)
      elseif nameData.confirm then
        app.alert(T.preset_name_empty)
      end
    end }

  -- ===== Tab: Screen =====
  dlg:tab{ id = "tab_screen", text = T.tab_screen }

  dlg:separator{ text = T.sep_scanlines }
  dlg:check{ id = "scanlines_enabled", label = T.enable, selected = params.scanlines_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "scanlines_intensity", label = T.intensity, min = 0, max = 100, value = params.scanlines_intensity, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "scanlines_thickness", label = T.thickness, min = 1, max = 4, value = params.scanlines_thickness, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:separator{ text = T.sep_curvature }
  dlg:check{ id = "curvature_enabled", label = T.enable, selected = params.curvature_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "curvature_amount", label = T.curvature, min = -100, max = 100, value = params.curvature_amount, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "curvature_corner_radius", label = T.corner, min = 0, max = 100, value = params.curvature_corner_radius, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:separator{ text = T.sep_aberration }
  dlg:check{ id = "aberration_enabled", label = T.enable, selected = params.aberration_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "aberration_shift_r", label = T.red_shift, min = -5, max = 5, value = params.aberration_shift_r, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "aberration_shift_b", label = T.blue_shift, min = -5, max = 5, value = params.aberration_shift_b, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "aberration_falloff", label = T.falloff, min = 0, max = 100, value = params.aberration_falloff, hexpand = true,
    onchange = function() updatePreview() end }

  -- ===== Tab: Display =====
  dlg:tab{ id = "tab_display", text = T.tab_display }

  dlg:separator{ text = T.sep_bloom }
  dlg:check{ id = "bloom_enabled", label = T.enable, selected = params.bloom_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "bloom_threshold", label = T.threshold, min = 0, max = 255, value = params.bloom_threshold, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "bloom_radius", label = T.radius, min = 1, max = 10, value = params.bloom_radius, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "bloom_intensity", label = T.intensity, min = 0, max = 100, value = params.bloom_intensity, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:separator{ text = T.sep_vignette }
  dlg:check{ id = "vignette_enabled", label = T.enable, selected = params.vignette_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "vignette_intensity", label = T.intensity, min = 0, max = 100, value = params.vignette_intensity, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "vignette_radius", label = T.inner, min = 0, max = 100, value = params.vignette_radius, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "vignette_softness", label = T.softness, min = 0, max = 100, value = params.vignette_softness, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:combobox{ id = "vignette_ratio", label = T.ratio,
    option = (params.vignette_ratio == "1:1" and T.ratio_1_1 or params.vignette_ratio == "4:3" and T.ratio_4_3 or params.vignette_ratio == "16:9" and T.ratio_16_9 or T.ratio_auto),
    options = { T.ratio_auto, T.ratio_1_1, T.ratio_4_3, T.ratio_16_9 },
    hexpand = true,
    onchange = function()
      local v = dlg.data.vignette_ratio
      if v == T.ratio_1_1 then params.vignette_ratio = "1:1"
      elseif v == T.ratio_4_3 then params.vignette_ratio = "4:3"
      elseif v == T.ratio_16_9 then params.vignette_ratio = "16:9"
      else params.vignette_ratio = "auto" end
      updatePreview()
    end
  }

  dlg:separator{ text = T.sep_noise }
  dlg:check{ id = "noise_enabled", label = T.enable, selected = params.noise_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "noise_intensity", label = T.intensity, min = 0, max = 100, value = params.noise_intensity, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "noise_grain_size", label = T.grain, min = 1, max = 4, value = params.noise_grain_size, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:check{ id = "noise_monochrome", label = T.monochrome, selected = params.noise_monochrome,
    onclick = function() updatePreview() end }

  -- ===== Tab: Pixel =====
  dlg:tab{ id = "tab_pixel", text = T.tab_pixel }

  dlg:separator{ text = T.sep_color_temp }
  dlg:check{ id = "color_temp_enabled", label = T.enable, selected = params.color_temp_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "color_temp_value", label = T.color_temp_value, min = 3000, max = 9300, value = params.color_temp_value, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "color_temp_intensity", label = T.intensity, min = 0, max = 100, value = params.color_temp_intensity, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:separator{ text = T.sep_pixelation }
  dlg:check{ id = "pixelation_enabled", label = T.enable, selected = params.pixelation_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "pixelation_block_size", label = T.block_size, min = 1, max = 8, value = params.pixelation_block_size, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:separator{ text = T.sep_rgb_mask }
  dlg:check{ id = "rgb_mask_enabled", label = T.enable, selected = params.rgb_mask_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "rgb_mask_intensity", label = T.intensity, min = 0, max = 100, value = params.rgb_mask_intensity, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "rgb_mask_width", label = T.stripe_width, min = 1, max = 4, value = params.rgb_mask_width, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:combobox{
    id = "rgb_mask_type",
    label = T.mask_type,
    option = (params.rgb_mask_type == "shadow") and T.mask_shadow
      or (params.rgb_mask_type == "slot") and T.mask_slot
      or T.mask_grille,
    options = { T.mask_grille, T.mask_shadow, T.mask_slot },
    hexpand = true,
    onchange = function()
      local v = dlg.data.rgb_mask_type
      params.rgb_mask_type = (v == T.mask_shadow) and "shadow"
        or (v == T.mask_slot) and "slot" or "grille"
      updatePreview()
    end
  }

  -- ===== Tab: Signal =====
  dlg:tab{ id = "tab_signal", text = T.tab_signal }

  dlg:separator{ text = T.sep_ripple }
  dlg:check{ id = "ripple_enabled", label = T.enable, selected = params.ripple_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "ripple_amplitude", label = T.amplitude, min = 0, max = 10, value = params.ripple_amplitude, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "ripple_frequency", label = T.frequency, min = 0, max = 100, value = params.ripple_frequency, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "ripple_phase", label = T.phase, min = 0, max = 360, value = params.ripple_phase, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "ripple_falloff", label = T.falloff, min = 0, max = 100, value = params.ripple_falloff, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:separator{ text = T.sep_jitter }
  dlg:check{ id = "jitter_enabled", label = T.enable, selected = params.jitter_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "jitter_intensity", label = T.intensity, min = 0, max = 100, value = params.jitter_intensity, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:combobox{
    id = "jitter_direction",
    label = T.direction,
    option = (params.jitter_direction == "vertical") and T.dir_vertical or T.dir_horizontal,
    options = { T.dir_horizontal, T.dir_vertical },
    hexpand = true,
    onchange = function()
      params.jitter_direction = (dlg.data.jitter_direction == T.dir_vertical) and "vertical" or "horizontal"
      updatePreview()
    end
  }

  dlg:separator{ text = T.sep_persistence }
  dlg:check{ id = "persistence_enabled", label = T.enable, selected = params.persistence_enabled,
    onclick = function() updatePreview() end }
  dlg:slider{ id = "persistence_intensity", label = T.intensity, min = 0, max = 100, value = params.persistence_intensity, hexpand = true,
    onchange = function() updatePreview() end }
  dlg:slider{ id = "persistence_threshold", label = T.threshold, min = 0, max = 255, value = params.persistence_threshold, hexpand = true,
    onchange = function() updatePreview() end }

  dlg:endtabs{ selected = "tab_presets" }

  -- ===== Buttons =====
  dlg:separator{}
  dlg:button{ id = "randomize", text = T.randomize_btn, hexpand = false,
    onclick = function()
      math.randomseed(os.time())
      local r = {
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
        vignette_ratio = ({"auto", "1:1", "4:3", "16:9"})[math.random(1, 4)],
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

      -- Update params and dialog controls
      for k, v in pairs(r) do
        params[k] = v
        if k == "rgb_mask_type" then
          local label = (v == "shadow") and T.mask_shadow or (v == "slot") and T.mask_slot or T.mask_grille
          pcall(function() dlg:modify{ id = k, text = label } end)
        elseif k == "jitter_direction" then
          local label = (v == "vertical") and T.dir_vertical or T.dir_horizontal
          pcall(function() dlg:modify{ id = k, text = label } end)
        elseif k == "vignette_ratio" then
          local label = (v == "1:1" and T.ratio_1_1 or v == "4:3" and T.ratio_4_3 or v == "16:9" and T.ratio_16_9 or T.ratio_auto)
          pcall(function() dlg:modify{ id = k, text = label } end)
        elseif type(v) == "boolean" then
          pcall(function() dlg:modify{ id = k, selected = v } end)
        else
          pcall(function() dlg:modify{ id = k, text = tostring(v) } end)
        end
      end

      updatePreview()
      dlg:repaint()
    end
  }
  dlg:button{ id = "apply", text = T.apply, focus = true, hexpand = false }
  dlg:button{ id = "cancel", text = T.cancel, hexpand = false }

  -- Dialog width = 1/4 of screen width, accounting for UI scale
  local uiScale = app.uiScale or 1.0
  local dialogWidth = math.max(240, math.floor(480 / uiScale))
  dlg.bounds = Rectangle(0, 0, dialogWidth, 0)
  dlg:show{ autoscrollbars = true }
  local data = dlg.data

  if data.apply then
    syncParams(dlg, params)
    prefs.params = params
    prefs.dup_layer = data.dup_layer

    local sprite = app.activeSprite
    DialogUI.applyToActiveLayer(sprite, params, T, data.dup_layer)
  end

  originalPreview = nil
  previewImg = nil
  lastPreviewParams = nil
end

-- ============================================================
-- Apply filter to the active layer only
-- ============================================================
function DialogUI.applyToActiveLayer(sprite, params, T, duplicate)
  if not sprite then return end

  local layer = app.activeLayer
  if not layer then
    app.alert(T.no_image)
    return
  end

  local cel = app.activeCel
  if not cel then
    app.alert(T.no_image)
    return
  end

  if cel.image.colorMode == ColorMode.INDEXED then
    app.alert(T.indexed_error)
    return
  end
  if cel.image.colorMode == ColorMode.GRAY then
    app.alert(T.grayscale_error)
    return
  end

  app.transaction(T.txn_single, function()
    if duplicate then
      local newLayer = sprite:newLayer()
      newLayer.name = layer.name .. " CRT"
      local newCel = sprite:newCel(newLayer, cel.frame)
      newCel.image = cel.image:clone()
      newCel.position = cel.position
      local img = newCel.image:clone()
      img = DialogUI.applyFilters(img, params)
      newCel.image = img
    else
      local img = cel.image:clone()
      img = DialogUI.applyFilters(img, params)
      cel.image = img
    end
  end)

  app.refresh()
end

return DialogUI