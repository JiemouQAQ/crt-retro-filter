-- ============================================================
-- CRT Retro Filter - VHS Tracking Band (VHS 跟踪条)
-- The classic "tape tracking error": a horizontal band where rows
-- are displaced by noisy amounts and static is added, mimicking a
-- damaged VHS head. Deterministic via row/position hashing.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local TrackingBand = {}

-- Apply tracking band (modifies in-place)
-- params:
--   tracking_band_enabled: boolean
--   tracking_band_intensity: 0-100, displacement + static strength
--   tracking_band_width: 1-16, band half-height in pixel rows
--   tracking_band_position: 0-100, band center position from top
function TrackingBand.apply(image, params)
  if params.tracking_band_enabled == false then return end
  local intensity = params.tracking_band_intensity or 50
  local width = math.max(1, params.tracking_band_width or 4)
  local position = params.tracking_band_position or 50
  if intensity <= 0 then return end

  local w = image.width
  local h = image.height
  if w <= 1 or h <= 0 then return end

  local src = image:clone()
  local animOffset = MathUtils.animSeed(params, 257)
  local seed1, seed2 = 555 + animOffset, 666 + animOffset
  local center = math.floor(position / 100.0 * (h - 1))
  -- In per-frame evolution mode the band scrolls down ~3 rows per frame,
  -- mimicking the tape transport drift of a damaged VHS head.
  if params.anim_enabled and params._frame then
    center = (center + params._frame * 3) % h
  end
  local half = width
  local maxDx = math.max(1, math.floor(intensity / 100.0 * w * 0.15))
  local noiseLevel = intensity / 100.0 * 40.0

  for y = 0, h - 1 do
    if math.abs(y - center) <= half then
      local dx = math.floor((MathUtils.fastHash(y, 0, seed1) - 0.5) * 2 * maxDx)
      for x = 0, w - 1 do
        local sx = x + dx
        local px
        if sx >= 0 and sx < w then
          px = src:getPixel(sx, y)
        else
          px = src:getPixel(x, y)
        end

        local nv = (MathUtils.fastHash(x, y, seed2) - 0.5) * 2 * noiseLevel
        local r, g, b, a = ColorUtils.getRGBA(px)
        image:putPixel(x, y, ColorUtils.makeRGBA(
          ColorUtils.clamp(r + nv, 0, 255),
          ColorUtils.clamp(g + nv, 0, 255),
          ColorUtils.clamp(b + nv, 0, 255),
          a))
      end
    end
  end
end

return TrackingBand
