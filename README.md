# DeskCal - macOS Desktop Calendar

DeskCal 是一个 macOS 桌面日历应用，自动在桌面墙纸上显示日历，支持全年和单月视图。

## 功能特性

- 自动生成美观的日历图片并设置为桌面墙纸
- 支持全年视图（12个月）和单月视图
- 自动每日更新，确保日期准确
- 响应式布局，适配不同屏幕尺寸
- 浅色/深色/透明主题，自动跟随系统外观
- 可自定义颜色、字体和高亮样式
- 通过 launchd 服务实现后台自动运行
- 完整的命令行控制接口

## 安装

### 从源码构建

```bash
git clone <repository-url>
cd desk_cal
swift build -c release
sudo cp .build/release/DeskCal /usr/local/bin/
```

### 安装 launchd 服务（可选，用于自动更新）

```bash
DeskCal --install-service
```

服务安装后，每天午夜自动更新墙纸。如需立即更新，可运行：

```bash
DeskCal --update
```

## 使用方法

### 命令行选项

```
DeskCal [options]

选项：
  -m, --month     生成单月日历（默认：全年）
  -y, --year      生成全年日历（12个月）
  -t, --test      测试模式：保存图片到桌面而不设置墙纸
  -d, --daemon    执行启动检查并在需要时更新（供 launchd 使用）
  -u, --update    强制立即更新墙纸
  -c, --check     检查更新状态而不更新
  --status        显示详细状态信息
  --install-service 安装 launchd 服务（复制 plist 到 LaunchAgents 并加载）
  --uninstall-service 卸载 launchd 服务（卸载并删除 plist）
  --start-service 启动 launchd 服务
  --stop-service  停止 launchd 服务
  --service-status 检查 launchd 服务状态
  --config PATH   使用自定义配置文件
  -h, --help      显示此帮助信息

示例：
  DeskCal --year                # 检查并在需要时更新（默认）
  DeskCal --month               # 检查并更新单月日历
  DeskCal --year --test         # 生成全年日历并保存到桌面
  DeskCal --update --month      # 强制更新单月日历
  DeskCal --check               # 检查更新状态
  DeskCal --status              # 显示详细状态
  DeskCal --config ~/my-config.json --update  # 使用自定义配置更新
```

## 配置文件

DeskCal 支持通过 JSON 配置文件自定义外观和行为。默认配置文件位于：
`~/Library/Application Support/DeskCal/config.json`

首次运行时会自动创建默认配置文件。

### 配置文件示例

```json
{
  "theme": "auto",
  "calendar_mode": "year",
  "show_weekend_colors": true,
  "show_month_separators": true,
  "show_year_title": true,
  "background_alpha": 0.85,
  "today_highlight_style": {
    "type": "circle"
  },
  "custom_colors": {
    "today_highlight_color": "#007AFF",
    "weekend_text_color": "#FF3B30"
  }
}
```

### 配置选项说明

#### 主题 (theme)
- `light`: 浅色主题
- `dark`: 深色主题
- `auto`: 自动跟随系统外观（默认）
- `transparent`: 透明背景，与用户墙纸更好融合

#### 日历模式 (calendar_mode)
- `month`: 单月视图
- `year`: 全年视图（默认）

#### 显示选项
- `show_weekend_colors`: 是否用特殊颜色显示周末（默认 `true`）
- `show_month_separators`: 是否显示月份分隔线（默认 `true`）
- `show_year_title`: 是否显示年份标题（默认 `true`）
- `background_alpha`: 背景透明度（0.0-1.0，默认 `0.85`）

#### 今天高亮样式 (today_highlight_style)
- `circle`: 圆形高亮（默认）
- `roundedRect`: 圆角矩形高亮，需指定 `cornerRadius`
- `underline`: 下划线高亮，需指定 `thickness`

示例：
```json
{
  "type": "roundedRect",
  "cornerRadius": 8.0
}
```

#### 自定义颜色 (custom_colors)
支持自定义以下颜色（十六进制格式，如 `#RRGGBB` 或 `#RRGGBBAA`）：
- `backgroundColor`: 背景颜色
- `monthTitleColor`: 月份标题颜色
- `weekdayTitleColor`: 星期标题颜色
- `dayTextColor`: 日期文本颜色
- `weekendTextColor`: 周末文本颜色
- `todayHighlightColor`: 今天高亮背景颜色
- `todayTextColor`: 今天日期文本颜色
- `monthSeparatorColor`: 月份分隔线颜色
- `yearTitleColor`: 年份标题颜色

### 优先级说明
1. 命令行参数（如 `--month`）优先于配置文件中的设置
2. 自定义颜色优先于主题默认颜色
3. 如果 `show_weekend_colors` 为 `false`，周末颜色将与普通日期相同

## 故障排除

### 墙纸未更新
1. 检查是否有墙纸设置权限：
   ```bash
   DeskCal --status
   ```
   查看 "Wallpaper permission" 是否为 "Granted"

2. 检查日志：
   ```bash
   cat /tmp/com.deskcal.log
   ```

3. 手动测试图片生成：
   ```bash
   DeskCal --test
   ```
   图片将保存到桌面，检查是否正常生成

### 服务未运行
1. 检查服务状态：
   ```bash
   DeskCal --service-status
   ```

2. 重新安装服务：
   ```bash
   DeskCal --uninstall-service
   DeskCal --install-service
   ```

### 配置文件错误
1. 验证 JSON 格式：
   ```bash
   python -m json.tool ~/Library/Application\ Support/DeskCal/config.json
   ```

2. 恢复默认配置：
   ```bash
   rm ~/Library/Application\ Support/DeskCal/config.json
   DeskCal --check
   ```

## 卸载

1. 停止并卸载服务：
   ```bash
   DeskCal --uninstall-service
   ```

2. 删除可执行文件：
   ```bash
   sudo rm /usr/local/bin/DeskCal
   ```

3. 删除配置文件（可选）：
   ```bash
   rm -rf ~/Library/Application\ Support/DeskCal
   ```

## 开发

### 项目结构
```
Sources/DeskCal/
├── DeskCal.swift          # 主入口，命令行解析
├── CalendarGenerator.swift # 日历图片生成
├── DateCalculator.swift   # 日期计算
├── LayoutCalculator.swift # 布局计算
├── WallpaperManager.swift # 墙纸设置
├── UpdateScheduler.swift  # 更新调度
├── Logger.swift          # 日志系统
└── ConfigurationManager.swift # 配置管理
```

### 构建和测试
```bash
# 调试构建
swift build

# 发布构建
swift build -c release

# 运行测试
swift run DeskCal --test
swift run DeskCal --update --month
```

## 许可证

[MIT License](LICENSE)

## 贡献

欢迎提交 Issue 和 Pull Request。