-- ============================================================
-- CRT Retro Filter - Phosphor Persistence / Afterglow
-- Simulates CRT phosphor decay by applying a directional blur
-- trail to bright pixels, creating a subtle ghosting effect.
-- For static images, applies a horizontal blur streak.
-- ============================================================

local ColorUtils = require("utils.color")

local Persistence = {}

-- Apply phosphor persistence (modifies in-place)
-- params:
--   persistence_enabled: boolean
--   persistence_intensity: 0-100, blur strength
--   persistence_threshold: 0-255, brightness threshold for persistence
function Persistence.apply(image, params)
  local enabled = params.persistence_enabled
  if enabled == false then return end

  local intensity = (params.persistence_intensity or 30) / 100.0
  if intensity <= 0 then return end

  local threshold = params.persistence_threshold or 160

  local w = image.width
  local h = image.height

  -- Mechanism C: real afterglow. In per-frame evolution mode with a
  -- previous frame available (params._prev), bright pixels from the
  -- previous frame's final output linger, decaying by `retained` per
  -- frame — genuine phosphor persistence across the animation.
  if params._prev and params.anim_enabled then
    local prev = params._prev
    local retained = 0.05 + intensity * 0.9
    for it in image:pixels() do
      local old = prev:getPixel(it.x, it.y)
      local or_, og, ob = ColorUtils.getRGBA(old)
      if ColorUtils.luminance(or_, og, ob) > threshold then
        local cr, cg, cb, ca = ColorUtils.getRGBA(it())
        it(ColorUtils.makeRGBA(
          math.max(cr, or_ * retained),
          math.max(cg, og * retained),
          math.max(cb, ob * retained),
          ca))
      end
    end
    return
  end

  -- Horizontal blur kernel: exponentially decaying samples to the right
  -- Simulates the phosphor trail as the electron beam moves left-to-right
  local maxSamples = math.floor(1 + intensity * 8)
  if maxSamples < 1 then maxSamples = 1 end

  local src = image:clone()

  for it in image:pixels() do
    local x = it.x
    local y = it.y

    local pixel = src:getPixel(x, y)
    local r, g, b, a = ColorUtils.getRGBA(pixel)
    local lum = ColorUtils.luminance(r, g, b)

    if lum <= threshold then
      -- Below threshold: keep original
      it(pixel)
    else
      -- Above threshold: blend with trailing samples
      -- The trail goes to the left (previous phosphor positions)
      local sum_r = r
      local sum_g = g
      local sum_b = b
      local totalWeight = 1.0

      local decay = 0.5 * intensity
      for i = 1, maxSamples do
        local sx = x - i
        if sx < 0 then break end

        local weight = math.exp(-i * decay)
        local sp = src:getPixel(sx, y)
        local sr, sg, sb, _ = ColorUtils.getRGBA(sp)

        sum_r = sum_r + sr * weight
        sum_g = sum_g + sg * weight
        sum_b = sum_b + sb * weight
        totalWeight = totalWeight + weight
      end

      it(ColorUtils.makeRGBA(sum_r / totalWeight, sum_g / totalWeight, sum_b / totalWeight, a))
    end
  end
end

return Persistence