// VisualStyle.swift
// DeskCal - macOS Desktop Calendar
// 视觉样式配置

import AppKit

/// 视觉样式配置
struct VisualStyle {
    /// 主题类型
    enum Theme {
        case light
        case dark
        case auto // 根据系统设置自动选择
    }

    /// 主题
    var theme: Theme

    /// 背景颜色（如果使用透明背景，alpha可能为0）
    var backgroundColor: NSColor

    /// 背景透明度 (0.0 - 1.0)
    var backgroundAlpha: CGFloat

    /// 月份标题颜色
    var monthTitleColor: NSColor

    /// 星期标题颜色
    var weekdayTitleColor: NSColor

    /// 日期文本颜色
    var dayTextColor: NSColor

    /// 周末日期颜色
    var weekendTextColor: NSColor

    /// 今天高亮背景颜色
    var todayHighlightColor: NSColor

    /// 今天高亮文本颜色（在高亮背景上）
    var todayTextColor: NSColor

    /// 月份标题字体
    var monthTitleFont: NSFont

    /// 星期标题字体
    var weekdayTitleFont: NSFont

    /// 日期字体
    var dayFont: NSFont

    /// 今天高亮效果配置
    var todayHighlightStyle: TodayHighlightStyle

    /// 是否显示月份分隔线
    var showMonthSeparators: Bool

    /// 月份分隔线颜色
    var monthSeparatorColor: NSColor

    /// 月份分隔线宽度
    var monthSeparatorWidth: CGFloat

    /// 是否显示年份标题
    var showYearTitle: Bool

    /// 年份标题颜色
    var yearTitleColor: NSColor

    /// 年份标题字体
    var yearTitleFont: NSFont

    /// 阴影配置
    var shadow: ShadowStyle?

    /// 渐变配置
    var gradient: GradientStyle?

    /// 内边距
    var padding: CGFloat

    /// 是否显示农历日期
    var showLunarDate: Bool = false

    /// 农历日期颜色
    var lunarDateColor: NSColor = NSColor.gray

    /// 农历节日颜色
    var lunarFestivalColor: NSColor = NSColor.systemRed

    /// 农历节气颜色
    var lunarSolarTermColor: NSColor = NSColor.systemBlue

    /// 农历文字大小比例（相对于公历字体）
    var lunarTextSize: CGFloat = 0.75

    /// 是否显示假期
    var showHolidays: Bool = false

    /// 假期背景颜色
    var holidayBackgroundColor: NSColor = NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 0.3)

    /// 假期边框颜色
    var holidayBorderColor: NSColor = NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0)

    /// 假期文本颜色
    var holidayTextColor: NSColor = NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)

    /// 今天高亮效果样式
    enum TodayHighlightStyle {
        case circle
        case roundedRect(cornerRadius: CGFloat)
        case underline(thickness: CGFloat)
        case gradient(gradient: GradientStyle)
    }

    /// 阴影样式
    struct ShadowStyle {
        var color: NSColor
        var offset: CGSize
        var blurRadius: CGFloat
        var opacity: CGFloat
    }

    /// 渐变样式
    struct GradientStyle {
        var type: GradientType
        var colors: [NSColor]
        var locations: [CGFloat]?

        enum GradientType {
            case linear(startPoint: CGPoint, endPoint: CGPoint)
            case radial(center: CGPoint, radius: CGFloat)
        }
    }

    /// 浅色主题默认样式
    static func lightTheme() -> VisualStyle {
        return VisualStyle(
            theme: .light,
            backgroundColor: NSColor.white.withAlphaComponent(0.85),
            backgroundAlpha: 0.85,
            monthTitleColor: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
            weekdayTitleColor: NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0),
            dayTextColor: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0),
            weekendTextColor: NSColor.systemRed,
            todayHighlightColor: NSColor.systemBlue,
            todayTextColor: NSColor.white,
            monthTitleFont: NSFont.systemFont(ofSize: 24, weight: .bold),
            weekdayTitleFont: NSFont.systemFont(ofSize: 12, weight: .medium),
            dayFont: NSFont.systemFont(ofSize: 16, weight: .regular),
            todayHighlightStyle: .circle,
            showMonthSeparators: true,
            monthSeparatorColor: NSColor(white: 0.9, alpha: 1.0),
            monthSeparatorWidth: 1.0,
            showYearTitle: true,
            yearTitleColor: NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0),
            yearTitleFont: NSFont.systemFont(ofSize: 32, weight: .bold),
            shadow: ShadowStyle(
                color: NSColor.black.withAlphaComponent(0.1),
                offset: CGSize(width: 0, height: 2),
                blurRadius: 4,
                opacity: 0.1
            ),
            gradient: nil,
            padding: 40,
            lunarDateColor: NSColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0),
            lunarFestivalColor: NSColor.systemRed,
            lunarSolarTermColor: NSColor.systemBlue,
            showHolidays: false,
            holidayBackgroundColor: NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 0.3),
            holidayBorderColor: NSColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1.0),
            holidayTextColor: NSColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
        )
    }

    /// 深色主题默认样式
    static func darkTheme() -> VisualStyle {
        return VisualStyle(
            theme: .dark,
            backgroundColor: NSColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.85),
            backgroundAlpha: 0.85,
            monthTitleColor: NSColor(white: 0.9, alpha: 1.0),
            weekdayTitleColor: NSColor(white: 0.7, alpha: 1.0),
            dayTextColor: NSColor(white: 0.9, alpha: 1.0),
            weekendTextColor: NSColor.systemYellow,
            todayHighlightColor: NSColor.systemBlue,
            todayTextColor: NSColor.white,
            monthTitleFont: NSFont.systemFont(ofSize: 24, weight: .bold),
            weekdayTitleFont: NSFont.systemFont(ofSize: 12, weight: .medium),
            dayFont: NSFont.systemFont(ofSize: 16, weight: .regular),
            todayHighlightStyle: .circle,
            showMonthSeparators: true,
            monthSeparatorColor: NSColor(white: 0.3, alpha: 1.0),
            monthSeparatorWidth: 1.0,
            showYearTitle: true,
            yearTitleColor: NSColor(white: 0.8, alpha: 1.0),
            yearTitleFont: NSFont.systemFont(ofSize: 32, weight: .bold),
            shadow: ShadowStyle(
                color: NSColor.black.withAlphaComponent(0.3),
                offset: CGSize(width: 0, height: 2),
                blurRadius: 6,
                opacity: 0.3
            ),
            gradient: nil,
            padding: 40,
            lunarDateColor: NSColor(white: 0.7, alpha: 1.0),
            lunarFestivalColor: NSColor.systemRed,
            lunarSolarTermColor: NSColor.systemBlue,
            showHolidays: false,
            holidayBackgroundColor: NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.25),
            holidayBorderColor: NSColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0),
            holidayTextColor: NSColor(red: 1.0, green: 0.7, blue: 0.0, alpha: 1.0)
        )
    }

    /// 透明背景样式（用于与用户墙纸融合）
    static func transparentTheme() -> VisualStyle {
        var lightStyle = lightTheme()
        lightStyle.backgroundColor = NSColor.clear
        lightStyle.backgroundAlpha = 0.0
        lightStyle.shadow = nil // 透明背景通常不需要阴影
        return lightStyle
    }

    /// 根据系统设置自动选择主题
    static func autoTheme() -> VisualStyle {
        // 检查系统是否处于深色模式
        let isDarkMode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        return isDarkMode ? darkTheme() : lightTheme()
    }

    /// 默认样式（自动主题）
    static func `default`() -> VisualStyle {
        return autoTheme()
    }
}
