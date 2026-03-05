// LayoutCalculator.swift
// DeskCal - macOS Desktop Calendar
// 布局计算器，负责根据屏幕尺寸计算最优的月份布局

import Foundation
import CoreGraphics

/// 布局计算器配置
struct LayoutConfig {
    /// 屏幕宽度
    let screenWidth: CGFloat
    /// 屏幕高度
    let screenHeight: CGFloat
    /// 月份数量
    let monthCount: Int
    /// 内边距
    let padding: CGFloat
    /// 月份之间的水平间距
    let horizontalSpacing: CGFloat
    /// 月份之间的垂直间距
    let verticalSpacing: CGFloat

    /// 默认配置
    static func `default`(screenWidth: CGFloat, screenHeight: CGFloat, monthCount: Int = 12) -> LayoutConfig {
        return LayoutConfig(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            monthCount: monthCount,
            padding: 40,
            horizontalSpacing: 30,
            verticalSpacing: 30
        )
    }
}

/// 月份布局信息
struct MonthLayout {
    /// 月份索引（0-11）
    let monthIndex: Int
    /// 月份在布局中的列位置（从0开始）
    let column: Int
    /// 月份在布局中的行位置（从0开始）
    let row: Int
    /// 月份区域的X坐标
    let x: CGFloat
    /// 月份区域的Y坐标
    let y: CGFloat
    /// 月份区域的宽度
    let width: CGFloat
    /// 月份区域的高度
    let height: CGFloat
}

/// 布局计算结果
struct LayoutResult {
    /// 所有月份的布局信息
    let monthLayouts: [MonthLayout]
    /// 总列数
    let columns: Int
    /// 总行数
    let rows: Int
    /// 推荐的月份标题字体大小
    let monthTitleFontSize: CGFloat
    /// 推荐的星期标题字体大小
    let weekdayTitleFontSize: CGFloat
    /// 推荐的日期字体大小
    let dayFontSize: CGFloat
}

/// 布局计算器
struct LayoutCalculator {

    /// 计算最优布局
    /// - Parameter config: 布局配置
    /// - Returns: 布局计算结果
    static func calculateLayout(config: LayoutConfig) -> LayoutResult {
        // 1. 确定列数
        let columns = calculateColumnCount(screenWidth: config.screenWidth, screenHeight: config.screenHeight)

        // 2. 计算行数
        let rows = Int(ceil(CGFloat(config.monthCount) / CGFloat(columns)))

        // 3. 计算每个月份的尺寸
        let (monthWidth, monthHeight) = calculateMonthSize(
            screenWidth: config.screenWidth,
            screenHeight: config.screenHeight,
            columns: columns,
            rows: rows,
            padding: config.padding,
            horizontalSpacing: config.horizontalSpacing,
            verticalSpacing: config.verticalSpacing
        )

        // 4. 计算字体大小（基于月份尺寸）
        let fontSizes = calculateFontSizes(monthWidth: monthWidth, monthHeight: monthHeight)

        // 5. 为每个月份计算布局位置
        let monthLayouts = calculateMonthPositions(
            monthCount: config.monthCount,
            columns: columns,
            rows: rows,
            monthWidth: monthWidth,
            monthHeight: monthHeight,
            padding: config.padding,
            horizontalSpacing: config.horizontalSpacing,
            verticalSpacing: config.verticalSpacing
        )


        return LayoutResult(
            monthLayouts: monthLayouts,
            columns: columns,
            rows: rows,
            monthTitleFontSize: fontSizes.monthTitle,
            weekdayTitleFontSize: fontSizes.weekdayTitle,
            dayFontSize: fontSizes.day
        )
    }

    /// 根据屏幕尺寸计算列数
    /// - Parameters:
    ///   - screenWidth: 屏幕宽度
    ///   - screenHeight: 屏幕高度
    /// - Returns: 推荐的列数
    private static func calculateColumnCount(screenWidth: CGFloat, screenHeight: CGFloat) -> Int {
        // 根据屏幕尺寸决定列数
        let screenArea = screenWidth * screenHeight

        // 定义阈值（以像素为单位）
        // 小屏幕：< 1920x1080 (约2百万像素)
        // 中等屏幕：1920x1080 到 2560x1440 (约2-3.7百万像素)
        // 大屏幕：> 2560x1440 (约3.7百万像素以上)

        if screenArea < 1920 * 1080 {
            // 小屏幕：根据宽高比决定
            if screenWidth >= 1440 {
                return 3  // 较宽的小屏幕：3列
            } else {
                return 2  // 较窄的小屏幕：2列
            }
        } else if screenArea <= 2560 * 1440 {
            return 3  // 中等屏幕：3列
        } else {
            return 4  // 大屏幕：4列
        }
    }

