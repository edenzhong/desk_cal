# 架构设计文档

## 系统概述
macOS 桌面日历应用采用模块化架构，通过生成日历图片并设置为系统墙纸实现桌面日历功能。应用作为后台服务运行，每天自动更新墙纸，确保日期准确。架构核心包括图片生成、墙纸管理和定时调度三大模块。

## 架构图
```
┌─────────────────────────────────────────────────────────────┐
│                      macOS 系统层                           │
├─────────────────────────────────────────────────────────────┤
│  NSWorkspace (墙纸设置)     NSScreen (显示器信息)           │
│  File System (图片存储)     Core Graphics (绘图)           │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                     调度层 (Scheduler)                      │
├─────────────────────────────────────────────────────────────┤
│  WallpaperScheduler ────────────┬───── Timer/DateMonitor    │
│  (定时触发)                     │     (时间监控)            │
│                                 │                           │
│                     ErrorHandler ────── Logger              │
│                     (错误处理)   (日志记录)                 │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                     核心业务层                              │
├─────────────────────────────────────────────────────────────┤
│  CalendarGenerator ──┬───── LayoutCalculator               │
│  (日历生成器)        │     (布局计算)                       │
│                      │                                      │
│               DateCalculator ─────── StyleManager          │
│               (日期计算)      (样式管理)                    │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                     系统集成层                              │
├─────────────────────────────────────────────────────────────┤
│  WallpaperManager ───┬───── ScreenDetector                 │
│  (墙纸管理器)        │     (屏幕检测)                       │
│                      │                                      │
│               FileManager ──────── UserPreferences         │
│               (文件管理)    (用户偏好)                      │
└─────────────────────────────────────────────────────────────┘
```

## 组件详述

### 1. WallpaperScheduler (调度器)
**职责**：
- 管理定时任务，每天触发墙纸更新
- 监控日期变化（跨天、跨月、跨年）
- 处理异常情况，确保任务可靠执行

**关键属性**：
- `updateTimer: Timer`：每日定时器
- `lastUpdateDate: Date`：最后更新日期
- `isUpdating: Bool`：更新状态标志

**主要方法**：
- `startScheduler()`：启动定时任务
- `stopScheduler()`：停止定时任务
- `checkDateChange() -> Bool`：检查日期是否变化
- `forceUpdate()`：手动触发更新

**定时策略**：
- 每天凌晨 00:05 执行更新（避开系统繁忙时段）
- 日期变化时立即更新（如用户调整系统时间）
- 提供手动更新接口

### 2. CalendarGenerator (日历生成器)
**职责**：
- 生成包含全年日历的高分辨率图片
- 管理绘图上下文和图形状态
- 协调布局计算和样式应用

**关键属性**：
- `graphicsContext: CGContext`：Core Graphics 绘图上下文
- `imageSize: CGSize`：生成的图片尺寸
- `scaleFactor: CGFloat`：Retina 缩放因子

**主要方法**：
- `generateCalendar(for screen: NSScreen) -> CGImage?`：为指定屏幕生成日历图片
- `drawMonthGrid(month: Int, year: Int, in rect: CGRect)`：绘制单个月份
- `highlightToday(in context: CGContext, date: Date, frame: CGRect)`：高亮今日日期

**图片生成流程**：
1. 创建位图上下文（考虑 Retina 缩放）
2. 绘制背景（透明或纯色）
3. 计算月份布局（行列排列）
4. 逐个绘制月份网格
5. 添加今日高亮效果
6. 导出为 CGImage

### 3. DateCalculator (日期计算器)
**职责**：
- 提供日期计算和日历数据
- 处理时区、本地化、闰年等复杂情况
- 生成月份和星期的结构化数据

**关键属性**：
- `calendar: Calendar`：系统日历实例（考虑用户本地化设置）
- `currentDate: Date`：当前日期
- `currentYear: Int`：当前年份

**主要方法**：
- `getYearCalendar(year: Int) -> YearCalendar`：获取指定年份的日历数据
- `getMonthGrid(month: Int, year: Int) -> MonthGrid`：获取月份网格数据
- `isToday(date: Date) -> Bool`：判断是否为今日

**数据结构**：
```swift
struct YearCalendar {
    let year: Int
    let months: [MonthData]
}

struct MonthData {
    let month: Int  // 1-12
    let year: Int
    let weeks: [[DayInfo]]
}

struct DayInfo {
    let day: Int?      // 日期（1-31）或 nil（空白）
    let date: Date?    // 完整日期
    let isToday: Bool  // 是否为今日
    let isWeekend: Bool // 是否为周末
}
```

