# Changelog

本项目所有重要变更记录于此，格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本遵循[语义化版本](https://semver.org/lang/zh-CN/)。版本条目含中英双语标题与摘要。

## [Unreleased]

### 新增 / Added

- 侧边栏：可收回的图像列表（⌘⌥S），缩略图/列表双模式可切换，点击切换图像 / Sidebar: collapsible image list (⌘⌥S) with thumbnail / list modes, click to switch
- 照片文件夹识别（iPhone「所有数据」模式，View 菜单开关）：将每照片文件夹视为一张图像，支持裁切副本（原图 + `IMG_E` 编辑版 + AAE）与编辑版优先开关 / Photo folder recognition (iPhone "Full Data" mode, View menu toggle): treats each photo folder as one image, supports edited copies (original + `IMG_E` edited version + AAE) with an edited-version preference toggle

## [1.0.0] - 2026-08-08

### Summary / 摘要

Lightweight macOS image viewer with folder-aware navigation, multi-window, smooth zoom, Live Photo playback, animated GIF/WebP, and camera RAW support. / 轻量级 macOS 图像查看器，支持文件夹感知导航、多窗口、平滑缩放、Live Photo 播放、GIF/WebP 动图与相机 RAW。

### 新增 / Added

- 文件夹感知导航：打开文件时自动扫描同目录图像（Finder 自然排序），支持鼠标（左右边缘点击）与键盘（←/→/空格）切换 / Folder-aware navigation: auto-scans the folder of the opened file (Finder natural order), switch via mouse (left/right edges) or keyboard (←/→/Space)
- 多窗口：每次打开新图片默认新开独立窗口（Finder 双击、⌘O 多选）/ Multi-window: opening another image always opens a new independent window (Finder double-click, ⌘O multi-select)
- 缩放：工具栏按钮（平滑动画）、触控板捏合、⌘+滚轮、双击切换 100%/适合窗口、⌘0/⌘1/⌘+/⌘− / Zoom: toolbar buttons (smooth animation), trackpad pinch, ⌘+scroll, double-click toggles 100%/fit, ⌘0/⌘1/⌘+/⌘−
- Live Photo：同目录配对视频（.mov/.mp4）循环播放（含声音）；支持同名与 `_HEVC` 命名模式及 ContentIdentifier 元数据兜底配对；视频未随文件传输时给出提示 / Live Photo: loop playback with sound for paired videos; same-name and `_HEVC` naming patterns plus ContentIdentifier fallback; hints when the video part was not transferred
- 动图：GIF / 动画 WebP 帧播放 / Animated images: GIF / animated WebP frame playback
- 格式：JPEG / PNG / GIF / TIFF / BMP / WebP / HEIC / HEIF / JPEG XL / SVG / ICNS / JPEG-2000 / 常见相机 RAW（CR2 / NEF / ARW / DNG / RAF / ORF / RW2 等），自动纠正 EXIF 方向 / Formats: JPEG / PNG / GIF / TIFF / BMP / WebP / HEIC / HEIF / JPEG XL / SVG / ICNS / JPEG-2000 / common camera RAW (CR2 / NEF / ARW / DNG / RAF / ORF / RW2 etc.), with EXIF orientation correction
- 放大拖移：放大后鼠标拖拽平移（抓手光标、边界钳制）/ Drag to pan: when zoomed in, mouse drag pans the image (grab cursor, clamped edges)
- macOS 标准 UI：统一工具栏、毛玻璃信息叠加层、深色自适应 / Native macOS UI: unified toolbar, frosted-glass info overlay, dark-mode aware
- 国际化：UI 文案支持中英双语（String Catalog）/ Localization: UI text in Chinese and English (String Catalog)
