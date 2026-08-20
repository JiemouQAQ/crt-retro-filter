-- ============================================================
-- CRT Retro Filter - Mirror Tear (镜像撕裂)
-- Classic mirror glitch: selected strips of the image are
-- reflected (left-right or top-bottom), like a broken video
-- buffer. Deterministic via band hashing.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local MirrorTear = {}

-- Apply mirror tearing (modifies in-place)
-- params:
--   mirror_tear_enabled: boolean
--   mirror_tear_intensity: 0-100, strip height/width in pixels
--   mirror_tear_density: 0-100, fraction of strips affected
--   mirror_tear_direction: "horizontal" | "vertical"
function MirrorTear.apply(image, params)
  if params.mirror_tear_enabled == false then return end
  local intensity = params.mirror_tear_intensity or 50
  local density = params.mirror_tear_density or 40
  local direction = params.mirror_tear_direction or "horizontal"
  if intensity <= 0 then return end

  local w = image.width
  local h = image.height
  if w <= 1 or h <= 1 then return end

  local src = image:clone()
  local animOffset = MathUtils.animSeed(params, 421)
  local strip = math.max(1, math.floor(1 + intensity / 100.0 * 15))
  local seed = 271828 + animOffset

  if direction == "vertical" then
    -- vertical strips, mirrored top-bottom
    local cols = math.ceil(w / strip)
    for c = 0, cols - 1 do
      if MathUtils.fastHash(0, c, seed) < density / 100.0 then
        local x0 = c * strip
        local x1 = math.min(w, x0 + strip)
        for y = 0, h - 1 do
          local sy = h - 1 - y
          for x = x0, x1 - 1 do
            image:putPixel(x, y, src:getPixel(x, sy))
          end
        end
      end
    end
  else
    -- horizontal strips, mirrored left-right
    local rows = math.ceil(h / strip)
    for r = 0, rows - 1 do
      if MathUtils.fastHash(r, 0, seed) < density / 100.0 then
        local y0 = r * strip
        local y1 = math.min(h, y0 + strip)
        for y = y0, y1 - 1 do
          for x = 0, w - 1 do
            local sx = w - 1 - x
            image:putPixel(x, y, src:getPixel(sx, y))
          end
        end
      end
    end
  end
end

return MirrorTear
