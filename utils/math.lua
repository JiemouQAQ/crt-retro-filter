-- ============================================================
-- CRT Retro Filter - Math Utilities
-- Gaussian kernel, coordinate mapping, and math helpers
-- ============================================================

local MathUtils = {}

-- Cache for Gaussian kernels: key = radius, value = kernel table
local gaussianKernelCache = {}

-- Generate a 1D Gaussian kernel of given radius and sigma
-- Radius is the half-width of the kernel (kernel_size = 2*radius + 1)
-- Results are cached for repeated use
function MathUtils.gaussianKernel(radius, sigma)
  local cacheKey = tostring(radius) .. "_" .. tostring(sigma or 0)
  if gaussianKernelCache[cacheKey] then
    return gaussianKernelCache[cacheKey]
  end

  sigma = sigma or (radius / 2.0)
  local size = 2 * radius + 1
  local kernel = {}
  local sum = 0.0

  for i = 0, size - 1 do
    local x = i - radius
    kernel[i + 1] = math.exp(-(x * x) / (2.0 * sigma * sigma))
    sum = sum + kernel[i + 1]
  end

  -- Normalize
  for i = 1, size do
    kernel[i] = kernel[i] / sum
  end

  gaussianKernelCache[cacheKey] = kernel
  return kernel
end

-- Seed the global RNG once with high-entropy state.
-- os.time() alone is second-precision: re-seeding it on every click within
-- the same second yields identical random sequences, so we mix in
-- sub-second CPU clock entropy. Call once at plugin init.
function MathUtils.seedRandom()
  local entropy = os.time() * 1000 + (math.floor(os.clock() * 1000) % 1000)
  math.randomseed(entropy)
end

-- Per-frame animation seed offset.
-- Returns 0 when "per-frame evolution" is off (or there is no frame
-- context), otherwise the frame number times a per-filter multiplier.
-- Multipliers differ per filter so their patterns decorrelate per frame.
function MathUtils.animSeed(params, multiplier)
  if params.anim_enabled and params._frame then
    return params._frame * multiplier
  end
  return 0
end

-- Sine oscillation for parameter animation (mechanism B).
-- Returns a value between min and max driven by the frame number.
-- period: frames per full cycle; phaseDeg: phase offset in degrees.
function MathUtils.animWave(params, period, minVal, maxVal, phaseDeg)
  local f = params._frame or 0
  local phase = (phaseDeg or 0) * math.pi / 180.0
  local t = (math.sin(f * 2.0 * math.pi / period + phase) + 1.0) / 2.0 -- 0..1
  return minVal + (maxVal - minVal) * t
end

-- Square-wave step for parameter animation (mechanism B).
-- Returns minVal or maxVal, alternating every `period` frames.
function MathUtils.animStep(params, period, minVal, maxVal, phaseFrames)
  local f = params._frame or 0
  local step = math.floor((f + (phaseFrames or 0)) / period) % 2
  if step == 0 then return minVal end
  return maxVal
end

-- Fast pseudo-random hash returning [0, 1) from integer coordinates
-- Uses Knuth multiplicative hash, pure integer arithmetic (no bit32 needed)
function MathUtils.fastHash(x, y, seed)
  local n = (x * 374761393 + y * 668265263 + (seed or 0) * 1274126177) % 2147483647
  n = (n * 2654435761) % 4294967296
  n = (n * 2654435761) % 4294967296
  return (n % 1048576) / 1048576.0
end

-- Barrel distortion: map output coordinate to source coordinate
-- k: curvature coefficient (0 = flat, positive = barrel)
-- cx, cy: center of distortion
function MathUtils.barrelDistortion(x, y, cx, cy, k)
  local dx = x - cx
  local dy = y - cy
  local r = math.sqrt(dx * dx + dy * dy)
  -- Barrel distortion: r' = r * (1 + k * r^2)
  local factor = 1.0 + k * r * r
  return cx + dx * factor, cy + dy * factor
end

-- Inverse distortion: map output coordinate back to source.
-- k is in absolute units (e.g. curvature/100 * 0.3 / max_dist_sq).
-- Uses Newton's method for the approximate inverse.
-- k > 0: barrel (convex), k < 0: pincushion (concave).
function MathUtils.inverseBarrelDistortion(x, y, cx, cy, k, max_r)
  if k == 0 then return x, y end

  local dx = x - cx
  local dy = y - cy
  local r = math.sqrt(dx * dx + dy * dy)

  if r < 0.001 then return x, y end

  -- For pincushion (k < 0), check if r exceeds the maximum mappable radius
  if k < 0 then
    local r_peak = math.sqrt(-1.0 / (3.0 * k))
    local f_peak = r_peak * (1.0 + k * r_peak * r_peak)
    if r > f_peak then
      local scale = r_peak / r
      return cx + dx * scale, cy + dy * scale
    end
  end

  -- Newton's method to solve r = r' * (1 + k * r'^2) for r'
  local r_prime = r
  for _ = 1, 5 do
    local f = r_prime * (1.0 + k * r_prime * r_prime) - r
    local df = 1.0 + 3.0 * k * r_prime * r_prime
    if math.abs(df) < 1e-10 then break end
    r_prime = r_prime - f / df
    r_prime = math.max(0, r_prime)
  end

  local scale = r_prime / r
  return cx + dx * scale, cy + dy * scale
end

-- Calculate distance from point to center, normalized to [0, 1]
function MathUtils.normalizedDistance(x, y, cx, cy, max_dist)
  local dx = x - cx
  local dy = y - cy
  local dist = math.sqrt(dx * dx + dy * dy)
  return math.min(1.0, dist / (max_dist or 1.0))
end

-- Smoothstep function
function MathUtils.smoothstep(edge0, edge1, x)
  local t = math.max(0, math.min(1, (x - edge0) / (edge1 - edge0)))
  return t * t * (3.0 - 2.0 * t)
end

-- Bilinear interpolation for a 2D grid of values
-- values is a 2x2 table: {{v00, v01}, {v10, v11}}
-- tx, ty are fractional positions [0, 1]
function MathUtils.bilerp(v00, v01, v10, v11, tx, ty)
  local top = v00 * (1 - tx) + v01 * tx
  local bottom = v10 * (1 - tx) + v11 * tx
  return top * (1 - ty) + bottom * ty
end

return MathUtils