### 4. LayoutCalculator (布局计算器)
**职责**：
- 根据屏幕尺寸计算最优日历布局
- 管理字体大小、间距、边距等视觉参数
- 提供响应式布局，适配不同分辨率

**关键属性**：
- `screenSize: CGSize`：屏幕尺寸
- `scaleFactor: CGFloat`：Retina 缩放因子
- `safeAreaInsets: EdgeInsets`：安全区域边距

**主要方法**：
- `calculateGridColumns() -> Int`：计算月份列数（3-4列）
- `calculateMonthSize() -> CGSize`：计算单个月份尺寸
- `calculateFontSize(for monthSize: CGSize) -> CGFloat`：计算推荐字体大小
- `calculateSpacing() -> (horizontal: CGFloat, vertical: CGFloat)`：计算间距

**布局策略**：
- 大屏幕（> 1920px）：4 列 × 3 行
- 中等屏幕（1440-1920px）：3 列 × 4 行
- 小屏幕（< 1440px）：2 列 × 6 行
- 根据实际屏幕尺寸微调，确保可读性

### 5. StyleManager (样式管理器)
**职责**：
- 管理日历的视觉样式（颜色、字体、效果）
- 提供与系统日历一致的默认样式
- 支持未来扩展（主题系统）

**关键属性**：
- `textColor: CGColor`：文字颜色
- `highlightColor: CGColor`：高亮颜色
- `weekendColor: CGColor`：周末颜色
- `font: CTFont`：字体

**样式元素**：
- **月份标题**：较大字体，粗体
- **星期标题**：较小字体，灰色
- **日期数字**：正常字体
- **今日高亮**：圆形背景，强调色
- **周末日期**：不同颜色（如红色）

**默认样式**：
- 参考 macOS 系统日历应用
- 使用系统字体（San Francisco）
- 颜色与系统 dark/light mode 协调

### 6. WallpaperManager (墙纸管理器)
**职责**：
- 将生成的图片设置为系统墙纸
- 管理多显示器配置
- 处理墙纸设置失败和恢复

**关键属性**：
- `workspace: NSWorkspace`：系统工作空间
- `screenOptions: [NSScreen: [NSWorkspace.DesktopImageOptionKey: Any]]`：各屏幕设置

**主要方法**：
- `setWallpaper(image: CGImage, for screen: NSScreen)`：为指定屏幕设置墙纸
- `getCurrentWallpaperOptions(for screen: NSScreen) -> [NSWorkspace.DesktopImageOptionKey: Any]`：获取当前墙纸设置
- `restoreUserWallpaper()`：恢复用户原始墙纸

**墙纸选项**：
- 保持用户现有设置（填充、适应、拉伸等）
- 支持透明背景（需用户墙纸为图片）
- 多显示器独立设置

### 7. ScreenDetector (屏幕检测器)
**职责**：
- 检测系统屏幕配置（数量、分辨率、DPI）
- 识别主显示器和扩展显示器
- 监听屏幕配置变化

**关键属性**：
- `screens: [NSScreen]`：所有屏幕列表
- `mainScreen: NSScreen?`：主显示器
- `screenObservers: [Any]`：屏幕变化监听器

**主要方法**：
- `detectScreens() -> [NSScreen]`：检测当前屏幕配置
- `getScreenInfo(_ screen: NSScreen) -> ScreenInfo`：获取屏幕详细信息
- `startMonitoring()`：开始监听屏幕变化

**屏幕信息**：
```swift
struct ScreenInfo {
    let id: String           // 屏幕唯一标识
    let frame: CGRect        // 屏幕位置和尺寸
    let resolution: CGSize   // 像素分辨率
    let scaleFactor: CGFloat // Retina 缩放因子
    let isMain: Bool         // 是否为主显示器
}
```

## 数据流
1. **启动和初始化流程**：
   ```
   应用启动
   → 初始化 WallpaperScheduler、CalendarGenerator、WallpaperManager
   → ScreenDetector 检测当前屏幕配置
   → 检查是否需要立即更新（如第一次运行或日期已变化）
   → 启动定时任务（每天 00:05 执行）
   → 应用转入后台运行
   ```

2. **每日更新流程**：
   ```
   定时器触发（00:05）或日期变化检测
   → WallpaperScheduler.checkDateChange() 确认日期变化
   → ScreenDetector 获取当前屏幕信息
   → 对每个需要更新的屏幕：
      1. DateCalculator 生成当前年份日历数据
      2. LayoutCalculator 根据屏幕尺寸计算布局
      3. CalendarGenerator 生成日历图片
      4. WallpaperManager 设置图片为墙纸
   → 记录更新时间和状态
   → 清理临时资源
   ```

