# 环境配置文档

## 概述
本文档描述如何设置 DeskCal 项目的开发环境。DeskCal 是一个 macOS 桌面日历应用，使用 Swift 和 Swift Package Manager 构建。

## 系统要求
- macOS 11.0 或更高版本
- Swift 6.2 或更高版本（推荐使用 Xcode 命令行工具）
- 磁盘空间：约 100 MB

## 开发环境设置

### 1. 安装 Swift 工具链
```bash
# 检查 Swift 版本
swift --version

# 如果未安装 Swift，安装 Xcode 命令行工具：
xcode-select --install
```

### 2. 克隆项目
```bash
git clone <repository-url>
cd desk_cal
```

### 3. 项目结构
```
desk_cal/
├── Package.swift              # Swift Package Manager 配置文件
├── Sources/DeskCal/           # 主程序源代码
│   └── DeskCal.swift          # 程序入口点
└── doc/                       # 项目文档
```

### 4. 构建项目
```bash
# 使用 Swift Package Manager 构建
swift build

# 构建发布版本
swift build -c release
```

### 5. 运行程序
```bash
# 运行调试版本
./.build/debug/DeskCal

# 运行发布版本
./.build/release/DeskCal
```

## 项目配置

### Package.swift
项目使用 Swift Package Manager 管理，配置如下：
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DeskCal",
    platforms: [
        .macOS(.v11)
    ],
    targets: [
        .executableTarget(
            name: "DeskCal"
        ),
    ]
)
```

### 依赖项
- **AppKit**: macOS 应用程序框架（系统自带）
- **Foundation**: 基础框架（系统自带）
- **Core Graphics**: 图形绘制框架（通过 AppKit 间接使用）

## 阶段 0 验证

### 功能验证
阶段 0 实现了以下核心功能，可用于验证环境配置：

1. **图片生成**: 使用 Core Graphics 创建简单图片
2. **墙纸设置**: 使用 NSWorkspace 将图片设置为桌面墙纸
3. **多显示器支持**: 仅为主显示器设置墙纸

### 验证步骤
```bash
# 1. 构建项目
swift build

# 2. 运行测试
./.build/debug/DeskCal

# 预期输出：
# DeskCal starting...
# Created image at: /tmp/deskcal-xxxx.png
# Found X screen(s)
# Setting wallpaper for main screen (ID: Y, size: (width, height))
# Wallpaper set successfully for main screen
```

### 验证标准
- ✅ 项目成功构建，无编译错误
- ✅ 程序运行时不崩溃
- ✅ 生成 PNG 图片文件（1920×1080 像素）
- ✅ 主显示器墙纸被正确设置
- ✅ 扩展显示器墙纸保持不变
- ✅ 无内存泄漏，程序正常退出

## 故障排除

### 常见问题

#### 1. 构建错误 "cannot find module 'AppKit'"
- 确保在 macOS 系统上构建
- 检查 Xcode 命令行工具是否安装：`xcode-select -p`

#### 2. 墙纸设置失败
- 确保程序有必要的权限（通常不需要特殊权限）
- 检查图片文件路径是否可访问
- 验证图片格式是否为 PNG

#### 3. 屏幕检测不准确
- 确保外部显示器正确连接
- 检查系统显示器设置

#### 4. 内存泄漏警告
- 使用 Instruments 工具进行内存分析
- 确保正确释放 Core Graphics 资源

### 调试技巧
```bash
# 启用详细日志
export DEBUG=1

# 使用 Instruments 分析内存
xcrun xctrace record --template 'Allocations' --output .build/debug/DeskCal.trace --launch -- .build/debug/DeskCal
```

## 后续步骤

完成环境配置后，可继续进行以下开发阶段：

1. **阶段 1**: 基础日历图片生成（单月日历）
2. **阶段 2**: 全年日历和布局优化
3. **阶段 3**: 定时更新和系统集成
4. **阶段 4**: 界面美化和视觉优化
5. **阶段 5**: 用户控制和发布准备

## 参考资料
- [Swift Package Manager 文档](https://swift.org/package-manager/)
- [AppKit 框架参考](https://developer.apple.com/documentation/appkit)
- [Core Graphics 编程指南](https://developer.apple.com/documentation/coregraphics)

---

*文档版本：1.0*
*更新日期：2026-03-05*
*更新说明：创建阶段 0 环境配置文档*