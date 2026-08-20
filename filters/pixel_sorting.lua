-- ============================================================
-- CRT Retro Filter - Pixel Sorting (像素排序)
-- The most iconic glitch-art technique: within processed scan
-- lines, contiguous runs of pixels brighter than the threshold
-- are sorted by luminance, producing the classic gradient smear.
-- Deterministic: line selection and runs come from fixed hashes.
-- ============================================================

local ColorUtils = require("utils.color")
local MathUtils = require("utils.math")

local PixelSorting = {}

local function luma(pixel)
  local r = app.pixelColor.rgbaR(pixel)
  local g = app.pixelColor.rgbaG(pixel)
  local b = app.pixelColor.rgbaB(pixel)
  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

-- Insertion sort by luminance (ascending). Lumas are precomputed so
-- the sort only does array reads, keeping the exact same result as
-- before with far fewer per-pixel color calls.
local function sortRun(values, lumas)
  for i = 2, #values do
    local v = values[i]
    local lv = lumas[i]
    local j = i - 1
    while j >= 1 and lumas[j] > lv do
      values[j + 1] = values[j]
      lumas[j + 1] = lumas[j]
      j = j - 1
    end
    values[j + 1] = v
    lumas[j + 1] = lv
  end
end

-- Apply pixel sorting (modifies in-place)
-- params:
--   pixel_sorting_enabled: boolean
--   pixel_sorting_intensity: 0-100, fraction of lines processed
--   pixel_sorting_threshold: 0-100, only runs above this brightness
--   pixel_sorting_direction: "horizontal" | "vertical"
function PixelSorting.apply(image, params)
  if params.pixel_sorting_enabled == false then return end
  local intensity = params.pixel_sorting_intensity or 70
  local threshold = (params.pixel_sorting_threshold or 60) / 100.0 * 255.0
  local direction = params.pixel_sorting_direction or "horizontal"
  if intensity <= 0 then return end

  local w = image.width
  local h = image.height
  if w <= 0 or h <= 0 then return end

  local src = image:clone()
  local animOffset = MathUtils.animSeed(params, 193)
  local seed = 987 + animOffset

  local function sortLine(get, set, n)
    local i = 0
    while i < n do
      if luma(get(i)) > threshold then
        local run = {}
        local lumas = {}
        while i < n and luma(get(i)) > threshold do
          local p = get(i)
          run[#run + 1] = p
          lumas[#lumas + 1] = luma(p)
          i = i + 1
        end
        if #run > 1 then
          sortRun(run, lumas)
          local start = i - #run
          for j = 1, #run do
            set(start + j - 1, run[j])
          end
        end
      else
        i = i + 1
      end
    end
  end

  if direction == "vertical" then
    for x = 0, w - 1 do
      if MathUtils.fastHash(x, 0, seed) < intensity / 100.0 then
        sortLine(
          function(i) return src:getPixel(x, i) end,
          function(i, v) image:putPixel(x, i, v) end,
          h)
      end
    end
  else
    for y = 0, h - 1 do
      if MathUtils.fastHash(y, 0, seed) < intensity / 100.0 then
        sortLine(
          function(i) return src:getPixel(i, y) end,
          function(i, v) image:putPixel(i, y, v) end,
          w)
      end
    end
  end
end

return PixelSorting
