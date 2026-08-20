-- ============================================================
-- CRT Retro Filter - Displacement (置换扭曲)
-- Random vector-field displacement: the image is warped by a
-- blocky noise field (like an After Effects displacement map with
-- a noise source). Horizontal, vertical, or both axes. Deterministic.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Displacement = {}

-- Apply displacement warp (modifies in-place)
-- params:
--   displacement_enabled: boolean
--   displacement_intensity: 0-100, max offset in pixels
--   displacement_scale: 0-100, noise cell size (low = fine, high = coarse)
--   displacement_direction: "horizontal" | "vertical" | "both"
function Displacement.apply(image, params)
  if params.displacement_enabled == false then return end
  local intensity = params.displacement_intensity or 30
  local scale = params.displacement_scale or 60
  local direction = params.displacement_direction or "both"
  if intensity <= 0 then return end

  local w = image.width
  local h = image.height
  if w <= 1 or h <= 1 then return end

  local src = image:clone()
  local animOffset = MathUtils.animSeed(params, 331)
  local cell = math.max(1, math.floor(1 + scale / 100.0 * 31))
  local maxOff = math.max(1, math.floor(intensity / 100.0 * w * 0.15))
  local seed = 31337 + animOffset

  -- Precompute one offset per noise cell (offsets depend only on cell
  -- coordinates, not on the pixel) — this turns ~2 hash calls per pixel
  -- into ~2 per cell, a large win on big images. Results are identical.
  local cols = math.ceil(w / cell)
  local rows = math.ceil(h / cell)
  local offX = {}
  local offY = {}
  local idx = 0
  for cy = 0, rows - 1 do
    for cx = 0, cols - 1 do
      idx = idx + 1
      offX[idx] = (MathUtils.fastHash(cx, cy, seed) - 0.5) * 2 * maxOff
      offY[idx] = (MathUtils.fastHash(cx, cy, seed + 1) - 0.5) * 2 * maxOff
    end
  end

  for y = 0, h - 1 do
    local cy = math.floor(y / cell)
    for x = 0, w - 1 do
      local cx = math.floor(x / cell)
      local ci = cy * cols + cx + 1
      local offXv = offX[ci]
      local offYv = offY[ci]

      local sx = x
      local sy = y
      if direction == "horizontal" then
        sx = x + offXv
      elseif direction == "vertical" then
        sy = y + offYv
      else
        sx = x + offXv
        sy = y + offYv
      end

      sx = math.max(0, math.min(w - 1, math.floor(sx + 0.5)))
      sy = math.max(0, math.min(h - 1, math.floor(sy + 0.5)))
      image:putPixel(x, y, src:getPixel(sx, sy))
    end
  end
end

return Displacement
