# DeskCal 故障排除指南

本文档提供 DeskCal 常见问题的解决方案和调试方法。

## 快速诊断

首先运行以下命令获取系统状态：

```bash
DeskCal --status
```

输出示例：
```
DeskCal Status Report
====================
Version: 1.0.0
Config file: ~/Library/Application Support/DeskCal/config.json (Exists: Yes, Valid: Yes)
Wallpaper permission: Granted
Last update: 2026-03-07 14:30:25
Next scheduled update: 2026-03-08 00:00:00
Service status: Running (com.deskcal)
Log file: /tmp/com.deskcal.log (Size: 45.2 KB)
```

## 常见问题

### 1. 墙纸未更新

#### 症状
- 桌面墙纸没有变化
- 日历图片没有更新到新日期
- 手动运行 `DeskCal --update` 无效

#### 诊断步骤

1. **检查权限**
   ```bash
   DeskCal --status | grep "Wallpaper permission"
   ```
   应显示 `Granted`。如果显示 `Unknown` 或 `Denied`，可能需要权限。

2. **查看日志**
   ```bash
   tail -n 20 /tmp/com.deskcal.log
   ```
   查找错误信息。

3. **手动测试图片生成**
   ```bash
   DeskCal --test
   ```
   检查桌面是否生成 `DeskCal-test-*.png` 文件。

4. **检查图片文件**
   ```bash
   ls -la /tmp/deskcal-*.png 2>/dev/null || echo "No temp files found"
   ```

#### 解决方案

**方案 A：权限问题**
- 确保在「系统设置」>「隐私与安全性」>「自动化」中允许 DeskCal 控制「系统事件」
- 重启应用后重试

**方案 B：临时文件问题**
- 清理临时文件：
  ```bash
  rm -f /tmp/deskcal-*.png
  rm -f /tmp/com.deskcal.log
  ```
- 重新运行

**方案 C：图片生成失败**
- 检查磁盘空间：
  ```bash
  df -h /tmp
  ```
- 确保有足够的可用空间（至少 100MB）

### 2. 服务未运行

#### 症状
- 日历不自动更新
- `DeskCal --service-status` 显示服务未运行
- 重启后日历不自动启动

#### 诊断步骤

1. **检查服务状态**
   ```bash
   DeskCal --service-status
   ```

2. **查看 launchd 状态**
   ```bash
   launchctl list | grep deskcal
   ```

3. **检查 plist 文件**
   ```bash
   ls -la ~/Library/LaunchAgents/com.deskcal.plist
   cat ~/Library/LaunchAgents/com.deskcal.plist
   ```

#### 解决方案

**方案 A：重新安装服务**
```bash
DeskCal --uninstall-service
DeskCal --install-service
```

**方案 B：手动启动服务**
```bash
launchctl load ~/Library/LaunchAgents/com.deskcal.plist
launchctl start com.deskcal
```

**方案 C：检查 plist 文件路径**
确保 `com.deskcal.plist` 中的可执行文件路径正确：
```xml
<string>/usr/local/bin/DeskCal</string>
```
如果 DeskCal 安装在其他位置，需要修改 plist 文件。

### 3. 配置文件错误

#### 症状
- 配置选项不生效
- DeskCal 启动时报 JSON 解析错误
- 自定义颜色不显示

#### 诊断步骤

1. **验证 JSON 格式**
   ```bash
   python -m json.tool ~/Library/Application\ Support/DeskCal/config.json
   ```

2. **检查配置状态**
   ```bash
   DeskCal --status | grep -A5 "Config file"
   ```

3. **查看配置加载日志**
   ```bash
   grep -i config /tmp/com.deskcal.log
   ```

#### 解决方案

**方案 A：修复 JSON 格式**
```bash
# 备份当前配置
cp ~/Library/Application\ Support/DeskCal/config.json ~/Desktop/config-backup.json

# 使用 Python 验证和格式化
python -m json.tool ~/Library/Application\ Support/DeskCal/config.json > /tmp/config-fixed.json
mv /tmp/config-fixed.json ~/Library/Application\ Support/DeskCal/config.json
```

**方案 B：恢复默认配置**
```bash
rm ~/Library/Application\ Support/DeskCal/config.json
DeskCal --check
```

**方案 C：逐步测试配置**
1. 从简单配置开始：
   ```json
   {"theme": "light"}
   ```
2. 逐步添加选项，每次测试

### 4. 性能问题

#### 症状
- 图片生成慢（> 5秒）
- 高 CPU 使用率
- 内存占用过高

#### 诊断步骤

1. **测量生成时间**
   ```bash
   time DeskCal --test
   ```

2. **检查系统资源**
   ```bash
   # 运行 DeskCal 时监控资源
   top -pid $(pgrep DeskCal)
   ```

3. **查看性能日志**
   ```bash
   grep -i "time\|performance\|memory" /tmp/com.deskcal.log
   ```

#### 解决方案

