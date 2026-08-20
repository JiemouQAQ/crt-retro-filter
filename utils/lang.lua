-- ============================================================
-- CRT Retro Filter - Language Module
-- EN / ZH bilingual support
-- ============================================================

local Lang = {}

local strings = {
  en = {
    -- Dialog title / global
    dialog_title = "CRT Retro Filter",
    no_image = "No active image to apply filters to.",
    indexed_error = "Indexed color mode is not supported.\nPlease convert to RGB mode first:\nSprite > Color Mode > RGB",
    grayscale_error = "Grayscale color mode is not supported.\nPlease convert to RGB mode first:\nSprite > Color Mode > RGB",
    lang_label = "Language:",

    -- Tabs
    tab_presets = "Presets",
    tab_screen = "Screen",
    tab_display = "Display",
    tab_pixel = "Pixel",
    tab_signal = "Signal",
    tab_glitch_data = "Data Glitch",
    tab_glitch_signal = "Signal Glitch",

    -- Presets tab
    preset_label = "Preset:",
    preset_custom = "Custom",
    save_preset = "Save Preset",
    delete_preset = "Delete Preset",
    preset_name_prompt = "Enter preset name:",
    preset_saved = "Preset saved: ",
    preset_deleted = "Preset deleted: ",
    preset_name_empty = "Preset name cannot be empty.",
    preset_not_found = "Preset not found.",
    preset_name_exists = "A preset with this name already exists.",
    custom_presets = "Custom Presets",
    no_custom_presets = "No custom presets saved.",
    dup_layer = "Duplicate Layer Before Apply",
    sel_only = "Selection Only:",
    all_frames = "Apply to All Frames:",
    no_selection = "No active selection. Create a selection first, or uncheck Selection Only.",
    compare_orig = "Compare Original",
    compare_hint = "hold the mouse button to peek",

    -- Preset descriptions
    preset_arcade_name = "Classic Arcade",
    preset_arcade_desc = "Strong scanlines, noticeable curvature, vignette",
    preset_80s_name = "80s Computer",
    preset_80s_desc = "Moderate scanlines, subtle chromatic aberration",
    preset_tv_name = "Broadcast TV",
    preset_tv_desc = "Heavy curvature, strong aberration, large bloom",
    preset_subtle_name = "Subtle Retro",
    preset_subtle_desc = "Very light scanlines and vignette only",
    preset_monitor_name = "CRT Monitor",
    preset_monitor_desc = "90s PC: thin scanlines, light bloom, RGB mask",
    preset_vhs_name = "VHS Tape",
    preset_vhs_desc = "Degraded VHS: jitter, noise, color bleed",
    preset_trinitron_name = "Trinitron",
    preset_trinitron_desc = "Sony aperture grille, deep contrast, sharp",
    preset_pixel_perfect_name = "Pixel Perfect",
    preset_pixel_perfect_desc = "Minimal CRT: subtle scanlines, no distortion",
    preset_glitch_name = "Heavy Glitch",
    preset_glitch_desc = "Experimental: all effects maxed for glitch art",
    preset_glitch_digital_name = "Digital Glitch",
    preset_glitch_digital_desc = "Classic glitch art: pixel sorting, slice tearing, data corruption",
    randomize_btn = "Randomize",
    disable_all_btn = "Disable All",
    reset_default_btn = "Reset Default",
    preset_strength = "Preset Strength:",

    -- Screen tab
    sep_scanlines = "Scanlines",
    enable = "Enable:",
    intensity = "Intensity:",
    thickness = "Thickness:",
    sep_curvature = "Screen Curvature",
    curvature = "Curvature:",
    corner = "Corner:",
    sep_aberration = "Chromatic Aberration",
    red_shift = "Red Shift:",
    blue_shift = "Blue Shift:",
    falloff = "Falloff:",

    -- Display tab
    sep_bloom = "Bloom / Glow",
    threshold = "Threshold:",
    radius = "Radius:",
    sep_vignette = "Vignette",
    inner = "Inner:",
    softness = "Softness:",
    ratio = "Ratio:",
    ratio_auto = "Auto",
    ratio_1_1 = "1:1",
    ratio_4_3 = "4:3",
    ratio_16_9 = "16:9",
    sep_noise = "Noise / Static",
    grain = "Grain:",
    monochrome = "Monochrome",
    noise_fixed = "Fixed Noise",

    -- Pixel tab
    sep_color_temp = "Color Temperature",
    color_temp_value = "Kelvin:",
    warm = "Warm",
    cool = "Cool",
    sep_pixelation = "Pixelation",
    block_size = "Block Size:",
    sep_rgb_mask = "RGB Phosphor Mask",
    mask_type = "Mask Type:",
    mask_grille = "Aperture Grille",
    mask_shadow = "Shadow Mask",
    mask_slot = "Slot Mask",
    stripe_width = "Element Width:",
    direction = "Direction:",
    dir_vertical = "Vertical",
    dir_horizontal = "Horizontal",
    dir_both = "Both",

    -- Signal tab
    sep_ripple = "Horizontal Ripple",
    amplitude = "Amplitude:",
    frequency = "Frequency:",
    phase = "Phase:",
    sep_jitter = "Interlacing Jitter",
    displacement = "Displacement:",
    sep_persistence = "Phosphor Persistence",
    persistence = "Persistence:",

    -- Glitch tab
    sep_slice_shift = "Slice Shift",
    sep_block_corruption = "Block Corruption",
    sep_pixel_sorting = "Pixel Sorting",
    sep_tracking_band = "VHS Tracking Band",
    sep_displacement = "Displacement",
    sep_mirror_tear = "Mirror Tear",
    density = "Density:",
    shift_amount = "Shift:",
    band_width = "Band Width:",
    position = "Position:",
    scale = "Scale:",

    -- Buttons
    apply = "Apply",
    cancel = "Cancel",

    -- Transaction names
    txn_single = "CRT Retro Filter",
  },

  zh = {
    -- Dialog title / global
    dialog_title = "CRT 复古滤镜",
    no_image = "没有可处理的图像。",
    indexed_error = "不支持索引色模式。\n请先转换为 RGB 模式：\n精灵 > 颜色模式 > RGB",
    grayscale_error = "不支持灰度模式。\n请先转换为 RGB 模式：\n精灵 > 颜色模式 > RGB",
    lang_label = "语言:",

    -- Tabs
    tab_presets = "预设",
    tab_screen = "屏幕",
    tab_display = "显示",
    tab_pixel = "像素",
    tab_signal = "信号",
    tab_glitch_data = "数据故障",
    tab_glitch_signal = "信号故障",

    -- Presets tab
    preset_label = "预设:",
    preset_custom = "自定义",
    save_preset = "保存预设",
    delete_preset = "删除预设",
    preset_name_prompt = "输入预设名称:",
    preset_saved = "预设已保存: ",
    preset_deleted = "预设已删除: ",
    preset_name_empty = "预设名称不能为空。",
    preset_not_found = "未找到预设。",
    preset_name_exists = "该名称的预设已存在。",
    custom_presets = "自定义预设",
    no_custom_presets = "暂无自定义预设。",
    dup_layer = "复制图层再应用",
    sel_only = "只应用到选区:",
    all_frames = "应用到全部帧:",
    no_selection = "没有活动的选区，请先创建选区，或取消勾选「只应用到选区」。",
    compare_orig = "对比原图",
    compare_hint = "按住鼠标左键可临时查看",

    -- Preset descriptions
    preset_arcade_name = "经典街机",
    preset_arcade_desc = "强力扫描线、明显弧度、暗角",
    preset_80s_name = "80 年代电脑",
    preset_80s_desc = "中等扫描线、轻微色差",
    preset_tv_name = "老式电视",
    preset_tv_desc = "强弧度、重色差、大光晕",
    preset_subtle_name = "轻复古",
    preset_subtle_desc = "仅轻微扫描线和暗角",
    preset_monitor_name = "CRT 显示器",
    preset_monitor_desc = "90年代PC：细扫描线、轻微辉光、RGB遮罩",
    preset_vhs_name = "VHS 录像带",
    preset_vhs_desc = "录像带劣化：抖动、噪点、色彩偏移",
    preset_trinitron_name = "特丽珑",
    preset_trinitron_desc = "索尼栅格遮罩、高对比、锐利画面",
    preset_pixel_perfect_name = "像素完美",
    preset_pixel_perfect_desc = "极简CRT：微妙扫描线、无畸变",
    preset_glitch_name = "重度故障",
    preset_glitch_desc = "实验风格：所有效果全开、故障艺术",
    preset_glitch_digital_name = "数字故障",
    preset_glitch_digital_desc = "经典故障艺术：像素排序、行撕裂、数据损坏",
    randomize_btn = "随机生成",
    disable_all_btn = "关闭全部",
    reset_default_btn = "恢复默认",
    preset_strength = "预设强度:",

    -- Screen tab
    sep_scanlines = "扫描线",
    enable = "启用:",
    intensity = "强度:",
    thickness = "粗细:",
    sep_curvature = "屏幕弧度",
    curvature = "弧度:",
    corner = "圆角:",
    sep_aberration = "色差",
    red_shift = "红通道偏移:",
    blue_shift = "蓝通道偏移:",
    falloff = "衰减:",

    -- Display tab
    sep_bloom = "辉光",
    threshold = "阈值:",
    radius = "半径:",
    sep_vignette = "暗角",
    inner = "内径:",
    softness = "柔和度:",
    ratio = "宽高比:",
    ratio_auto = "自动",
    ratio_1_1 = "1:1",
    ratio_4_3 = "4:3",
    ratio_16_9 = "16:9",
    sep_noise = "噪点",
    grain = "颗粒:",
    monochrome = "单色",
    noise_fixed = "固定噪点",

    -- Pixel tab
    sep_color_temp = "色温",
    color_temp_value = "色温:",
    warm = "暖色",
    cool = "冷色",
    sep_pixelation = "像素化",
    block_size = "块大小:",
    sep_rgb_mask = "RGB 荧光粉遮罩",
    mask_type = "遮罩类型:",
    mask_grille = "栅格遮罩",
    mask_shadow = "点阵遮罩",
    mask_slot = "槽状遮罩",
    stripe_width = "元素宽度:",
    direction = "方向:",
    dir_vertical = "垂直",
    dir_horizontal = "水平",
    dir_both = "双向",

    -- Signal tab
    sep_ripple = "水平波纹",
    amplitude = "振幅:",
    frequency = "频率:",
    phase = "相位:",
    sep_jitter = "隔行扫描抖动",
    displacement = "偏移:",
    sep_persistence = "荧光粉余晖",
    persistence = "余晖:",

    -- Glitch tab
    sep_slice_shift = "行撕裂",
    sep_block_corruption = "数据损坏",
    sep_pixel_sorting = "像素排序",
    sep_tracking_band = "VHS 跟踪条",
    sep_displacement = "置换扭曲",
    sep_mirror_tear = "镜像撕裂",
    density = "密度:",
    shift_amount = "位移:",
    band_width = "条宽:",
    position = "位置:",
    scale = "缩放:",

    -- Buttons
    apply = "应用",
    cancel = "取消",

    -- Transaction names
    txn_single = "CRT 复古滤镜",
  },
}

-- ============================================================
-- Get current language from preferences
-- ============================================================
function Lang.get(prefs)
  local lang = (prefs and prefs.lang) or "en"
  if not strings[lang] then lang = "en" end
  return strings[lang]
end

-- ============================================================
-- Get a single string by key
-- ============================================================
function Lang.t(key, prefs)
  local t = Lang.get(prefs)
  return t[key] or key
end

-- ============================================================
-- Available languages
-- ============================================================
Lang.available = { "en", "zh" }
Lang.names = { en = "English", zh = "中文" }

return Lang