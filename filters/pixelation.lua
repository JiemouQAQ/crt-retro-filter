-- ============================================================
-- CRT Retro Filter - Pixelation
-- Simulates low-resolution CRT by grouping pixels into blocks.
-- Returns a new image (resolution reduction changes size).
-- ============================================================

local ColorUtils = require("utils.color")

local Pixelation = {}

-- Apply pixelation effect
-- Returns a new image with blocky pixelation applied
-- params:
--   pixelation_enabled: boolean
--   pixelation_block_size: 1-8 (pixel block dimension)
function Pixelation.apply(image, params)
  local enabled = params.pixelation_enabled
  local blockSize = params.pixelation_block_size or 2

  if enabled == false or blockSize <= 1 then
    return image:clone()
  end

  local w = image.width
  local h = image.height

  -- Downscale: each block becomes 1 pixel
  local sw = math.max(1, math.floor(w / blockSize))
  local sh = math.max(1, math.floor(h / blockSize))

  local small = Image(sw, sh, image.colorMode)
  for it in small:pixels() do
    local sx = it.x * blockSize
    local sy = it.y * blockSize
    it(image:getPixel(sx, sy))
  end

  -- Upscale back to original size
  local result = Image(w, h, image.colorMode)
  local scale = blockSize
  for it in result:pixels() do
    local sx = math.floor(it.x / scale)
    local sy = math.floor(it.y / scale)
    sx = math.min(sx, sw - 1)
    sy = math.min(sy, sh - 1)
    it(small:getPixel(sx, sy))
  end

  return result
end

return Pixelation