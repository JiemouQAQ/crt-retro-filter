-- ============================================================
-- CRT Retro Filter - Horizontal Ripple / Wave Distortion
-- Simulates CRT interference patterns by applying sinusoidal
-- horizontal displacement to each row of pixels.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Ripple = {}

-- Apply horizontal ripple distortion (modifies in-place)
-- params:
--   ripple_enabled: boolean
--   ripple_amplitude: 0-10, max horizontal pixel displacement
--   ripple_frequency: 0-100, number of wave cycles across image
--   ripple_phase: 0-360, wave phase offset in degrees
--   ripple_falloff: 0-100, edge attenuation (0=full wave, 100=flat)
function Ripple.apply(image, params)
  local enabled = params.ripple_enabled
  if enabled == false then return end

  local amplitude = params.ripple_amplitude or 2
  if amplitude <= 0 then return end

  local frequency = (params.ripple_frequency or 30) / 100.0
  local phase = (params.ripple_phase or 0) * math.pi / 180.0
  local falloff = (params.ripple_falloff or 0) / 100.0

  -- Parameter animation (mechanism B): phase sweeps through 360 degrees
  -- over 60 frames, making the ripple wobble like disturbed water.
  if params.anim_enabled and params._frame then
    phase = phase + MathUtils.animWave(params, 60, 0, 2 * math.pi)
  end

  local w = image.width
  local h = image.height
  local cy = (h - 1) / 2.0

  -- Clone source to read from undisturbed pixels
  local src = image:clone()

  for it in image:pixels() do
    local x = it.x
    local y = it.y

    -- Sine wave displacement based on y position
    local wave = math.sin(y / h * frequency * 2.0 * math.pi + phase)

    -- Falloff: attenuate wave near edges (top/bottom)
    local edgeFactor = 1.0
    if falloff > 0 then
      local distFromCenter = math.abs(y - cy) / (cy + 1)
      edgeFactor = 1.0 - falloff * distFromCenter
      if edgeFactor < 0 then edgeFactor = 0 end
    end

    local displacement = wave * amplitude * edgeFactor

    -- Sample from source at displaced x position
    local sx = x + displacement
    sx = math.max(0, math.min(w - 1, sx))

    -- Nearest-neighbor sampling (sharp CRT look)
    local sxInt = math.floor(sx + 0.5)
    if sxInt < 0 then sxInt = 0 elseif sxInt >= w then sxInt = w - 1 end

    it(src:getPixel(sxInt, y))
  end
end

return Ripple