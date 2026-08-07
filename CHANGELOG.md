# Changelog

本项目所有重要变更记录于此，格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，版本遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2026-08-08

### 新增

- 文件夹自动识别：打开文件时自动扫描同目录图像，按 Finder 自然顺序排列，支持鼠标（左右边缘点击）与键盘（←/→/空格）切换
- 多窗口：每次打开新图片默认新开独立窗口（Finder 双击、⌘O 多选）
- 缩放：工具栏按钮（平滑动画）、触控板捏合、⌘+滚轮、双击切换 100%/适合窗口、⌘0/⌘1/⌘+/⌘−
- Live Photo：同目录配对视频（.mov/.mp4）循环播放（含声音）；支持同名与 `_HEVC` 后缀命名模式及 ContentIdentifier 元数据兜底配对；视频未随文件传输时给出提示
- 动图：GIF / 动画 WebP 帧播放
- 格式：JPEG / PNG / GIF / TIFF / BMP / WebP / HEIC / HEIF / JPEG XL / SVG / ICNS / JPEG-2000 / 常见相机 RAW（CR2 / NEF / ARW / DNG / RAF / ORF / RW2 等），自动纠正 EXIF 方向
- 放大拖移：放大后鼠标拖拽平移（抓手光标、边界钳制）
- macOS 标准 UI：统一工具栏、毛玻璃信息叠加层、深色自适应
