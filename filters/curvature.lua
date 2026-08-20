-- ============================================================
-- CRT Retro Filter - Screen Curvature
-- Simulates the curved surface of a CRT display.
-- Uses barrel/pincushion distortion with bilinear interpolation
-- (restored to the v3.4.1 behavior).
-- Creates a new image (does not modify in-place).
-- Caches coordinate remap for repeated use at same dimensions.
--
-- v3.11.1 adjustments over the original:
--   * Out-of-bounds sampling is edge-clamped instead of writing
--     transparent pixels, so the warped image fully covers the
--     original (no see-through / semi-transparent ghosting).
--   * Corner radius is capped at 50% of the image's short side.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Curvature = {}

-- Coordinate remap cache: key = "w_h_curvature" -> {{sx, sy}, ...}
local remapCache = {}

-- Sample a pixel using bilinear interpolation.
-- Coordinates are clamped to the image bounds, so out-of-bounds
-- sampling never produces transparent pixels.
local function sampleBilinear(src_img, x, y, w, h)
  local x0 = math.max(0, math.min(w - 1, math.floor(x)))
  local y0 = math.max(0, math.min(h - 1, math.floor(y)))
  local x1 = math.max(0, math.min(w - 1, x0 + 1))
  local y1 = math.max(0, math.min(h - 1, y0 + 1))

  local tx = x - x0
  local ty = y - y0
  if tx < 0 then tx = 0 elseif tx > 1 then tx = 1 end
  if ty < 0 then ty = 0 elseif ty > 1 then ty = 1 end

  local p00 = src_img:getPixel(x0, y0)
  local p10 = src_img:getPixel(x1, y0)
  local p01 = src_img:getPixel(x0, y1)
  local p11 = src_img:getPixel(x1, y1)

  local r00, g00, b00, a00 = ColorUtils.getRGBA(p00)
  local r10, g10, b10, a10 = ColorUtils.getRGBA(p10)
  local r01, g01, b01, a01 = ColorUtils.getRGBA(p01)
  local r11, g11, b11, a11 = ColorUtils.getRGBA(p11)

  return ColorUtils.makeRGBA(
    MathUtils.bilerp(r00, r10, r01, r11, tx, ty),
    MathUtils.bilerp(g00, g10, g01, g11, tx, ty),
    MathUtils.bilerp(b00, b10, b01, b11, tx, ty),
    MathUtils.bilerp(a00, a10, a01, a11, tx, ty)
  )
end

-- Apply screen curvature to an image
-- Returns a new image (does NOT modify the original)
-- params:
--   curvature_amount: -100 (concave/pincushion) to 100 (convex/barrel)
--   curvature_corner_radius: 0-100, rounded corner radius in pixels
--     (capped at 50% of the image's short side)
function Curvature.apply(image, params)
  local curvature = params.curvature_amount or 30
  local corner_radius = params.curvature_corner_radius or 0
  local enabled = params.curvature_enabled

  -- Parameter animation (mechanism B): slow "breathing" of the bend.
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
  local max_dist_sq = max_dist * max_dist
  if max_dist_sq < 1 then max_dist_sq = 1 end
  -- positive curvature = convex (barrel), negative = concave (pincushion)
  local k = (curvature / 100.0) * 0.3 / max_dist_sq

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

  -- Create output image using cached remap. Every pixel is filled with a
  -- clamped bilinear sample, so the warped image completely covers the
  -- canvas (no transparent holes, no original showing through).
  local result = Image(w, h, image.colorMode)

  for it in result:pixels() do
    local idx = it.y * w + it.x + 1
    local coord = remap[idx]
    it(sampleBilinear(image, coord.sx, coord.sy, w, h))
  end

  -- Apply corner radius by clearing corners (capped at half the short side
  -- so the rounded corners can never swallow the picture)
  if corner_radius > 0 then
    local max_cr = math.floor(math.min(w, h) / 2)
    corner_radius = math.min(corner_radius, max_cr)
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