**方案 A：调整图片质量**
在配置文件中降低背景透明度：
```json
{
  "background_alpha": 0.7
}
```

**方案 B：减少显示元素**
```json
{
  "show_month_separators": false,
  "show_year_title": false
}
```

**方案 C：使用单月模式**
```json
{
  "calendar_mode": "month"
}
```
或通过命令行：
```bash
DeskCal --month
```

### 5. 显示问题

#### 症状
- 日历文字模糊
- 颜色不正确
- 布局错乱

#### 诊断步骤

1. **检查屏幕分辨率**
   ```bash
   system_profiler SPDisplaysDataType | grep Resolution
   ```

2. **测试不同主题**
   ```bash
   DeskCal --test
   # 检查生成的图片
   open ~/Desktop/DeskCal-test-*.png
   ```

3. **验证颜色配置**
   ```bash
   DeskCal --status | grep -i color
   ```

#### 解决方案

**方案 A：Retina 显示优化**
确保使用高分辨率图片生成。如果问题持续，尝试：

1. 调整字体大小（如果支持）
2. 使用系统默认字体

**方案 B：颜色校正**
1. 检查颜色值格式（必须为 `#RRGGBB` 或 `#RRGGBBAA`）
2. 确保颜色值有效
3. 测试不同的主题

**方案 C：布局问题**
1. 检查屏幕方向
2. 确保外部显示器正确识别
3. 尝试不同的日历模式

### 6. 日志和调试

#### 启用详细日志
```bash
# 设置环境变量
export DEBUG=1

# 运行 DeskCal
DeskCal --update
```

#### 查看实时日志
```bash
# 跟踪日志文件
tail -f /tmp/com.deskcal.log

# 同时查看错误日志
tail -f /tmp/com.deskcal.log /tmp/com.deskcal.error.log
```

#### 日志文件位置
- 主日志：`/tmp/com.deskcal.log`
- 错误日志：`/tmp/com.deskcal.error.log`
- 临时图片：`/tmp/deskcal-*.png`

### 7. 卸载和清理

#### 完全卸载
```bash
# 使用卸载脚本
./uninstall.sh

# 或手动卸载
DeskCal --uninstall-service
sudo rm -f /usr/local/bin/DeskCal
rm -rf ~/Library/Application\ Support/DeskCal
rm -f /tmp/com.deskcal.*
rm -f ~/Desktop/DeskCal-test-*.png
```

#### 清理残留文件
```bash
# 检查可能残留的文件
ls -la ~/Library/LaunchAgents/ | grep deskcal
ls -la /usr/local/bin/ | grep DeskCal
ls -la ~/Library/Application\ Support/ | grep DeskCal
```

### 8. 系统兼容性问题

#### macOS 版本问题
DeskCal 需要 macOS 11.0 或更高版本。检查系统版本：
```bash
sw_vers
```

#### 架构兼容性
DeskCal 支持 Apple Silicon (arm64) 和 Intel (x86_64)。检查架构：
```bash
uname -m
```

#### Swift 运行时问题
确保 Swift 运行时正确安装：
```bash
# 检查 Swift 版本
swift --version

# 重新安装 Xcode 命令行工具
xcode-select --install
```

## 高级调试

### 使用 Instruments 分析
```bash
# 启动性能分析
xcrun xctrace record --template 'Allocations' --output DeskCal.trace --launch -- /usr/local/bin/DeskCal --test
```

### 核心转储分析
如果应用崩溃：
```bash
# 查找崩溃日志
ls -la ~/Library/Logs/DiagnosticReports/ | grep DeskCal

# 查看崩溃报告
cat ~/Library/Logs/DiagnosticReports/DeskCal_*.crash
```

### 网络调试（如果将来有网络功能）
```bash
# 监控网络请求
sudo tcpdump -i any port 443 -w deskcal-network.pcap
```

## 获取帮助

如果以上方法都无法解决问题：

1. **收集诊断信息**
   ```bash
   DeskCal --status > ~/Desktop/deskcal-status.txt
   tail -n 100 /tmp/com.deskcal.log > ~/Desktop/deskcal-log.txt
   ```

2. **检查系统信息**
   ```bash
   system_profiler SPSoftwareDataType SPHardwareDataType > ~/Desktop/system-info.txt
   ```

3. **提交问题**
   - 包含诊断信息
   - 描述问题现象
   - 提供复现步骤
   - 附上相关日志

## 预防措施

1. **定期备份配置**
   ```bash
   cp ~/Library/Application\ Support/DeskCal/config.json ~/Desktop/deskcal-config-backup-$(date +%Y%m%d).json
   ```

2. **监控日志大小**
   ```bash
   # 定期清理旧日志
   find /tmp -name "com.deskcal.*" -mtime +7 -delete
   ```

3. **测试更新**
   - 在次要更新前测试新配置
   - 备份当前工作配置
   - 逐步应用更改

---

*文档版本：1.0*
*更新日期：2026-03-07*