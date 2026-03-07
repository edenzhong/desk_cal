#!/bin/bash
# DeskCal 打包脚本
# 创建可分发的 DeskCal 包

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

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# 检查项目文件
if [[ ! -f "Package.swift" ]]; then
    print_error "未找到 Package.swift，请确保在 DeskCal 项目根目录中运行。"
    exit 1
fi

# 检查 Swift 是否安装
print_info "检查 Swift 版本..."
if ! command -v swift &> /dev/null; then
    print_error "未找到 Swift，请先安装 Xcode 命令行工具："
    print_error "  xcode-select --install"
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

# 创建分发目录
DIST_DIR="dist"
PACKAGE_NAME="DeskCal-$(date +%Y%m%d)"
PACKAGE_DIR="$DIST_DIR/$PACKAGE_NAME"

print_info "创建分发包目录: $PACKAGE_DIR"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# 复制文件到包目录
print_info "复制文件到包目录..."

# 1. 可执行文件
cp "$EXECUTABLE_PATH" "$PACKAGE_DIR/DeskCal"

# 2. 配置文件模板
cp "config.example.json" "$PACKAGE_DIR/config.example.json"

# 3. launchd plist 文件
cp "Resources/com.deskcal.plist" "$PACKAGE_DIR/"

# 4. 安装和卸载脚本
cp "scripts/install.sh" "$PACKAGE_DIR/"
cp "scripts/uninstall.sh" "$PACKAGE_DIR/"

# 5. README 和许可证
cp "README.md" "$PACKAGE_DIR/"
if [[ -f "LICENSE" ]]; then
    cp "LICENSE" "$PACKAGE_DIR/"
fi

# 6. 其他文档
mkdir -p "$PACKAGE_DIR/docs"
if [[ -d "doc" ]]; then
    cp -r doc/* "$PACKAGE_DIR/docs/" 2>/dev/null || true
fi

# 设置文件权限
chmod 755 "$PACKAGE_DIR/DeskCal"
chmod 755 "$PACKAGE_DIR/install.sh"
chmod 755 "$PACKAGE_DIR/uninstall.sh"

# 创建版本文件
echo "DeskCal $(date +%Y%m%d)" > "$PACKAGE_DIR/VERSION"
echo "Build date: $(date)" >> "$PACKAGE_DIR/VERSION"
echo "Build with: $(swift --version | head -n1)" >> "$PACKAGE_DIR/VERSION"

# 创建包结构说明
cat > "$PACKAGE_DIR/STRUCTURE.md" << 'EOF'
# DeskCal 包结构

```
DeskCal-YYYYMMDD/
├── DeskCal                    # 主可执行文件
├── config.example.json        # 配置文件示例
├── com.deskcal.plist          # launchd 服务配置文件
├── install.sh                 # 安装脚本
├── uninstall.sh               # 卸载脚本
├── README.md                  # 使用说明
├── LICENSE                    # 许可证文件（如果存在）
├── VERSION                    # 版本信息
├── docs/                      # 文档目录
└── STRUCTURE.md               # 本文件
```

## 安装说明

### 快速安装
```bash
cd DeskCal-YYYYMMDD
./install.sh
```

### 手动安装
1. 复制 `DeskCal` 到 `/usr/local/bin/`:
   ```bash
   sudo cp DeskCal /usr/local/bin/
   sudo chmod 755 /usr/local/bin/DeskCal
   ```

2. （可选）安装 launchd 服务:
   ```bash
   DeskCal --install-service
   ```

3. （可选）复制配置文件示例:
   ```bash
   mkdir -p ~/Library/Application\ Support/DeskCal
   cp config.example.json ~/Library/Application\ Support/DeskCal/config.json
   ```

## 卸载说明
```bash
./uninstall.sh
```
EOF

# 创建压缩包
print_info "创建压缩包..."
cd "$DIST_DIR"
tar -czf "$PACKAGE_NAME.tar.gz" "$PACKAGE_NAME"
cd ..

# 计算文件大小
PACKAGE_SIZE=$(du -h "$DIST_DIR/$PACKAGE_NAME.tar.gz" | cut -f1)

print_info ""
print_info "==============================================="
print_info "打包完成！"
print_info "==============================================="
print_info ""
print_info "包文件: $DIST_DIR/$PACKAGE_NAME.tar.gz"
print_info "文件大小: $PACKAGE_SIZE"
print_info ""
print_info "包内容:"
ls -la "$PACKAGE_DIR/"
print_info ""
print_info "安装测试:"
print_info "  tar -xzf $DIST_DIR/$PACKAGE_NAME.tar.gz"
print_info "  cd $PACKAGE_NAME"
print_info "  ./install.sh"
print_info ""
print_info "分发说明:"
print_info "  1. 将 $PACKAGE_NAME.tar.gz 分发给用户"
print_info "  2. 用户解压后运行 ./install.sh 即可安装"
print_info "  3. 包含完整的安装、卸载脚本和文档"
print_info "==============================================="