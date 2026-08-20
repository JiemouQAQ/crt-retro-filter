-- ============================================================
-- CRT Retro Filter - Block Corruption (数据损坏)
-- Data-moshing look: rectangular blocks are shifted horizontally,
-- leaving corrupted edges where the original pixels show through.
-- Deterministic via grid hashing.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local BlockCorruption = {}

-- Apply block corruption (modifies in-place)
-- params:
--   block_corruption_enabled: boolean
--   block_corruption_density: 0-100, fraction of blocks affected
--   block_corruption_size: 1-8, block size multiplier
--   block_corruption_shift: 0-100, max horizontal block displacement
function BlockCorruption.apply(image, params)
  if params.block_corruption_enabled == false then return end
  local density = params.block_corruption_density or 30
  local size = math.max(1, MathUtils.previewParam(params, params.block_corruption_size or 2))
  local shift = params.block_corruption_shift or 50
  if shift <= 0 then return end

  local w = image.width
  local h = image.height
  if w <= 1 or h <= 0 then return end

  local src = image:clone()
  local animOffset = MathUtils.animSeed(params, 131)
  local block = size * 4 -- visible block size in pixels
  local maxShift = math.max(1, math.floor(shift / 100.0 * w * 0.25))
  local seed1, seed2 = 4242 + animOffset, 2424 + animOffset

  local cols = math.ceil(w / block)
  local rows = math.ceil(h / block)
  for by = 0, rows - 1 do
    for bx = 0, cols - 1 do
      if MathUtils.fastHash(bx, by, seed1) < density / 100.0 then
        local dx = math.floor((MathUtils.fastHash(bx, by, seed2) - 0.5) * 2 * maxShift)
        if dx ~= 0 then
          local x0 = bx * block
          local x1 = math.min(w, x0 + block)
          local y0 = by * block
          local y1 = math.min(h, y0 + block)
          for y = y0, y1 - 1 do
            for x = x0, x1 - 1 do
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
end

return BlockCorruption