    /// 计算每个月份的尺寸
    /// - Parameters:
    ///   - screenWidth: 屏幕宽度
    ///   - screenHeight: 屏幕高度
    ///   - columns: 列数
    ///   - rows: 行数
    ///   - padding: 内边距
    ///   - horizontalSpacing: 水平间距
    ///   - verticalSpacing: 垂直间距
    /// - Returns: (月份宽度, 月份高度)
    private static func calculateMonthSize(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        columns: Int,
        rows: Int,
        padding: CGFloat,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat
    ) -> (width: CGFloat, height: CGFloat) {
        // 计算可用区域
        let availableWidth = screenWidth - (2 * padding) - (CGFloat(columns - 1) * horizontalSpacing)
        let availableHeight = screenHeight - (2 * padding) - (CGFloat(rows - 1) * verticalSpacing)

        // 计算每个月份的尺寸
        let monthWidth = availableWidth / CGFloat(columns)
        let monthHeight = availableHeight / CGFloat(rows)

        return (monthWidth, monthHeight)
    }

    /// 计算字体大小
    /// - Parameters:
    ///   - monthWidth: 月份宽度
    ///   - monthHeight: 月份高度
    /// - Returns: (月份标题字体大小, 星期标题字体大小, 日期字体大小)
    private static func calculateFontSizes(monthWidth: CGFloat, monthHeight: CGFloat) -> (monthTitle: CGFloat, weekdayTitle: CGFloat, day: CGFloat) {
        // 基于月份尺寸计算字体大小
        // 使用比例因子确保在不同尺寸下可读
        let scaleFactor = min(monthWidth, monthHeight) / 300.0  // 基于300像素参考尺寸

        // 基础字体大小
        let baseMonthTitleSize: CGFloat = 24.0
        let baseWeekdayTitleSize: CGFloat = 12.0
        let baseDaySize: CGFloat = 16.0

        // 应用比例因子，但设置最小和最大限制
        let monthTitleSize = max(16.0, min(48.0, baseMonthTitleSize * scaleFactor))
        let weekdayTitleSize = max(10.0, min(24.0, baseWeekdayTitleSize * scaleFactor))
        let daySize = max(12.0, min(32.0, baseDaySize * scaleFactor))

        return (monthTitleSize, weekdayTitleSize, daySize)
    }

    /// 计算每个月份的位置
    /// - Parameters:
    ///   - monthCount: 月份数量
    ///   - columns: 列数
    ///   - rows: 行数
    ///   - monthWidth: 月份宽度
    ///   - monthHeight: 月份高度
    ///   - padding: 内边距
    ///   - horizontalSpacing: 水平间距
    ///   - verticalSpacing: 垂直间距
    /// - Returns: 月份布局数组
    private static func calculateMonthPositions(
        monthCount: Int,
        columns: Int,
        rows: Int,
        monthWidth: CGFloat,
        monthHeight: CGFloat,
        padding: CGFloat,
        horizontalSpacing: CGFloat,
        verticalSpacing: CGFloat
    ) -> [MonthLayout] {
        var layouts: [MonthLayout] = []

        for monthIndex in 0..<monthCount {
            let row = monthIndex / columns
            let column = monthIndex % columns

            // 计算位置
            let x = padding + (CGFloat(column) * (monthWidth + horizontalSpacing))
            let y = padding + (CGFloat(rows - row - 1) * (monthHeight + verticalSpacing))

            let layout = MonthLayout(
                monthIndex: monthIndex,
                column: column,
                row: row,
                x: x,
                y: y,
                width: monthWidth,
                height: monthHeight
            )

            layouts.append(layout)
        }

        return layouts
    }
}