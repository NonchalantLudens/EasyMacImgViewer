# EasyMacImgViewer
> 轻量级 macOS 图像查看器，支持 Live Photo。

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-lightgrey.svg)
![Language](https://img.shields.io/badge/language-Swift-orange.svg)
![Release](https://img.shields.io/badge/release-v1.0.0-blue.svg)

[English](README.md) | [简体中文](README.zh-CN.md)

原生 SwiftUI 图像查看器，零第三方依赖：文件夹感知导航、多窗口、平滑缩放、Live Photo 循环播放、GIF/WebP 动图，以及包含相机 RAW 在内的广泛格式支持。

## 目录

- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [安装](#安装)
- [使用指南](#使用指南)
- [故障排查](#故障排查)
- [构建](#构建)
- [项目结构](#项目结构)
- [参与贡献](#参与贡献)
- [许可](#许可)

## 功能特性

- **文件夹感知导航** — 打开文件时自动扫描同目录图像，按 Finder 自然顺序排列；鼠标（点击左右边缘）或键盘（←/→/空格）切换
- **多窗口** — 打开另一张图片默认新开独立窗口（Finder 双击、⌘O 多选）
- **缩放** — 工具栏按钮（平滑动画）、触控板捏合、⌘+滚轮、双击切换 100%/适合窗口、⌘0/⌘1/⌘+/⌘−
- **Live Photo** — 同目录配对 .mov/.mp4 循环播放（含声音）；支持同名与 `_HEVC` 命名模式及 ContentIdentifier 元数据兜底配对；视频未随文件传输时给出提示
- **动图** — GIF / 动画 WebP 帧播放
- **格式** — JPEG / PNG / GIF / TIFF / BMP / WebP / HEIC / HEIF / JPEG XL / SVG / ICNS / JPEG-2000 / 常见相机 RAW（CR2 / NEF / ARW / DNG / RAF / ORF / RW2 等），自动纠正 EXIF 方向
- **放大拖移** — 放大后鼠标拖拽平移（抓手光标、边界钳制）
- **原生 macOS UI** — 统一工具栏、毛玻璃信息叠加层、深色自适应

## 系统要求

| 项目 | 要求 |
| --- | --- |
| macOS | 15.0 (Sequoia) 或更高 |
| 架构 | Apple Silicon 或 Intel |

## 安装

从 [Releases](https://github.com/NonchalantLudens/EasyMacImgViewer/releases) 页面下载最新安装包：

```bash
# 方式一：GUI — 打开 DMG，将 EasyMacImgViewer 拖入 Applications
open EasyMacImgViewer-1.0.0.dmg

# 方式二：命令行 — 挂载、拷贝、卸载
hdiutil attach EasyMacImgViewer-1.0.0.dmg
cp -R "/Volumes/EasyMacImgViewer/EasyMacImgViewer.app" /Applications/
hdiutil detach /Volumes/EasyMacImgViewer
```

未公证构建首次启动：右键 app → 打开 → 确认。

## 使用指南

| 操作 | 方式 |
| --- | --- |
| 打开图像 | ⌘O，或 Finder 双击文件，或拖入 app |
| 上一张 / 下一张 | ← / → / 空格，或点击窗口左右 12% 边缘 |
| 放大 / 缩小 | 工具栏按钮、触控板捏合、⌘+滚轮、⌘+ / ⌘− |
| 适合窗口 / 实际大小 | 双击、⌘0 / ⌘1 |
| 放大后平移 | 鼠标拖拽（抓手光标） |
| 播放 Live Photo | 点击「Live」徽标或工具栏按钮 |
| 播放 / 暂停动图 | 工具栏播放按钮 |

## 故障排查

1. **Live Photo 显示为静态图**
   - 检查同目录下是否存在同名（或 `_HEVC` 后缀）的 `.mov` 配对文件。AirDrop 及多数分享通道只传输静态帧；请使用 AirDrop 到「照片」，或经 icloudpd 下载原片。
2. **RAW 文件打不开**
   - 完整解码需 macOS 15+；超大 RAW 解码需数秒，界面会显示进度指示。
3. **缩放速度不适**
   - 滚轮缩放现需按住 ⌘；触控板捏合不受影响。
4. **出现「视频部分未随文件传输」提示**
   - HEIC 内含 Live Photo 元数据但缺少配对 MOV —— 请重新传输并保持文件成对。

## 构建

```sh
xcodebuild -project EasyMacImgViewer.xcodeproj -scheme EasyMacImgViewer -configuration Release build
```

产物：`build/Build/Products/Release/EasyMacImgViewer.app`

运行测试：

```sh
xcodebuild test -project EasyMacImgViewer.xcodeproj -scheme EasyMacImgViewer -destination 'platform=macOS'
```

## 项目结构

```text
EasyMacImgViewer/
├── App/        应用入口、窗口场景、文件打开处理、菜单命令
├── Models/     查看器状态模型（导航/缩放/平移）
├── Services/   目录扫描、图像解码、Live Photo 配对
├── Views/      窗口/画布/工具栏/叠加层视图
├── LivePhoto/  Live Photo 与动图播放器
└── Resources/  Info.plist、应用图标
```

## 参与贡献

开发流程与提交规范见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可

[MIT](LICENSE) © 2026 NonchalantLudens
