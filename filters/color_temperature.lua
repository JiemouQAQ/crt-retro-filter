-- ============================================================
-- CRT Retro Filter - Color Temperature
-- Simulates CRT color temperature bias by adjusting RGB channel
-- gains. Warm (low K) boosts red, cool (high K) boosts blue.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local ColorTemp = {}

-- Convert kelvin temperature to RGB gain multipliers
-- Uses simplified interpolation between 3 key color temperatures
local function kelvinToGains(kelvin)
  -- Key points: 3000K (warm), 6500K (neutral), 9300K (cool)
  if kelvin <= 3000 then
    return 1.0, 0.85, 0.65
  elseif kelvin >= 9300 then
    return 0.85, 0.93, 1.0
  elseif kelvin <= 6500 then
    -- Interpolate 3000K -> 6500K
    local t = (kelvin - 3000) / 3500
    return 1.0, 0.85 + 0.15 * t, 0.65 + 0.35 * t
  else
    -- Interpolate 6500K -> 9300K
    local t = (kelvin - 6500) / 2800
    return 1.0 - 0.15 * t, 1.0 - 0.07 * t, 1.0
  end
end

-- Apply color temperature to image (modifies in-place)
-- params:
--   color_temp_enabled: boolean
--   color_temp_value: 3000-9300 (kelvin)
--   color_temp_intensity: 0-100 (blend strength)
function ColorTemp.apply(image, params)
  local enabled = params.color_temp_enabled
  if enabled == false then return end

  local kelvin = params.color_temp_value or 6500
  local intensity = (params.color_temp_intensity or 50) / 100.0

  -- Parameter animation (mechanism B): gentle warm/cool drift.
  if params.anim_enabled and params._frame then
    kelvin = kelvin + MathUtils.animWave(params, 90, -800, 800)
  end

  if intensity <= 0 then return end

  local rGain, gGain, bGain = kelvinToGains(kelvin)

  -- Blend from identity (1,1,1) to target gains based on intensity
  rGain = 1.0 + (rGain - 1.0) * intensity
  gGain = 1.0 + (gGain - 1.0) * intensity
  bGain = 1.0 + (bGain - 1.0) * intensity

  for it in image:pixels() do
    local pixel = it()
    local r, g, b, a = ColorUtils.getRGBA(pixel)
    it(ColorUtils.makeRGBA(r * rGain, g * gGain, b * bGain, a))
  end
end

return ColorTemp