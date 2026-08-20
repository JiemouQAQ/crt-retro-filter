# Changelog

All notable changes to the CRT Retro Filter extension.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.11.1] - 2026-02

### Changed
- **Screen Curvature** restored to the v3.4.1 behavior (barrel/pincushion, bilinear interpolation, original strength mapping), with two fixes:
  - Out-of-bounds sampling is now **edge-clamped** instead of writing transparent pixels — the warped image fully covers the original (no semi-transparent ghosting / see-through)
  - **Corner radius capped at 50% of the image's short side** so rounded corners can never swallow the picture

## [3.11.0] - 2026-02

### Fixed
- **Screen Curvature** — both barrel (convex) and pincushion (concave) modes kept, now with **boundary-fit compensation**:
  - Barrel no longer crops the picture (previously the outer ~25% of the source ring was never shown at full strength)
  - Pincushion no longer samples beyond the image or collapses the outer content onto a single radius (edge smear)
  - The remap's largest source radius is scaled exactly onto the canvas boundary: full picture always visible, canvas size and aspect ratio preserved, no transparent holes

## [3.10.0] - 2026-02

### Fixed
- **Screen Curvature** rewritten on the standard radial lens-distortion model (normalized `r_out = r_src(1 + k·r_src²)`):
  - **Negative (concave) values now work**: the old inverse solver clamped past the distortion peak to a radius beyond the image, wiping up to ~36% of the canvas to transparent. The inverse is now solved robustly in the monotonic region, and out-of-range samples are edge-clamped — no more holes.
  - **No more ghosting on positive (convex) values**: sampling switched from bilinear to nearest-neighbor, keeping pixel art crisp and consistent with the other filters.
  - All pixels always get a valid color (never transparent), determinism and the remap cache are preserved.

## [3.9.2] - 2026-02

### Fixed
- Randomize and preset switching now update the **combobox widgets visually** (mask type, directions, vignette ratio). Previously only the underlying params changed — the dropdowns displayed stale values because the wrong `modify` property (`text` instead of `option`) was used.

## [3.9.1] - 2026-02

### Changed
- Compare Original hint shortened to "(left-click to compare / 可左键对比)"
- Performance note moved from the Presets tab to directly under the preview compare checkbox
- Preview canvas margin reduced (12 → 4 px) and background lightened for a subtler frame

## [3.9.0] - 2026-02

### Added
- **Parameter animation (mechanism B)** — with *Per-Frame Evolution* on, the classic filters now animate via built-in waveforms (no keyframes, deterministic):
  - Horizontal Ripple: phase sweep (water wobble)
  - Color Temperature: warm/cool drift
  - Chromatic Aberration: channel-shift pulse
  - Screen Curvature: slow "breathing"
  - Bloom: glow pulse; Vignette: edge-darkening pulse
  - Pixelation: resolution step-flicker every 24 frames
  - RGB Phosphor Mask: pattern rolls right every 6 frames
  - Interlacing Jitter: comb shimmer
- **Real afterglow (mechanism C)** — Phosphor Persistence now blends the *previous frame's actual output* (params._prev) when evolving an animation, decaying by intensity — genuine phosphor persistence (falls back to the classic trail otherwise)
- Presets tab shows a performance note ("heavy jobs take a while, please wait")

### Changed
- Removed the progress-bar dialog (per user request); heavy jobs now run with the static note instead. Task cost guard and rollback protection remain.

## [3.8.0] - 2026-02

### Added
- **Progress bar** for heavy multi-frame jobs: a non-blocking dialog shows frame progress while "Apply to All Frames" runs (with a best-effort Cancel button)
- **Task cost guard**: before starting, the plugin estimates the pixel-filter workload; tasks estimated to take minutes are refused with a clear message instead of freezing the UI (suggestions: smaller canvas / fewer frames / fewer filters / lower strength)
- **Crash protection**: the whole apply pipeline is wrapped in error handling — failures roll back the transaction and show the error instead of leaving Aseprite in an undefined state
- No-op fast paths: applying with zero enabled filters does nothing (no wasted work)

### Changed (performance, stability-first)
- **Displacement** now caches per-cell offsets (~2 hash calls per cell instead of per pixel; identical results)
- **Pixel Sorting** precomputes run luminances (fewer per-pixel color calls; identical results)
- **Bloom** blends into the working buffer instead of cloning it (one less full-image clone)
- **Selection mask** skips its full pass when the selection covers the whole image

### Fixed
- (internal) selection mask fast-path coverage check

## [3.7.0] - 2026-02

### Added
- **Per-Frame Evolution** (逐帧演变): deterministic per-frame animation support
  - Noise and all 6 glitch filters (Slice Shift / Block Corruption / Pixel Sorting / VHS Tracking Band / Displacement / Mirror Tear) now derive their pattern seed from the frame number when enabled — fresh pattern every frame, fully reproducible
  - VHS Tracking Band additionally scrolls its position down ~3 rows per frame (tape transport drift)
  - Scanlines gain a separate **Interlace Flicker** toggle (alternate darkened rows per frame, classic CRT shimmer)
  - Dialog preview computes with the current frame number (what you see is what that frame gets)
  - Default off — existing behavior and saved settings are unaffected
- Internal frame context (`params._frame` / `_frames` / `_prev`) passed through the filter chain during multi-frame apply, cleared afterwards; reserved for future frame-dependent effects (mechanism B/C)

## [3.6.2] - 2026-02

### Changed
- Dialog: **Monochrome** and **Fixed Noise** checkboxes now share one row (noise tab)
- Added `ROADMAP.md` with the future development plan

## [3.6.1] - 2026-02

### Fixed
- **Disable All** button now also disables the 6 glitch filters (previously only the original 12); the enable-key list is now derived from the parameter table so future filters are covered automatically

### Changed
- Edit menu commands grouped into a **CRT Retro Filter** submenu (Open Dialog… / Quick Apply / Randomize), with a fallback to the flat menu on older Aseprite versions; command IDs unchanged so bound keyboard shortcuts keep working
- **Quick Apply** and **Randomize** have no default shortcuts (as before) but are fully bindable via **Edit → Keyboard Shortcuts**
- Dialog polish: Disable All + Reset Default buttons share one row; Compare Original hint folded into its label

## [3.6.0] - 2026-02

### Added
- **Mirror Tear** (镜像撕裂) filter: selected strips are reflected (left-right / top-bottom), 17 → 18 filters total
- Glitch tab split into two tabs (17 → 18 filter count, 6 → 7 tabs total):
  - **Data Glitch** (数据故障): Slice Shift, Block Corruption, Pixel Sorting
  - **Signal Glitch** (信号故障): VHS Tracking Band, Displacement, Mirror Tear
- **Heavy Glitch** preset now also stacks Mirror Tear

## [3.5.0] - 2026-02

### Added
- **Glitch Art tab** (5 new deterministic filters, 12 → 17 total):
  - **Slice Shift** (行撕裂) — random horizontal band tearing
  - **Block Corruption** (数据损坏) — data-moshing rectangular blocks
  - **Pixel Sorting** (像素排序) — classic luminance-sorted scan lines
  - **VHS Tracking Band** (VHS 跟踪条) — damaged-tape interference band
  - **Displacement** (置换扭曲) — random vector-field warp (horizontal / vertical / both)
- New preset **Digital Glitch** (数字故障): pixel sorting + slice tearing + corruption
- **Heavy Glitch** preset now stacks all glitch filters on top of its existing effects
- All glitch effects are deterministic: identical parameters produce identical output, so *Apply to All Frames* keeps patterns stable across animation frames

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
