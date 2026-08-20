-- ============================================================
-- CRT Retro Filter - Screen Curvature
-- Simulates the curved surface of a CRT display using the standard
-- radial lens-distortion model (r_out = r_src * (1 + k * r_src^2),
-- normalized radii) with BOTH barrel (convex, k > 0) and pincushion
-- (concave, k < 0) modes.
-- The remap is boundary-fitted: the largest source radius is scaled
-- onto the canvas boundary, so the full picture is always visible —
-- barrel no longer crops the corners and pincushion no longer
-- samples out of bounds or collapses the edges. Canvas size and
-- aspect ratio are preserved. Nearest-neighbor sampling keeps
-- pixel art crisp. Creates a new image (does not modify in-place).
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

-- Apply screen curvature to an image
-- Returns a new image (does NOT modify the original)
-- params:
--   curvature_amount: -100 (concave/pincushion) to 100 (convex/barrel)
--   curvature_corner_radius: 0-100, rounded corner radius in pixels
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
  if max_dist < 1 then max_dist = 1 end
  -- Normalized radial coefficient: positive = convex (barrel),
  -- negative = concave (pincushion). k in [-0.6, 0.6].
  local k = (curvature / 100.0) * 0.6

  -- Try to get cached remap table
  local cacheKey = w .. "_" .. h .. "_" .. curvature
  local remap = remapCache[cacheKey]

  if not remap then
    -- Pass 1: raw radial inverse for every output pixel, tracking the
    -- maximum source radius used.
    remap = {}
    local idx = 0
    local maxSrc = 0
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local sx, sy = MathUtils.inverseBarrelDistortion(x, y, cx, cy, k, max_dist)
        idx = idx + 1
        remap[idx] = { sx = sx, sy = sy }
        local sr = math.sqrt((sx - cx) * (sx - cx) + (sy - cy) * (sy - cy))
        if sr > maxSrc then maxSrc = sr end
      end
    end

    -- Pass 2: boundary-fit compensation. Scale every source position so
    -- the largest source radius maps exactly onto the canvas boundary.
    -- This fixes both modes:
    --   barrel   -> outer source ring was cropped (never shown)
    --   pincushion -> corners sampled beyond the image / collapsed onto
    --                 one radius (edge smear)
    -- After the fit: no cropping, no out-of-bounds sampling, the whole
    -- picture is always visible and the canvas/proportions are preserved.
    if maxSrc > 0 and math.abs(maxSrc - max_dist) > 0.5 then
      local fit = max_dist / maxSrc
      for i = 1, idx do
        local c = remap[i]
        c.sx = cx + (c.sx - cx) * fit
        c.sy = cy + (c.sy - cy) * fit
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