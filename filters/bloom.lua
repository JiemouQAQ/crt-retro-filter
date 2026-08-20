-- ============================================================
-- CRT Retro Filter - Phosphor Bloom / Glow
-- Simulates CRT phosphor glow by blurring bright pixels and
-- blending back. Uses downsampled blur for performance
-- (same technique as real-time game bloom shaders).
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Bloom = {}

-- Extract bright pixels above a threshold into a new image
local function extractBright(image, threshold)
  local w = image.width
  local h = image.height
  local bright = Image(w, h, image.colorMode)

  for it in bright:pixels() do
    local src_pixel = image:getPixel(it.x, it.y)
    local r, g, b, a = ColorUtils.getRGBA(src_pixel)

    local lum = ColorUtils.luminance(r, g, b)
    if lum > threshold then
      local factor = (lum - threshold) / (255 - threshold)
      it(ColorUtils.makeRGBA(r * factor, g * factor, b * factor, a))
    else
      it(ColorUtils.makeRGBA(0, 0, 0, 0))
    end
  end

  return bright
end

-- Downscale image by factor (nearest-neighbor)
local function downscale(image, factor)
  if factor <= 1 then return image end
  local w = image.width
  local h = image.height
  local sw = math.max(1, math.floor(w / factor))
  local sh = math.max(1, math.floor(h / factor))
  if sw == w and sh == h then return image end

  local small = Image(sw, sh, image.colorMode)
  for it in small:pixels() do
    local sx = math.floor(it.x * factor)
    local sy = math.floor(it.y * factor)
    it(image:getPixel(sx, sy))
  end
  return small
end

-- Upscale image by factor (nearest-neighbor)
local function upscale(image, targetW, targetH)
  local w = image.width
  local h = image.height
  if w == targetW and h == targetH then return image end

  local result = Image(targetW, targetH, image.colorMode)
  local scaleX = w / targetW
  local scaleY = h / targetH
  for it in result:pixels() do
    local sx = math.min(w - 1, math.floor(it.x * scaleX))
    local sy = math.min(h - 1, math.floor(it.y * scaleY))
    it(image:getPixel(sx, sy))
  end
  return result
end

-- 1D Gaussian blur pass (horizontal)
local function blurHorizontal(src, dst, kernel, radius)
  local w = src.width
  local h = src.height

  for it in dst:pixels() do
    local x = it.x
    local y = it.y

    local sum_r, sum_g, sum_b, sum_a = 0, 0, 0, 0

    for ki = 1, #kernel do
      local sx = x + (ki - 1) - radius
      if sx >= 0 and sx < w then
        local pixel = src:getPixel(sx, y)
        local r, g, b, a = ColorUtils.getRGBA(pixel)
        local weight = kernel[ki]
        sum_r = sum_r + r * weight
        sum_g = sum_g + g * weight
        sum_b = sum_b + b * weight
        sum_a = sum_a + a * weight
      end
    end

    it(ColorUtils.makeRGBA(sum_r, sum_g, sum_b, sum_a))
  end
end

-- 1D Gaussian blur pass (vertical)
local function blurVertical(src, dst, kernel, radius)
  local w = src.width
  local h = src.height

  for it in dst:pixels() do
    local x = it.x
    local y = it.y

    local sum_r, sum_g, sum_b, sum_a = 0, 0, 0, 0

    for ki = 1, #kernel do
      local sy = y + (ki - 1) - radius
      if sy >= 0 and sy < h then
        local pixel = src:getPixel(x, sy)
        local r, g, b, a = ColorUtils.getRGBA(pixel)
        local weight = kernel[ki]
        sum_r = sum_r + r * weight
        sum_g = sum_g + g * weight
        sum_b = sum_b + b * weight
        sum_a = sum_a + a * weight
      end
    end

    it(ColorUtils.makeRGBA(sum_r, sum_g, sum_b, sum_a))
  end
end

-- Apply bloom/glow effect using downsampled blur for performance
-- params:
--   threshold: 0-255, luminance threshold for brightness
--   radius: 1-10, blur radius (applied at reduced resolution)
--   intensity: 0-100, glow intensity
function Bloom.apply(image, params)
  local threshold = params.bloom_threshold or 128
  local radius = params.bloom_radius or 3
  local intensity = params.bloom_intensity or 50
  local enabled = params.bloom_enabled

  -- Parameter animation (mechanism B): the glow pulses like breathing.
  if params.anim_enabled and params._frame then
    intensity = intensity * (0.5 + 0.5 * MathUtils.animWave(params, 70, 0, 1))
  end

  if enabled == false or intensity == 0 then
    return image:clone()
  end

  local w = image.width
  local h = image.height

  -- Step 1: Extract bright pixels
  local bright = extractBright(image, threshold)

  -- Step 2: Downsample by 2x for performance (blur at half resolution)
  local downsample = 2
  local small = downscale(bright, downsample)
  local sw = small.width
  local sh = small.height

  -- Step 3: Gaussian kernel (cached)
  local kernel = MathUtils.gaussianKernel(radius)

  -- Step 4: Blur the downsampled image
  local temp = Image(sw, sh, small.colorMode)
  blurHorizontal(small, temp, kernel, radius)
  local blurredSmall = Image(sw, sh, small.colorMode)
  blurVertical(temp, blurredSmall, kernel, radius)

  -- Step 5: Upscale back to original size
  local blurred = upscale(blurredSmall, w, h)

  -- Step 6: Blend blurred bright pixels back onto the image (the input
  -- is a working copy, so it can be modified in place — saves a clone)
  local result = image
  local blend_factor = intensity / 100.0

  for it in result:pixels() do
    local orig_pixel = it()
    local orig_r, orig_g, orig_b, orig_a = ColorUtils.getRGBA(orig_pixel)

    local blur_pixel = blurred:getPixel(it.x, it.y)
    local blur_r, blur_g, blur_b = ColorUtils.getRGBA(blur_pixel)

    local r = ColorUtils.clamp(orig_r + blur_r * blend_factor, 0, 255)
    local g = ColorUtils.clamp(orig_g + blur_g * blend_factor, 0, 255)
    local b = ColorUtils.clamp(orig_b + blur_b * blend_factor, 0, 255)

    it(ColorUtils.makeRGBA(r, g, b, orig_a))
  end

  return result
end

return Bloom