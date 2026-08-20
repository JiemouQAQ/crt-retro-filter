-- ============================================================
-- CRT Retro Filter - Noise / Static
-- Simulates CRT signal noise by adding random pixel variations.
-- Uses fast pseudo-random hash instead of math.randomseed for
-- much better performance.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local Noise = {}

-- Apply noise to an image (modifies in-place)
-- params:
--   intensity: 0-100, noise strength
--   grain_size: 1-4, noise grain size in pixels
--   monochrome: true/false, whether noise is luminance-only
--   fixed: true/false, use a constant seed so repeated applies
--         produce the same pattern (useful for animations)
function Noise.apply(image, params)
  local intensity = params.noise_intensity or 20
  local grain_size = params.noise_grain_size or 1
  local monochrome = params.noise_monochrome
  local enabled = params.noise_enabled

  if enabled == false or intensity == 0 then return end

  local noise_level = intensity / 100.0 * 255.0
  -- Frame-based seed for temporal variation; a constant seed when
  -- "fixed noise" is enabled keeps the pattern stable across frames.
  -- In per-frame evolution mode the seed derives from the frame number,
  -- giving deterministic film-grain animation.
  local frameSeed
  if params.noise_fixed then
    frameSeed = 12345
  elseif params.anim_enabled and params._frame then
    frameSeed = 137 + params._frame * 97
  else
    frameSeed = os.time() % 10007
  end

  for it in image:pixels() do
    local gx = math.floor(it.x / grain_size)
    local gy = math.floor(it.y / grain_size)

    local pixel = it()
    local r, g, b, a = ColorUtils.getRGBA(pixel)

    if monochrome then
      local noise_val = (MathUtils.fastHash(gx, gy, frameSeed) - 0.5) * 2.0 * noise_level
      it(ColorUtils.makeRGBA(
        ColorUtils.clamp(r + noise_val, 0, 255),
        ColorUtils.clamp(g + noise_val, 0, 255),
        ColorUtils.clamp(b + noise_val, 0, 255),
        a
      ))
    else
      local nr = ColorUtils.clamp(r + (MathUtils.fastHash(gx, gy, frameSeed + 1) - 0.5) * 2.0 * noise_level, 0, 255)
      local ng = ColorUtils.clamp(g + (MathUtils.fastHash(gx, gy, frameSeed + 2) - 0.5) * 2.0 * noise_level, 0, 255)
      local nb = ColorUtils.clamp(b + (MathUtils.fastHash(gx, gy, frameSeed + 3) - 0.5) * 2.0 * noise_level, 0, 255)
      it(ColorUtils.makeRGBA(nr, ng, nb, a))
    end
  end
end

return Noise