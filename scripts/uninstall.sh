#!/bin/bash
# DeskCal 卸载脚本
# 完全移除 DeskCal 及其相关文件

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

# 检查是否以 root 运行（对于删除 /usr/local/bin 中的文件需要）
if [[ $EUID -ne 0 ]]; then
    print_warning "此脚本需要 root 权限来删除系统文件。"
    print_warning "将尝试使用 sudo。"
fi

print_warning "==============================================="
print_warning "           DeskCal 卸载程序"
print_warning "==============================================="
print_warning "此脚本将完全移除 DeskCal 及其相关文件。"
print_warning "包括："
print_warning "  • launchd 服务"
print_warning "  • /usr/local/bin/DeskCal"
print_warning "  • 配置文件目录"
print_warning "  • 日志文件"
print_warning ""
print_warning "建议在卸载前备份配置文件（如果需要）。"
print_warning "==============================================="

# 确认卸载
read -p "确定要完全卸载 DeskCal? (y/n, 默认: n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "取消卸载。"
    exit 0
fi

# 第一步：停止并卸载 launchd 服务
print_info "步骤 1/4: 停止并卸载 launchd 服务..."

# 尝试使用 DeskCal 命令卸载服务
if command -v DeskCal &> /dev/null; then
    print_info "使用 DeskCal 命令卸载服务..."
    if DeskCal --uninstall-service; then
        print_info "服务卸载成功。"
    else
        print_warning "使用 DeskCal 命令卸载服务失败，尝试手动卸载..."
    fi
else
    print_warning "未找到 DeskCal 命令，尝试手动卸载服务..."
fi

# 手动停止和卸载服务
SERVICE_PLIST="$HOME/Library/LaunchAgents/com.deskcal.plist"
if [[ -f "$SERVICE_PLIST" ]]; then
    print_info "手动停止服务..."
    launchctl stop com.deskcal 2>/dev/null || true
    launchctl unload "$SERVICE_PLIST" 2>/dev/null || true

    print_info "删除服务文件..."
    rm -f "$SERVICE_PLIST"
    print_info "服务文件已删除: $SERVICE_PLIST"
else
    print_info "未找到服务文件: $SERVICE_PLIST"
fi

# 第二步：删除可执行文件
print_info "步骤 2/4: 删除可执行文件..."

if [[ -f "/usr/local/bin/DeskCal" ]]; then
    print_info "删除 /usr/local/bin/DeskCal..."
    sudo rm -f /usr/local/bin/DeskCal
    print_info "可执行文件已删除。"
else
    print_info "未找到 /usr/local/bin/DeskCal"
fi

# 第三步：删除配置文件目录
print_info "步骤 3/4: 删除配置文件目录..."

CONFIG_DIR="$HOME/Library/Application Support/DeskCal"
if [[ -d "$CONFIG_DIR" ]]; then
    print_info "删除配置文件目录: $CONFIG_DIR"
    rm -rf "$CONFIG_DIR"
    print_info "配置文件目录已删除。"
else
    print_info "未找到配置文件目录: $CONFIG_DIR"
fi

# 第四步：删除日志文件
print_info "步骤 4/4: 清理日志文件..."

LOG_FILES=(
    "/tmp/com.deskcal.log"
    "/tmp/com.deskcal.error.log"
    "$HOME/Desktop/DeskCal-test-*.png"
)

for log_file in "${LOG_FILES[@]}"; do
    # 使用通配符扩展
    for file in $log_file; do
        if [[ -e "$file" ]]; then
            print_info "删除文件: $file"
            rm -f "$file"
        fi
    done
done

print_info "日志文件已清理。"

# 完成
print_info ""
print_info "==============================================="
print_info "DeskCal 卸载完成！"
print_info "==============================================="
print_info ""
print_info "以下项目已被移除："
print_info "  ✓ launchd 服务"
print_info "  ✓ 可执行文件 (/usr/local/bin/DeskCal)"
print_info "  ✓ 配置文件目录"
print_info "  ✓ 日志文件"
print_info ""
print_info "注意："
print_info "  • 如果通过其他方式安装了 DeskCal（如手动复制），可能需要额外清理。"
print_info "  • 桌面上的测试图片（DeskCal-test-*.png）已被删除。"
print_info ""
print_info "感谢使用 DeskCal！"
print_info "==============================================="