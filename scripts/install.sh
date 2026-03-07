#!/bin/bash
# DeskCal 安装脚本
# 安装 DeskCal 到系统路径，并可选择安装为 launchd 服务

set -e  # 遇到错误退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 函数：打印彩色消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以 root 运行（对于安装到 /usr/local/bin 需要）
if [[ $EUID -eq 0 ]]; then
    print_warning "正在以 root 用户运行，请确保你知道自己在做什么。"
fi

# 检查 Swift 是否安装
print_info "检查 Swift 版本..."
if ! command -v swift &> /dev/null; then
    print_error "未找到 Swift，请先安装 Xcode 命令行工具："
    print_error "  xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(swift --version | head -n1)
print_info "找到 Swift: $SWIFT_VERSION"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 检查项目文件
if [[ ! -f "Package.swift" ]]; then
    print_error "未找到 Package.swift，请确保在 DeskCal 项目根目录中运行。"
    exit 1
fi

# 构建项目
print_info "构建 DeskCal (发布模式)..."
if ! swift build -c release; then
    print_error "构建失败，请检查错误信息。"
    exit 1
fi

# 获取构建的可执行文件路径
EXECUTABLE_PATH=".build/release/DeskCal"
if [[ ! -f "$EXECUTABLE_PATH" ]]; then
    print_error "未找到可执行文件: $EXECUTABLE_PATH"
    exit 1
fi

print_info "构建成功: $EXECUTABLE_PATH"

# 询问是否安装到系统路径
read -p "安装 DeskCal 到 /usr/local/bin? (y/n, 默认: y): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_info "跳过系统路径安装。你可以直接运行: $EXECUTABLE_PATH"
else
    # 安装到 /usr/local/bin
    print_info "复制 DeskCal 到 /usr/local/bin..."
    if ! sudo cp "$EXECUTABLE_PATH" /usr/local/bin/DeskCal; then
        print_error "复制失败，你可能需要 root 权限。"
        print_error "可以手动运行: sudo cp $EXECUTABLE_PATH /usr/local/bin/DeskCal"
        exit 1
    fi

    # 设置权限
    sudo chmod 755 /usr/local/bin/DeskCal
    print_info "安装成功！现在可以在终端中运行 'DeskCal' 命令。"
fi

# 询问是否安装 launchd 服务
echo
read -p "安装 launchd 服务以实现自动更新? (y/n, 默认: y): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    print_info "跳过服务安装。你可以稍后运行 'DeskCal --install-service' 来安装。"
else
    # 检查是否已经安装了 DeskCal 命令
    if ! command -v DeskCal &> /dev/null; then
        print_error "未找到 DeskCal 命令，请先安装到系统路径或使用完整路径运行。"
        print_error "示例: $EXECUTABLE_PATH --install-service"
        exit 1
    fi

    print_info "安装 launchd 服务..."
    if DeskCal --install-service; then
        print_info "服务安装成功！DeskCal 将在后台自动运行并每天更新墙纸。"
        print_info "运行 'DeskCal --status' 检查状态。"
    else
        print_error "服务安装失败，请检查错误信息。"
        print_warning "可以尝试手动安装:"
        print_warning "  cp Resources/com.deskcal.plist ~/Library/LaunchAgents/"
        print_warning "  launchctl load ~/Library/LaunchAgents/com.deskcal.plist"
    fi
fi

# 询问是否立即运行测试
echo
read -p "立即运行测试以验证安装? (y/n, 默认: n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "运行测试..."
    if command -v DeskCal &> /dev/null; then
        DeskCal --test
        print_info "测试完成！请检查桌面是否生成了测试图片。"
    else
        "$EXECUTABLE_PATH" --test
        print_info "测试完成！请检查桌面是否生成了测试图片。"
    fi
fi

print_info ""
print_info "==============================================="
print_info "DeskCal 安装完成！"
print_info "==============================================="
print_info ""
print_info "使用说明:"
print_info "  DeskCal --help          # 查看帮助"
print_info "  DeskCal --year          # 生成全年日历"
print_info "  DeskCal --month         # 生成单月日历"
print_info "  DeskCal --update        # 立即更新墙纸"
print_info "  DeskCal --status        # 查看状态"
print_info ""
print_info "配置文件位置: ~/Library/Application Support/DeskCal/config.json"
print_info "日志文件位置: /tmp/com.deskcal.log"
print_info ""
print_info "如需卸载，请运行: sudo $SCRIPT_DIR/uninstall.sh"
print_info "==============================================="