# Changelog

All notable changes to the CRT Retro Filter extension.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.4.1] - 2026-02

### Changed
- CI: added GitHub Actions workflow that auto-packages the extension and publishes a GitHub Release on `v*` tags (first release through the pipeline)

## [3.4.0] - 2026-02

### Added
- **Apply to All Frames**: apply the filter chain to every frame of the active layer in a single undo step (pair it with *Fixed Noise* for flicker-free animation)
- Dialog title now shows the extension version (e.g. `CRT Retro Filter v3.4.0`)

### Fixed
- Slider widgets now update visually when switching built-in/custom presets or randomizing (previously only the values changed, the thumb position did not)

### Changed
- `curvature.lua` corner radius doc comment aligned with the 0–100 slider range

## [3.3.0] - 2026-02

### Added
- **Preset Strength** slider (0–100%): dials the overall effect intensity of all filters by blending the filtered result toward the original image
  - 0% short-circuits to the original; 100%/absent = full effect
  - Kept when switching built-in presets; stored inside saved custom presets
  - Menu *Randomize* inherits the saved strength

## [3.2.0] - 2026-02

### Added
- **Selection Support**: apply filters to the selected area only
  - `Selection Only` checkbox in the Presets tab; alert when no selection is active
  - Preview reflects the masked result (cel-offset aware)
  - Works with Quick Apply and Randomize menu commands

## [3.1.0] - 2026-02

### Added
- **Before/After Compare**: hold the left mouse button on the preview canvas to peek at the original; `Compare Original` checkbox locks the original view (green border marks compare mode)
- **Fixed Noise** toggle: constant noise seed, stable when applied per animation frame

### Fixed
- Noise **Grain** slider was a no-op (wrong param key `grain_size` → `noise_grain_size`)
- Chromatic Aberration **Red/Blue Shift & Falloff** sliders were no-ops (wrong param keys)

### Changed
- Scanline **Intensity** semantics inverted: higher = darker rows (was inverted)

## [3.0.7] - 2026-02

### Added
- MIT `LICENSE` file (repository root)

### Fixed
- Randomize produced identical results when clicked twice within the same second (`os.time()` reseed) — now seeded once at init with sub-second entropy
- Removed dead duplicated branch in the scanlines filter

### Changed
- Randomize parameter table unified between the dialog button and the menu command (`DialogUI.generateRandomParams()`)

## [3.0.6] - 2026-02

### Added
- Vignette aspect-ratio presets (Auto / 1:1 / 4:3 / 16:9)
- `Disable All` and `Reset Default` buttons in the Presets tab

### Fixed
- Scanlines intensity bug
- Preset reset behavior

## [3.0.3] - 2026-01

### Added
- Initial release: 12 CRT filters, real-time on-canvas preview with change detection, 9 built-in presets, custom presets, Randomize, duplicate-layer option, bilingual EN/ZH interface, Quick Apply
