# EasyMacImgViewer

轻量级 macOS 图像查看器。原生 SwiftUI，无第三方依赖，macOS 15+。

## 功能

- **文件夹自动识别**：打开文件时自动扫描同目录图像，按 Finder 自然顺序排列，支持鼠标（点击左右边缘 12% 区域）/键盘（←/→/空格）切换
- **多窗口**：每次打开新图片默认新开独立窗口（Finder 双击、⌘O 多选均可）
- **缩放**：工具栏按钮（平滑动画）、触控板捏合、⌘+滚轮、双击切换 100%/适合窗口、⌘0/⌘1/⌘+/⌘−
- **Live Photo**：检测同目录配对视频（.mov/.mp4），点击循环播放（含声音）；支持同名与 `_HEVC` 后缀两种命名模式，及 ContentIdentifier 元数据兜底配对；视频未随文件传输时给出提示
- **动图**：GIF / 动画 WebP 帧播放
- **格式**：JPEG / PNG / GIF / TIFF / BMP / WebP / HEIC / HEIF / JPEG XL / SVG / ICNS / JPEG-2000 / 常见相机 RAW（CR2 / NEF / ARW / DNG / RAF / ORF / RW2 等），自动纠正 EXIF 方向
- **放大拖移**：放大后鼠标拖拽平移（抓手光标、边界钳制）
- **macOS 标准 UI**：统一工具栏、毛玻璃信息叠加层、深色自适应

## 构建

```sh
xcodebuild -project EasyMacImgViewer.xcodeproj -scheme EasyMacImgViewer -configuration Release build
```

产物位于 `build/Build/Products/Release/EasyMacImgViewer.app`。

## 测试

```sh
xcodebuild test -project EasyMacImgViewer.xcodeproj -scheme EasyMacImgViewer -destination 'platform=macOS'
```

## 项目结构

```
EasyMacImgViewer/
├── App/        应用入口、窗口场景、文件打开处理、菜单命令
├── Models/     查看器状态模型（导航/缩放/平移）
├── Services/   目录扫描、图像解码、Live Photo 配对
├── Views/      窗口/画布/工具栏/叠加层视图
├── LivePhoto/  Live Photo 与动图播放器
└── Resources/  Info.plist、应用图标
```
