-- ============================================================
-- CRT Retro Filter - Slice Shift (行撕裂)
-- Classic glitch tear: random horizontal bands of rows are shifted
-- left/right by a pseudo-random amount. Deterministic: identical
-- params always produce the same tear pattern.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local SliceShift = {}

-- Apply slice tearing (modifies in-place)
-- params:
--   slice_shift_enabled: boolean
--   slice_shift_intensity: 0-100, max horizontal displacement
--   slice_shift_density: 0-100, fraction of bands affected
--   slice_shift_thickness: 1-8, band height in pixel rows
function SliceShift.apply(image, params)
  if params.slice_shift_enabled == false then return end
  local intensity = params.slice_shift_intensity or 50
  local density = params.slice_shift_density or 40
  local thickness = math.max(1, MathUtils.previewParam(params, params.slice_shift_thickness or 2))
  if intensity <= 0 then return end

  local w = image.width
  local h = image.height
  if w <= 1 or h <= 0 then return end

  local src = image:clone()
  local animOffset = MathUtils.animSeed(params, 97)
  local seed1, seed2 = 1337 + animOffset, 7331 + animOffset
  local maxShift = math.max(1, math.floor(intensity / 100.0 * w * 0.35))

  local bandCount = math.ceil(h / thickness)
  for b = 0, bandCount - 1 do
    local y0 = b * thickness
    local y1 = math.min(h, y0 + thickness)

    if MathUtils.fastHash(b, 0, seed1) < density / 100.0 then
      local dx = math.floor((MathUtils.fastHash(b, 1, seed2) - 0.5) * 2 * maxShift)
      if dx ~= 0 then
        for y = y0, y1 - 1 do
          for x = 0, w - 1 do
            local sx = x + dx
            if sx >= 0 and sx < w then
              image:putPixel(x, y, src:getPixel(sx, y))
            end
          end
        end
      end
    end
  end
end

return SliceShift
