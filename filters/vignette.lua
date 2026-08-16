-- ============================================================
-- CRT Retro Filter - Vignette
-- Simulates CRT screen edge darkening by applying a radial
-- gradient dark mask over the image.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Vignette = {}

-- Apply vignette to an image (modifies in-place)
-- params:
--   intensity: 0-100, how dark the edges get
--   radius: 0-100, inner radius as percentage of max distance
--   softness: 0-100, how gradually the darkening fades in
function Vignette.apply(image, params)
  local intensity = params.intensity or 40
  local radius = params.radius or 50
  local softness = params.softness or 50
  local enabled = params.vignette_enabled

  if enabled == false or intensity == 0 then return end

  local w = image.width
  local h = image.height
  local cx = (w - 1) / 2.0
  local cy = (h - 1) / 2.0
  local max_dist = math.sqrt(cx * cx + cy * cy)

  -- Convert params to usable ranges
  local inner_radius = (radius / 100.0) * max_dist  -- where vignette starts
  local outer_radius = max_dist                      -- where vignette is full
  local soft_edge = (softness / 100.0) * (outer_radius - inner_radius)
  local darken = intensity / 100.0

  for it in image:pixels() do
    local dist = math.sqrt((it.x - cx)^2 + (it.y - cy)^2)

    if dist > inner_radius then
      -- Calculate vignette factor
      local t
      if soft_edge > 0 then
        t = MathUtils.smoothstep(inner_radius, inner_radius + soft_edge, dist)
      else
        t = (dist - inner_radius) / (outer_radius - inner_radius)
      end
      t = math.min(1.0, t)

      local factor = 1.0 - t * darken
      local pixel = it()
      local r, g, b, a = ColorUtils.getRGBA(pixel)
      it(ColorUtils.makeRGBA(r * factor, g * factor, b * factor, a))
    end
  end
end

return Vignette