-- ============================================================
-- CRT Retro Filter - Vignette
-- Simulates CRT screen edge darkening via normalized elliptical
-- gradient. Supports custom aspect ratios: auto, 1:1, 4:3, 16:9.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Vignette = {}

-- Apply vignette to an image (modifies in-place)
-- params:
--   intensity: 0-100, how dark the edges get
--   radius: 0-100, inner radius as percentage of normalized distance
--   softness: 0-100, how gradually the darkening fades in
--   ratio: "auto" | "1:1" | "4:3" | "16:9"
function Vignette.apply(image, params)
  local intensity = params.vignette_intensity or 40
  local radius = params.vignette_radius or 50
  local softness = params.vignette_softness or 50
  local enabled = params.vignette_enabled
  local ratio = params.vignette_ratio or "auto"

  -- Parameter animation (mechanism B): gentle edge-darkening pulse.
  if params.anim_enabled and params._frame then
    intensity = intensity * (0.6 + 0.4 * MathUtils.animWave(params, 80, 0, 1))
  end

  if enabled == false or intensity == 0 then return end

  local w = image.width
  local h = image.height
  local cx = (w - 1) / 2.0
  local cy = (h - 1) / 2.0
  local hw = w / 2.0
  local hh = h / 2.0

  if hw == 0 or hh == 0 then return end

  -- Aspect ratio correction: scale x/y so the vignette shape
  -- matches the selected ratio, centered on the image.
  local rx, ry = 1.0, 1.0
  local imgRatio = w / h

  if ratio == "1:1" then
    if imgRatio > 1.0 then rx = imgRatio else ry = 1.0 / imgRatio end
  elseif ratio == "4:3" then
    local t = 4.0 / 3.0
    if imgRatio > t then rx = imgRatio / t else ry = t / imgRatio end
  elseif ratio == "16:9" then
    local t = 16.0 / 9.0
    if imgRatio > t then rx = imgRatio / t else ry = t / imgRatio end
  end
  -- "auto": rx=ry=1.0 — vignette follows the image's own aspect ratio

  local inner_r = radius / 100.0
  local soft = softness / 100.0
  local darken = intensity / 100.0

  for it in image:pixels() do
    local nx = (it.x - cx) / hw * rx
    local ny = (it.y - cy) / hh * ry
    local dist = math.sqrt(nx * nx + ny * ny)

    if dist > inner_r then
      local t
      if soft > 0 then
        local endDist = inner_r + soft
        if endDist > 1.4 then endDist = 1.4 end
        if dist < endDist then
          t = (dist - inner_r) / (endDist - inner_r)
          t = t * t * (3.0 - 2.0 * t)  -- smoothstep inline
        else
          t = 1.0
        end
      else
        t = (dist - inner_r) / (1.4 - inner_r)
      end
      t = math.min(1.0, t)

      local factor = 1.0 - t * darken
      local p = it()
      local r, g, b, a = ColorUtils.getRGBA(p)
      it(ColorUtils.makeRGBA(r * factor, g * factor, b * factor, a))
    end
  end
end

return Vignette