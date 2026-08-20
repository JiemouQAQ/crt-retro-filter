-- ============================================================
-- CRT Retro Filter - Scanlines
-- Simulates CRT interlaced scanline effect by darkening
-- alternating rows of pixels.
-- ============================================================

local ColorUtils = require("utils.color")

local Scanlines = {}

-- Apply scanlines to an image (modifies in-place)
-- params:
--   intensity: 0-100, scanline strength (higher = darker rows)
--   thickness: 1-4, scanline thickness in pixel rows
--   offset: 0 or 1, which row set gets darkened
function Scanlines.apply(image, params)
  local intensity = params.scanlines_intensity or 70
  local thickness = params.scanlines_thickness or 1
  local offset = params.scanlines_offset or 0
  local enabled = params.scanlines_enabled

  if enabled == false then return end

  -- Interlace flicker: when enabled, the darkened row set alternates
  -- every frame (the classic CRT interlacing shimmer).
  if params.scanlines_flicker and params._frame then
    offset = (offset + params._frame) % 2
  end

  -- Convert intensity 0-100 to a darkening factor 1.0..0.15:
  -- higher intensity = darker scanline rows (never fully black).
  local darken = 1.0 - (intensity / 100.0) * 0.85

  for it in image:pixels() do
    local row = it.y
    local band = math.floor((row - offset) / thickness)
    if band % 2 == 0 then
      local pixel = it()
      local r, g, b, a = ColorUtils.getRGBA(pixel)
      it(ColorUtils.makeRGBA(r * darken, g * darken, b * darken, a))
    end
  end
end

return Scanlines