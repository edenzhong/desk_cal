# DeskCal 配置指南

本文档详细说明 DeskCal 的配置选项和自定义方法。

## 配置文件位置

默认配置文件位于：
```
~/Library/Application Support/DeskCal/config.json
```

首次运行 DeskCal 时会自动创建默认配置文件。如果配置文件不存在或格式错误，将使用内置默认值。

## 配置文件结构

配置文件使用 JSON 格式。基本结构如下：

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

## 配置选项详解

### 主题 (theme)

控制日历的整体外观风格。

| 值 | 说明 | 示例 |
|----|------|------|
| `light` | 浅色主题，白色背景 | ![](https://via.placeholder.com/100x50/FFFFFF/000000?text=Light) |
| `dark` | 深色主题，黑色背景 | ![](https://via.placeholder.com/100x50/000000/FFFFFF?text=Dark) |
| `auto` | 自动跟随系统外观（默认） | 系统浅色/深色模式自动切换 |
| `transparent` | 透明背景，与用户墙纸融合 | 背景透明，只显示文字 |

**示例：**
```json
{
  "theme": "dark"
}
```

### 日历模式 (calendar_mode)

控制日历显示的范围。

| 值 | 说明 |
|----|------|
| `month` | 单月视图，只显示当前月份 |
| `year` | 全年视图，显示12个月份（默认） |

**示例：**
```json
{
  "calendar_mode": "month"
}
```

### 显示选项

控制日历的显示细节。

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `show_weekend_colors` | boolean | `true` | 是否用特殊颜色显示周末 |
| `show_month_separators` | boolean | `true` | 是否显示月份分隔线 |
| `show_year_title` | boolean | `true` | 是否显示年份标题 |
| `background_alpha` | number | `0.85` | 背景透明度（0.0-1.0），1.0为完全不透明 |

**示例：**
```json
{
  "show_weekend_colors": false,
  "show_month_separators": true,
  "show_year_title": true,
  "background_alpha": 0.9
}
```

### 今天高亮样式 (today_highlight_style)

自定义今天日期的突出显示样式。

#### 圆形高亮 (circle)
默认样式，在日期周围绘制圆形背景。

```json
{
  "today_highlight_style": {
    "type": "circle"
  }
}
```

#### 圆角矩形高亮 (roundedRect)
在日期周围绘制圆角矩形背景。

```json
{
  "today_highlight_style": {
    "type": "roundedRect",
    "cornerRadius": 8.0  // 圆角半径（可选，默认 6.0）
  }
}
```

#### 下划线高亮 (underline)
在日期下方绘制下划线。

```json
{
  "today_highlight_style": {
    "type": "underline",
    "thickness": 2.0,    // 下划线粗细（可选，默认 2.0）
    "offset": 2.0        // 与文字的间距（可选，默认 2.0）
  }
}
```

#### 无高亮 (none)
不显示特殊高亮。

```json
{
  "today_highlight_style": {
    "type": "none"
  }
}
```

### 自定义颜色 (custom_colors)

覆盖主题默认颜色，支持十六进制颜色格式（`#RRGGBB` 或 `#RRGGBBAA`）。

可自定义的颜色：

| 颜色键 | 说明 | 默认值（浅色主题） | 默认值（深色主题） |
|--------|------|-------------------|-------------------|
| `backgroundColor` | 背景颜色 | `#FFFFFF` | `#000000` |
| `monthTitleColor` | 月份标题颜色 | `#000000` | `#FFFFFF` |
| `weekdayTitleColor` | 星期标题颜色 | `#000000` | `#FFFFFF` |
| `dayTextColor` | 日期文本颜色 | `#000000` | `#FFFFFF` |
| `weekendTextColor` | 周末文本颜色 | `#FF3B30` | `#FF453A` |
| `todayHighlightColor` | 今天高亮背景颜色 | `#007AFF` | `#0A84FF` |
| `todayTextColor` | 今天日期文本颜色 | `#FFFFFF` | `#FFFFFF` |
| `monthSeparatorColor` | 月份分隔线颜色 | `#C7C7CC` | `#545458` |
| `yearTitleColor` | 年份标题颜色 | `#000000` | `#FFFFFF` |

**示例：自定义蓝色主题**
```json
{
  "custom_colors": {
    "backgroundColor": "#F0F8FF",
    "monthTitleColor": "#1E3A8A",
    "weekdayTitleColor": "#1E40AF",
    "dayTextColor": "#1E3A8A",
    "weekendTextColor": "#DC2626",
    "todayHighlightColor": "#2563EB",
    "todayTextColor": "#FFFFFF",
    "monthSeparatorColor": "#93C5FD",
    "yearTitleColor": "#1E3A8A"
  }
}
```

## 配置示例

### 示例 1：简约单月日历
```json
{
  "theme": "light",
  "calendar_mode": "month",
  "show_weekend_colors": false,
  "show_month_separators": false,
  "show_year_title": false,
  "background_alpha": 0.7,
  "today_highlight_style": {
    "type": "underline",
    "thickness": 1.5
  }
}
```

### 示例 2：深色全年日历
```json
{
  "theme": "dark",
  "calendar_mode": "year",
  "show_weekend_colors": true,
  "show_month_separators": true,
  "show_year_title": true,
  "background_alpha": 0.9,
  "today_highlight_style": {
    "type": "circle"
  },
  "custom_colors": {
    "todayHighlightColor": "#FF9F0A",
    "weekendTextColor": "#FF453A"
  }
}
```

### 示例 3：透明背景日历
```json
{
  "theme": "transparent",
  "calendar_mode": "year",
  "show_weekend_colors": true,
  "show_month_separators": false,
  "show_year_title": true,
  "background_alpha": 0.3,
  "today_highlight_style": {
    "type": "roundedRect",
    "cornerRadius": 4.0
  },
  "custom_colors": {
    "monthTitleColor": "#FFFFFF",
    "weekdayTitleColor": "#FFFFFF",
    "dayTextColor": "#FFFFFF",
    "weekendTextColor": "#FFD60A",
    "todayHighlightColor": "#32D74B40",
    "todayTextColor": "#FFFFFF",
    "yearTitleColor": "#FFFFFF"
  }
}
```

## 配置优先级

DeskCal 按以下优先级应用配置：

1. **命令行参数** - 最高优先级
   ```bash
   DeskCal --month  # 覆盖配置文件中的 calendar_mode
   ```

2. **自定义颜色** - 覆盖主题默认颜色
   ```json
   "custom_colors": {
     "todayHighlightColor": "#FF0000"
   }
   ```

3. **主题默认颜色** - 如果未指定自定义颜色
4. **内置默认值** - 如果配置文件不存在或选项缺失

## 配置验证和调试

### 验证 JSON 格式
```bash
python -m json.tool ~/Library/Application\ Support/DeskCal/config.json
```

### 检查当前配置
```bash
DeskCal --status
```

### 恢复默认配置
```bash
rm ~/Library/Application\ Support/DeskCal/config.json
DeskCal --check
```

### 配置文件位置
```bash
# 查看配置文件路径
DeskCal --status | grep "Config file"
```

## 常见配置问题

### 1. 颜色不生效
- 确保 JSON 格式正确
- 检查颜色值格式（`#RRGGBB` 或 `#RRGGBBAA`）
- 验证颜色键名是否正确

### 2. 透明度无效
- `background_alpha` 范围应为 0.0-1.0
- 对于透明主题，建议使用较低的值（0.2-0.5）

### 3. 高亮样式不生效
- 检查 `today_highlight_style.type` 值
- 确保类型拼写正确（`circle`, `roundedRect`, `underline`, `none`）
- 对于 `roundedRect` 和 `underline`，确保提供了必要的参数

## 最佳实践

1. **备份配置文件**：在修改前备份当前配置
2. **逐步修改**：一次只修改一个选项，测试效果
3. **使用注释**：JSON 不支持注释，但可以添加 `_comment` 字段：
   ```json
   {
     "_comment": "深色主题配置",
     "theme": "dark"
   }
   ```
4. **测试不同主题**：在不同系统外观（浅色/深色）下测试配置

---

*文档版本：1.0*
*更新日期：2026-03-07*