// CalendarConfig.swift
// DeskCal - macOS Desktop Calendar
// 日历配置结构

import AppKit

/// 日历生成器配置
struct CalendarConfig {
    /// 图片宽度
    var width: CGFloat

    /// 图片高度
    var height: CGFloat

    /// 视觉样式
    var style: VisualStyle

    /// 内边距（覆盖样式中的内边距，如果提供）
    var padding: CGFloat?

    /// 农历日期格式
    var lunarDateFormat: String = "short"

    /// 默认配置
    static func `default`(width: CGFloat = 1920, height: CGFloat = 1080, style: VisualStyle = .default()) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: style,
            padding: nil,
            lunarDateFormat: "short"
        )
    }

    /// 使用浅色主题的配置
    static func lightTheme(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: .lightTheme(),
            padding: nil,
            lunarDateFormat: "short"
        )
    }

    /// 使用深色主题的配置
    static func darkTheme(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: .darkTheme(),
            padding: nil,
            lunarDateFormat: "short"
        )
    }

    /// 使用透明背景的配置
    static func transparentTheme(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: .transparentTheme(),
            padding: nil,
            lunarDateFormat: "short"
        )
    }

    /// 获取实际内边距（优先使用配置的内边距，否则使用样式的内边距）
    var effectivePadding: CGFloat {
        return padding ?? style.padding
    }

    /// 获取背景颜色（考虑透明度）
    var effectiveBackgroundColor: NSColor {
        if style.backgroundAlpha == 0.0 {
            return NSColor.clear
        } else {
            return style.backgroundColor.withAlphaComponent(style.backgroundAlpha)
        }
    }
}
