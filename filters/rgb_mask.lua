-- ============================================================
-- CRT Retro Filter - RGB Phosphor Mask
-- Supports 3 classic CRT mask types:
--   1. Aperture Grille (Trinitron) - vertical RGB stripes
--   2. Shadow Mask - triangular dot pattern
--   3. Slot Mask - vertical slot groups (NEC/Mitsubishi)
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local RGBMask = {}

-- Determine which phosphor channel a pixel belongs to
-- Returns 0=red, 1=green, 2=blue
local function getMaskBand(maskType, x, y, width)
  if maskType == "grille" then
    -- Aperture Grille: vertical RGB stripes
    return math.floor(x / width) % 3

  elseif maskType == "shadow" then
    -- Shadow Mask: triangular dot pattern
    -- Uses a 2-row offset pattern: even rows R-G-B, odd rows offset by 1
    local row = math.floor(y / width)
    local col = math.floor(x / width)
    -- Offset every other row to create triangular interpolation
    local offset = row % 2
    return (col + offset) % 3

  elseif maskType == "slot" then
    -- Slot Mask: groups of 3 vertical slots, offset every other group row
    local col = math.floor(x / width)
    local row = math.floor(y / (width * 2))
    local offset = row % 2
    return (col + offset) % 3

  else
    -- Default: grille
    return math.floor(x / width) % 3
  end
end

-- Apply RGB phosphor mask to image (modifies in-place)
-- params:
--   rgb_mask_enabled: boolean
--   rgb_mask_intensity: 0-100
--   rgb_mask_type: "grille", "shadow", or "slot"
--   rgb_mask_width: 1-4 (phosphor element width in pixels)
function RGBMask.apply(image, params)
  local enabled = params.rgb_mask_enabled
  if enabled == false then return end

  local intensity = (params.rgb_mask_intensity or 30) / 100.0
  if intensity <= 0 then return end

  local maskType = params.rgb_mask_type or "grille"
  local width = params.rgb_mask_width or 1

  -- Parameter animation (mechanism B): the phosphor pattern rolls to the
  -- right one band every 6 frames.
  local roll = 0
  if params.anim_enabled and params._frame then
    roll = math.floor(params._frame / 6) % 3
  end

  local atten = 1.0 - intensity * 0.5

  for it in image:pixels() do
    local pixel = it()
    local r, g, b, a = ColorUtils.getRGBA(pixel)

    local band = getMaskBand(maskType, it.x + roll * width, it.y, width)

    if band == 0 then
      g = g * atten
      b = b * atten
    elseif band == 1 then
      r = r * atten
      b = b * atten
    else
      r = r * atten
      g = g * atten
    end

    it(ColorUtils.makeRGBA(r, g, b, a))
  end
end

return RGBMask