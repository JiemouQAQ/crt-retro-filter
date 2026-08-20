-- ============================================================
-- CRT Retro Filter - Interlacing Jitter
-- Simulates CRT interlaced scan artifacts by offsetting
-- alternating rows of pixels, creating a "comb" effect on
-- horizontal edges typical of interlaced displays.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Jitter = {}

-- Apply interlacing jitter (modifies in-place)
-- params:
--   jitter_enabled: boolean
--   jitter_intensity: 0-100, max pixel displacement
--   jitter_direction: "horizontal" or "vertical"
function Jitter.apply(image, params)
  local enabled = params.jitter_enabled
  if enabled == false then return end

  local intensity = params.jitter_intensity or 20
  if intensity <= 0 then return end

  -- Parameter animation (mechanism B): the comb shimmer pulses.
  if params.anim_enabled and params._frame then
    intensity = intensity * (0.5 + 0.5 * MathUtils.animWave(params, 30, 0, 1))
  end

  local direction = params.jitter_direction or "horizontal"
  local displacement = intensity / 25.0  -- scale to 0-4px range

  local w = image.width
  local h = image.height

  local src = image:clone()

  for it in image:pixels() do
    local x = it.x
    local y = it.y

    -- Offset every other row (odd rows)
    local offset = 0
    if y % 2 == 1 then
      offset = displacement
    end

    if offset == 0 then
      -- Even rows: no change
      it(src:getPixel(x, y))
    else
      local sx, sy = x, y
      if direction == "horizontal" then
        sx = x + offset
        if sx >= w then sx = w - 1 end
      else
        sy = y + offset
        if sy >= h then sy = h - 1 end
      end
      it(src:getPixel(math.floor(sx + 0.5), math.floor(sy + 0.5)))
    end
  end
end

return Jitter