-- ============================================================
-- CRT Retro Filter - Color Utilities
-- Color mode detection, RGBA decomposition, and color helpers
-- ============================================================

local ColorUtils = {}

-- Clamp value between min and max
function ColorUtils.clamp(value, min_val, max_val)
  return math.max(min_val, math.min(max_val, value))
end

-- Linear interpolation
function ColorUtils.lerp(a, b, t)
  return a + (b - a) * t
end

-- Get RGBA components from a pixel value (RGB mode)
function ColorUtils.getRGBA(pixel)
  local r = app.pixelColor.rgbaR(pixel)
  local g = app.pixelColor.rgbaG(pixel)
  local b = app.pixelColor.rgbaB(pixel)
  local a = app.pixelColor.rgbaA(pixel)
  return r, g, b, a
end

-- Create an RGBA pixel value from components
function ColorUtils.makeRGBA(r, g, b, a)
  return app.pixelColor.rgba(
    ColorUtils.clamp(math.floor(r + 0.5), 0, 255),
    ColorUtils.clamp(math.floor(g + 0.5), 0, 255),
    ColorUtils.clamp(math.floor(b + 0.5), 0, 255),
    ColorUtils.clamp(math.floor(a + 0.5), 0, 255)
  )
end

-- Blend two RGBA pixel values
function ColorUtils.blendRGBA(r1, g1, b1, a1, r2, g2, b2, a2, opacity)
  local inv_opacity = 1.0 - opacity
  local r = r1 * inv_opacity + r2 * opacity
  local g = g1 * inv_opacity + g2 * opacity
  local b = b1 * inv_opacity + b2 * opacity
  local a = a1 * inv_opacity + a2 * opacity
  return ColorUtils.makeRGBA(r, g, b, a)
end

-- Calculate luminance from RGB (ITU-R BT.709)
function ColorUtils.luminance(r, g, b)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Check if the active image is in RGB mode
function ColorUtils.isRGB(image)
  return image.colorMode == ColorMode.RGB
end

-- Check if the active image is in INDEXED mode
function ColorUtils.isIndexed(image)
  return image.colorMode == ColorMode.INDEXED
end

-- Check if the active image is in GRAY mode
function ColorUtils.isGray(image)
  return image.colorMode == ColorMode.GRAY
end

return ColorUtils