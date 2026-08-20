-- ============================================================
-- CRT Retro Filter - Screen Curvature
-- Simulates the concave screen surface of a CRT tube: the picture
-- is gently pinched inward (pincushion) — concave only, no convex.
-- The canvas size, aspect ratio and the full picture are preserved:
-- every output pixel is nearest-sampled with edge clamping, so the
-- image is never cropped and never shows transparent holes.
-- Creates a new image (does not modify in-place).
-- Caches coordinate remap for repeated use at same dimensions.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Curvature = {}

-- Coordinate remap cache: key = "w_h_curvature" -> {{sx, sy}, ...}
local remapCache = {}

-- Nearest-neighbor sampling with edge clamping: never samples outside
-- the image and never produces transparent holes.
local function sampleNearest(src_img, x, y, w, h)
  local ix = math.max(0, math.min(w - 1, math.floor(x + 0.5)))
  local iy = math.max(0, math.min(h - 1, math.floor(y + 0.5)))
  return src_img:getPixel(ix, iy)
end

-- Apply concave screen curvature to an image
-- Returns a new image (does NOT modify the original; same size)
-- params:
--   curvature_amount: 0-100, inward depth (0 = flat, 100 = deepest)
--   curvature_corner_radius: 0-100, rounded corner radius in pixels
function Curvature.apply(image, params)
  -- Concave-only: the magnitude drives the inward depth (any sign works,
  -- so old presets with negative values still behave sensibly).
  local curvature = math.abs(params.curvature_amount or 30)
  local corner_radius = params.curvature_corner_radius or 0
  local enabled = params.curvature_enabled

  -- Parameter animation (mechanism B): slow "breathing" of the depth.
  if params.anim_enabled and params._frame then
    curvature = curvature * (0.7 + 0.3 * MathUtils.animWave(params, 120, 0, 1))
  end

  if enabled == false or curvature == 0 then
    return image:clone()
  end

  local w = image.width
  local h = image.height
  local cx = (w - 1) / 2.0
  local cy = (h - 1) / 2.0

  local max_dist = math.sqrt(cx * cx + cy * cy)
  if max_dist < 1 then max_dist = 1 end
  -- Normalized radial coefficient, concave only (k <= 0), capped so the
  -- pinch stays gentle and the picture never loses its shape.
  -- k in [-0.4, 0] -> max inward pull ~9% at the corners.
  local k = -(curvature / 100.0) * 0.4

  -- Try to get cached remap table
  local cacheKey = w .. "_" .. h .. "_" .. curvature
  local remap = remapCache[cacheKey]

  if not remap then
    -- Precompute all source coordinates
    remap = {}
    local idx = 0
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local sx, sy = MathUtils.inverseBarrelDistortion(x, y, cx, cy, k, max_dist)
        idx = idx + 1
        remap[idx] = { sx = sx, sy = sy }
      end
    end
    remapCache[cacheKey] = remap
    -- Limit cache size to avoid memory bloat
    if #remapCache > 8 then
      local firstKey = next(remapCache)
      if firstKey then remapCache[firstKey] = nil end
    end
  end

  -- Create output image using cached remap (nearest + edge-clamped, so
  -- every pixel gets a valid color — no transparent holes)
  local result = Image(w, h, image.colorMode)

  for it in result:pixels() do
    local idx = it.y * w + it.x + 1
    local coord = remap[idx]
    it(sampleNearest(image, coord.sx, coord.sy, w, h))
  end

  -- Apply corner radius by clearing corners
  if corner_radius > 0 then
    local cr2 = corner_radius * corner_radius
    for it in result:pixels() do
      local x = it.x
      local y = it.y

      local in_corner = false
      if x < corner_radius and y < corner_radius then
        local dx = corner_radius - x
        local dy = corner_radius - y
        in_corner = (dx * dx + dy * dy) > cr2
      elseif x >= w - corner_radius and y < corner_radius then
        local dx = x - (w - corner_radius)
        local dy = corner_radius - y
        in_corner = (dx * dx + dy * dy) > cr2
      elseif x < corner_radius and y >= h - corner_radius then
        local dx = corner_radius - x
        local dy = y - (h - corner_radius)
        in_corner = (dx * dx + dy * dy) > cr2
      elseif x >= w - corner_radius and y >= h - corner_radius then
        local dx = x - (w - corner_radius)
        local dy = y - (h - corner_radius)
        in_corner = (dx * dx + dy * dy) > cr2
      end

      if in_corner then
        it(ColorUtils.makeRGBA(0, 0, 0, 0))
      end
    end
  end

  return result
end

return Curvature