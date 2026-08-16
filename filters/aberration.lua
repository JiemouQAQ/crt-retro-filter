-- ============================================================
-- CRT Retro Filter - Chromatic Aberration
-- Simulates the color fringing caused by imperfect convergence
-- of the three electron beams in a CRT. Shifts the R and B
-- channels radially outward from the center.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Aberration = {}

-- Apply chromatic aberration to an image (modifies in-place)
-- Requires the image to already have curvature applied (or not).
-- params:
--   shift_r: -5 to 5, red channel radial shift in pixels
--   shift_b: -5 to 5, blue channel radial shift in pixels
--   falloff: 0-100, how the shift increases from center to edge
function Aberration.apply(image, params)
  local shift_r = params.shift_r or 2
  local shift_b = params.shift_b or -2
  local falloff = params.falloff or 50
  local enabled = params.aberration_enabled

  if enabled == false or (shift_r == 0 and shift_b == 0) then return end

  local w = image.width
  local h = image.height
  local cx = (w - 1) / 2.0
  local cy = (h - 1) / 2.0
  local max_dist = math.sqrt(cx * cx + cy * cy)

  if max_dist == 0 then return end

  -- Create a copy to read from
  local src = image:clone()

  for it in image:pixels() do
    local x = it.x
    local y = it.y

    local dx = x - cx
    local dy = y - cy
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist > 0.001 then
      -- Normalize direction
      local nx = dx / dist
      local ny = dy / dist

      -- Calculate falloff factor (0 at center, 1 at edges)
      local factor = (dist / max_dist) ^ (falloff / 100.0 * 2.0 + 0.5)

      -- Get original pixel
      local orig_pixel = src:getPixel(x, y)
      local _, g, _, a = ColorUtils.getRGBA(orig_pixel)

      -- Sample red channel from shifted position
      local rx = x + nx * shift_r * factor
      local ry = y + ny * shift_r * factor
      rx = math.max(0, math.min(w - 1, math.floor(rx + 0.5)))
      ry = math.max(0, math.min(h - 1, math.floor(ry + 0.5)))
      local r = ColorUtils.getRGBA(src:getPixel(rx, ry))

      -- Sample blue channel from shifted position
      local bx = x + nx * shift_b * factor
      local by = y + ny * shift_b * factor
      bx = math.max(0, math.min(w - 1, math.floor(bx + 0.5)))
      by = math.max(0, math.min(h - 1, math.floor(by + 0.5)))
      local _, _, b = ColorUtils.getRGBA(src:getPixel(bx, by))

      it(ColorUtils.makeRGBA(r, g, b, a))
    end
  end
end

return Aberration