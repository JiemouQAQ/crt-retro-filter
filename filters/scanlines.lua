-- ============================================================
-- CRT Retro Filter - Scanlines
-- Simulates CRT interlaced scanline effect by darkening
-- alternating rows of pixels.
-- ============================================================

local ColorUtils = require("utils.color")

local Scanlines = {}

-- Apply scanlines to an image (modifies in-place)
-- params:
--   intensity: 0-100, how dark the scanlines are (lower = darker)
--   thickness: 1-4, scanline thickness in pixel rows
--   offset: 0 or 1, which row set gets darkened
function Scanlines.apply(image, params)
  local intensity = params.scanlines_intensity or 70
  local thickness = params.scanlines_thickness or 1
  local offset = params.scanlines_offset or 0
  local enabled = params.scanlines_enabled

  if enabled == false then return end

  -- Convert intensity 0-100 to opacity 0.0-1.0 for the darkening
  local darken = intensity / 100.0

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