3. **图片生成流程**：
   ```
   为单个屏幕生成日历图片
   → 创建位图上下文（考虑 Retina 缩放）
   → 绘制背景（透明或纯色）
   → LayoutCalculator 计算月份布局（行列、位置）
   → 对每个月份（1-12）：
      1. DateCalculator 获取月份网格数据
      2. 绘制月份标题
      3. 绘制星期标题行
      4. 绘制日期网格（6行×7列）
      5. 如果是今日，添加高亮效果
   → 导出为 CGImage
   → 保存到临时文件
   ```

4. **错误处理流程**：
   ```
   更新过程中发生错误
   → ErrorHandler 捕获异常
   → Logger 记录错误详情
   → 根据错误类型尝试恢复：
      - 文件权限问题：使用不同临时目录
      - 墙纸设置失败：重试或跳过
      - 图片生成失败：使用简化版本
   → 如果严重错误，通知用户（通过日志或通知）
   → 确保应用不崩溃，继续运行
   ```

5. **屏幕配置变化流程**：
   ```
   用户连接/断开显示器
   → ScreenDetector 收到系统通知
   → 检测到屏幕配置变化
   → 立即触发墙纸更新流程
   → 为新屏幕生成适配的日历图片
   → 保持原有屏幕的墙纸（如已设置）
   ```

## 关键设计决策

### 1. 动态墙纸 vs 桌面窗口
- **选择动态墙纸方案**：简化实现，降低资源占用，更好的系统集成
- **优势**：无需常驻窗口，无需事件监听，系统原生多显示器支持
- **权衡**：日历持续显示而非仅显示桌面时，但更符合"桌面日历"直觉

### 2. Core Graphics 图片生成
- **选择 Core Graphics 而非 SwiftUI ImageRenderer**：支持 macOS 11.0+，更精细的绘图控制
- **性能考虑**：直接操作位图上下文，避免 SwiftUI 渲染开销
- **Retina 支持**：使用 scale factor 生成高分辨率图片，确保清晰度

### 3. 模块化架构
- **关注点分离**：调度、生成、管理各司其职，便于测试和维护
- **可替换性**：每个模块有清晰接口，可独立替换实现（如不同布局算法）
- **错误隔离**：一个模块失败不影响其他模块，系统降级运行

### 4. 资源优化策略
- **按需生成**：仅在日期变化或屏幕配置变化时生成新图片
- **缓存策略**：缓存生成的图片，避免重复计算（相同日期、相同分辨率）
- **定时优化**：选择系统空闲时段（凌晨）执行更新，减少对用户的干扰
- **内存管理**：及时释放大尺寸图片内存，避免内存泄漏

### 5. 错误恢复设计
- **优雅降级**：图片生成失败时使用简化版本或跳过
- **状态持久化**：记录最后成功状态，避免重复失败
- **用户通知**：通过日志文件记录问题，不干扰用户正常使用
- **自动恢复**：下次定时任务时重试，逐步恢复功能

### 6. 兼容性设计
- **macOS 版本**：支持 11.0+，使用稳定的系统 API
- **显示器适配**：自动检测 Retina 显示器，生成合适分辨率的图片
- **多语言支持**：使用系统日历的本地化设置（月份、星期名称）
- **权限最小化**：不需要特殊权限，使用标准墙纸 API

## 扩展点
1. **主题系统**：可插拔的配色方案，支持 dark/light mode 自适应
2. **布局变体**：紧凑视图（仅当前月）、季度视图、半年视图等
3. **事件集成**：从日历应用读取事件并在墙纸上标记（需用户授权）
4. **多语言扩展**：支持更多语言的月份和星期名称
5. **配置界面**：图形化设置面板，调整颜色、字体、布局等
6. **云同步**：用户偏好设置在多设备间同步
7. **高级调度**：支持自定义更新频率、特定时间更新等

## 依赖关系
- **系统框架**：Foundation, AppKit, Core Graphics, Core Text
- **第三方库**：暂无必需第三方库
- **开发工具**：Xcode, Swift Package Manager (SPM)
- **部署要求**：macOS 11.0+，不需要特殊权限

---
*文档版本：2.0*
*最后更新：2026-03-04*
*更新说明：变更为动态墙纸方案，完全重新设计架构*