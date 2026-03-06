// CalendarGenerator.swift
// DeskCal - macOS Desktop Calendar
// 日历图片生成器，负责创建日历图片的绘图和布局

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
            padding: 40
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
            padding: 40
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

    /// 默认配置
    static func `default`(width: CGFloat = 1920, height: CGFloat = 1080, style: VisualStyle = .default()) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: style,
            padding: nil
        )
    }

    /// 使用浅色主题的配置
    static func lightTheme(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: .lightTheme(),
            padding: nil
        )
    }

    /// 使用深色主题的配置
    static func darkTheme(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: .darkTheme(),
            padding: nil
        )
    }

    /// 使用透明背景的配置
    static func transparentTheme(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            style: .transparentTheme(),
            padding: nil
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

/// 日历图片生成器
struct CalendarGenerator {

    /// 配置
    let config: CalendarConfig

    /// 初始化
    /// - Parameter config: 日历配置
    init(config: CalendarConfig = .default()) {
        self.config = config
    }

    /// 生成单个月份的日历图片
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    ///   - todayDay: 今天的日期（可选，用于高亮显示）
    /// - Returns: 生成的日历图片
    func generateMonthCalendar(year: Int, month: Int, todayDay: Int? = nil) throws -> NSImage {
        // 创建图片上下文
        let imageRep = try createImageContext(width: config.width, height: config.height)

        // 保存图形状态
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        // 设置当前上下文
        guard let context = NSGraphicsContext(bitmapImageRep: imageRep) else {
            throw NSError(domain: "CalendarGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
        }
        NSGraphicsContext.current = context

        // 绘制背景
        drawBackground()

        // 计算布局
        let layout = calculateLayout()

        // 绘制月份标题
        drawMonthTitle(year: year, month: month, layout: layout)

        // 绘制星期标题
        drawWeekdayTitles(layout: layout)

        // 绘制日期网格
        drawDayGrid(year: year, month: month, layout: layout, todayDay: todayDay)

        // 创建并返回图片
        return createImageFromRepresentation(imageRep)
    }

    /// 创建图片上下文
    private func createImageContext(width: CGFloat, height: CGFloat) throws -> NSBitmapImageRep {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(width),
            pixelsHigh: Int(height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 32
        ) else {
            throw NSError(domain: "CalendarGenerator", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap image representation"])
        }

        return rep
    }

    /// 绘制背景
    private func drawBackground() {
        config.effectiveBackgroundColor.setFill()
        NSRect(x: 0, y: 0, width: config.width, height: config.height).fill()
    }

    /// 计算日历布局
    private func calculateLayout() -> CalendarLayout {
        let padding = config.effectivePadding
        let availableWidth = config.width - (2 * padding)
        let availableHeight = config.height - (2 * padding)

        // 月份标题高度
        let monthTitleHeight: CGFloat = 80

        // 星期标题高度
        let weekdayTitleHeight: CGFloat = 40

        // 剩余高度用于日期网格（6行）
        let gridHeight = availableHeight - monthTitleHeight - weekdayTitleHeight
        let rowHeight = gridHeight / 6

        // 列宽（7列）
        let columnWidth = availableWidth / 7

        return CalendarLayout(
            padding: padding,
            monthTitleHeight: monthTitleHeight,
            weekdayTitleHeight: weekdayTitleHeight,
            rowHeight: rowHeight,
            columnWidth: columnWidth,
            availableWidth: availableWidth,
            availableHeight: availableHeight
        )
    }

    /// 绘制月份标题
    private func drawMonthTitle(year: Int, month: Int, layout: CalendarLayout) {
        let monthName = DateCalculator.monthName(for: month)
        let title = "\(monthName) \(year)"

        let font = config.style.monthTitleFont
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.style.monthTitleColor
        ]

        let textSize = title.size(withAttributes: attributes)
        let padding = config.effectivePadding
        let textRect = NSRect(
            x: padding + (layout.availableWidth - textSize.width) / 2,
            y: padding + layout.availableHeight - textSize.height,
            width: textSize.width,
            height: textSize.height
        )

        title.draw(in: textRect, withAttributes: attributes)
    }

    /// 绘制星期标题
    private func drawWeekdayTitles(layout: CalendarLayout) {
        let weekdayNames = DateCalculator.weekdayNames()
        let font = config.style.weekdayTitleFont
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.style.weekdayTitleColor
        ]

        let padding = config.effectivePadding
        let startY = padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight

        for (index, weekdayName) in weekdayNames.enumerated() {
            let textSize = weekdayName.size(withAttributes: attributes)
            let x = padding + (CGFloat(index) * layout.columnWidth) + (layout.columnWidth - textSize.width) / 2
            let textRect = NSRect(
                x: x,
                y: startY + (layout.weekdayTitleHeight - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            weekdayName.draw(in: textRect, withAttributes: attributes)
        }
    }

    /// 绘制日期网格
    private func drawDayGrid(year: Int, month: Int, layout: CalendarLayout, todayDay: Int?) {
        let matrix = DateCalculator.generateCalendarMatrix(year: year, month: month)
        let today = todayDay

        let padding = config.effectivePadding

        // 日期网格的起始Y坐标
        let startY = padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight - layout.rowHeight

        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, day) in row.enumerated() {
                guard let day = day else { continue }

                // 计算单元格位置
                let cellX = padding + (CGFloat(colIndex) * layout.columnWidth)
                let cellY = startY - (CGFloat(rowIndex) * layout.rowHeight)

                // 检查是否是周末（周日或周六）
                let isWeekend = colIndex == 0 || colIndex == 6  // 周日(0)和周六(6)
                let isToday = today == day

                // 绘制今天的高亮背景
                if isToday {
                    drawTodayHighlight(cellX: cellX, cellY: cellY,
                                       cellWidth: layout.columnWidth, cellHeight: layout.rowHeight)
                }

                // 绘制日期文本
                drawDayText(day: day, cellX: cellX, cellY: cellY,
                           cellWidth: layout.columnWidth, cellHeight: layout.rowHeight,
                           isWeekend: isWeekend, isToday: isToday)
            }
        }
    }

    /// 绘制今天的高亮背景
    private func drawTodayHighlight(cellX: CGFloat, cellY: CGFloat,
                                   cellWidth: CGFloat, cellHeight: CGFloat) {
        drawTodayHighlight(cellX: cellX, cellY: cellY,
                          cellWidth: cellWidth, cellHeight: cellHeight,
                          style: config.style)
    }

    /// 绘制今天的高亮背景（内部实现，使用样式）
    private func drawTodayHighlight(cellX: CGFloat, cellY: CGFloat,
                                   cellWidth: CGFloat, cellHeight: CGFloat,
                                   style: VisualStyle) {
        // 保存图形状态以应用阴影
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        // 应用阴影效果（如果存在）
        if let shadow = style.shadow {
            let shadowColor = shadow.color.withAlphaComponent(shadow.opacity)
            let shadowOffset = shadow.offset
            let shadowBlur = shadow.blurRadius

            let shadowObject = NSShadow()
            shadowObject.shadowColor = shadowColor
            shadowObject.shadowOffset = shadowOffset
            shadowObject.shadowBlurRadius = shadowBlur
            shadowObject.set()
        }

        // 根据高亮样式绘制
        switch style.todayHighlightStyle {
        case .circle:
            drawCircleHighlight(cellX: cellX, cellY: cellY,
                               cellWidth: cellWidth, cellHeight: cellHeight,
                               style: style)
        case .roundedRect(let cornerRadius):
            drawRoundedRectHighlight(cellX: cellX, cellY: cellY,
                                    cellWidth: cellWidth, cellHeight: cellHeight,
                                    cornerRadius: cornerRadius, style: style)
        case .underline(let thickness):
            drawUnderlineHighlight(cellX: cellX, cellY: cellY,
                                  cellWidth: cellWidth, cellHeight: cellHeight,
                                  thickness: thickness, style: style)
        case .gradient:
            // 暂时用圆形替代渐变高亮
            drawCircleHighlight(cellX: cellX, cellY: cellY,
                               cellWidth: cellWidth, cellHeight: cellHeight,
                               style: style)
        }
    }

    /// 绘制圆形高亮
    private func drawCircleHighlight(cellX: CGFloat, cellY: CGFloat,
                                    cellWidth: CGFloat, cellHeight: CGFloat,
                                    style: VisualStyle) {
        let circleDiameter = min(cellWidth, cellHeight) * 0.8
        let circleRect = NSRect(
            x: cellX + (cellWidth - circleDiameter) / 2,
            y: cellY + (cellHeight - circleDiameter) / 2,
            width: circleDiameter,
            height: circleDiameter
        )

        style.todayHighlightColor.setFill()
        let path = NSBezierPath(ovalIn: circleRect)
        path.fill()
    }

    /// 绘制圆角矩形高亮
    private func drawRoundedRectHighlight(cellX: CGFloat, cellY: CGFloat,
                                         cellWidth: CGFloat, cellHeight: CGFloat,
                                         cornerRadius: CGFloat, style: VisualStyle) {
        let rectWidth = cellWidth * 0.8
        let rectHeight = cellHeight * 0.8
        let rect = NSRect(
            x: cellX + (cellWidth - rectWidth) / 2,
            y: cellY + (cellHeight - rectHeight) / 2,
            width: rectWidth,
            height: rectHeight
        )

        style.todayHighlightColor.setFill()
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.fill()
    }

    /// 绘制下划线高亮
    private func drawUnderlineHighlight(cellX: CGFloat, cellY: CGFloat,
                                       cellWidth: CGFloat, cellHeight: CGFloat,
                                       thickness: CGFloat, style: VisualStyle) {
        let underlineWidth = cellWidth * 0.6
        let underlineHeight = thickness
        let underlineRect = NSRect(
            x: cellX + (cellWidth - underlineWidth) / 2,
            y: cellY + cellHeight * 0.2 - underlineHeight / 2,
            width: underlineWidth,
            height: underlineHeight
        )

        style.todayHighlightColor.setFill()
        let path = NSBezierPath(rect: underlineRect)
        path.fill()
    }

    /// 绘制渐变高亮（暂时用圆形替代）
    private func drawGradientHighlight(cellX: CGFloat, cellY: CGFloat,
                                      cellWidth: CGFloat, cellHeight: CGFloat,
                                      gradientStyle: VisualStyle.GradientStyle,
                                      style: VisualStyle) {
        // 暂时用圆形替代渐变高亮
        drawCircleHighlight(cellX: cellX, cellY: cellY,
                           cellWidth: cellWidth, cellHeight: cellHeight,
                           style: style)
    }


    /// 绘制日期文本
    private func drawDayText(day: Int, cellX: CGFloat, cellY: CGFloat,
                            cellWidth: CGFloat, cellHeight: CGFloat,
                            isWeekend: Bool, isToday: Bool) {
        let dayString = "\(day)"

        // 选择字体和颜色
        let font: NSFont
        if isToday {
            // 今天使用粗体版本
            let baseFont = config.style.dayFont
            font = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
        } else {
            font = config.style.dayFont
        }

        let textColor: NSColor
        if isToday {
            // 今天日期使用对比色（在高亮背景上可见）
            textColor = config.style.todayTextColor
        } else if isWeekend {
            textColor = config.style.weekendTextColor
        } else {
            textColor = config.style.dayTextColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textSize = dayString.size(withAttributes: attributes)
        let textRect = NSRect(
            x: cellX + (cellWidth - textSize.width) / 2,
            y: cellY + (cellHeight - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        dayString.draw(in: textRect, withAttributes: attributes)
    }

    /// 从位图表示创建图片
    private func createImageFromRepresentation(_ rep: NSBitmapImageRep) -> NSImage {
        let image = NSImage(size: NSSize(width: config.width, height: config.height))
        image.addRepresentation(rep)
        return image
    }
}

/// 日历布局信息
struct CalendarLayout {
    let padding: CGFloat
    let monthTitleHeight: CGFloat
    let weekdayTitleHeight: CGFloat
    let rowHeight: CGFloat
    let columnWidth: CGFloat
    let availableWidth: CGFloat
    let availableHeight: CGFloat
}

// MARK: - 全年日历生成扩展

extension CalendarGenerator {

    /// 生成全年日历图片
    /// - Parameters:
    ///   - year: 年份
    ///   - todayDate: 今天的日期（可选，用于高亮显示）
    /// - Returns: 生成的日历图片
    func generateYearCalendar(year: Int, todayDate: (month: Int, day: Int)? = nil) throws -> NSImage {
        // 创建图片上下文
        let imageRep = try createImageContext(width: config.width, height: config.height)

        // 保存图形状态
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        // 设置当前上下文
        guard let context = NSGraphicsContext(bitmapImageRep: imageRep) else {
            throw NSError(domain: "CalendarGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
        }
        NSGraphicsContext.current = context

        // 绘制背景
        drawBackground()

        // 计算全年布局
        let layoutResult = LayoutCalculator.calculateLayout(config: LayoutConfig.default(
            screenWidth: config.width,
            screenHeight: config.height,
            monthCount: 12
        ))

        // 为每个月份绘制日历
        for monthLayout in layoutResult.monthLayouts {
            let month = monthLayout.monthIndex + 1  // 月份索引转换为1-12

            // 创建月份特定的配置
            var monthConfig = config
            // 根据布局结果调整字体大小
            monthConfig.style.monthTitleFont = NSFont.systemFont(ofSize: layoutResult.monthTitleFontSize, weight: .bold)
            monthConfig.style.weekdayTitleFont = NSFont.systemFont(ofSize: layoutResult.weekdayTitleFontSize, weight: .medium)
            monthConfig.style.dayFont = NSFont.systemFont(ofSize: layoutResult.dayFontSize, weight: .regular)

            // 检查今天是否在这个月份
            let todayDay: Int? = {
                guard let today = todayDate, today.month == month else {
                    return nil
                }
                return today.day
            }()

            // 在指定位置绘制月份
            try drawMonthCalendar(
                year: year,
                month: month,
                todayDay: todayDay,
                in: monthLayout,
                config: monthConfig
            )
        }

        // 创建并返回图片
        return createImageFromRepresentation(imageRep)
    }

    /// 在指定位置绘制单个月份日历
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    ///   - todayDay: 今天的日期（可选）
    ///   - monthLayout: 月份布局信息
    ///   - config: 月份特定的配置
    private func drawMonthCalendar(
        year: Int,
        month: Int,
        todayDay: Int?,
        in monthLayout: MonthLayout,
        config: CalendarConfig
    ) throws {
        // 保存图形状态
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        // 设置裁剪区域（限制在月份边界内）
        let clipRect = NSRect(x: monthLayout.x, y: monthLayout.y,
                              width: monthLayout.width, height: monthLayout.height)
        NSBezierPath(rect: clipRect).addClip()

        // 计算月份内的布局
        let layout = calculateMonthLayout(in: monthLayout, config: config)

        // 绘制月份标题
        drawMonthTitle(year: year, month: month, layout: layout, monthLayout: monthLayout, config: config)

        // 绘制星期标题
        drawWeekdayTitles(layout: layout, monthLayout: monthLayout, config: config)

        // 绘制日期网格
        drawDayGrid(year: year, month: month, layout: layout, monthLayout: monthLayout,
                    todayDay: todayDay, config: config)
    }

    /// 计算月份内的布局
    /// - Parameters:
    ///   - monthLayout: 月份布局信息
    ///   - config: 月份特定的配置
    /// - Returns: 日历布局
    private func calculateMonthLayout(in monthLayout: MonthLayout, config: CalendarConfig) -> CalendarLayout {
        // 根据月份尺寸调整内边距，确保有足够空间
        let minMonthSize = min(monthLayout.width, monthLayout.height)
        let adjustedPadding = min(config.effectivePadding, minMonthSize * 0.1) // 最大为月份尺寸的10%

        let availableWidth = monthLayout.width - (2 * adjustedPadding)
        let availableHeight = monthLayout.height - (2 * adjustedPadding)

        // 月份标题高度（基于字体大小）
        let monthTitleHeight: CGFloat = config.style.monthTitleFont.pointSize * 1.5

        // 星期标题高度（基于字体大小）
        let weekdayTitleHeight: CGFloat = config.style.weekdayTitleFont.pointSize * 1.5

        // 剩余高度用于日期网格（6行）
        let gridHeight = availableHeight - monthTitleHeight - weekdayTitleHeight

        // 确保网格高度至少能容纳6行，每行最小高度为日期字体大小
        let minRowHeight = config.style.dayFont.pointSize * 1.2
        let minGridHeight = minRowHeight * 6

        var actualMonthTitleHeight = monthTitleHeight
        var actualWeekdayTitleHeight = weekdayTitleHeight
        var actualGridHeight = gridHeight
        var actualRowHeight: CGFloat = 0

        if gridHeight < minGridHeight {
            // 如果空间不足，计算总需求高度
            let totalNeededHeight = monthTitleHeight + weekdayTitleHeight + minGridHeight
            if totalNeededHeight > 0 {
                // 计算缩放因子，使总高度适应可用空间
                let scaleFactor = availableHeight / totalNeededHeight

                // 按比例缩放各部分高度
                actualMonthTitleHeight = monthTitleHeight * scaleFactor
                actualWeekdayTitleHeight = weekdayTitleHeight * scaleFactor
                actualGridHeight = minGridHeight * scaleFactor
            } else {
                // 回退方案：平均分配可用高度
                actualMonthTitleHeight = availableHeight * 0.3
                actualWeekdayTitleHeight = availableHeight * 0.2
                actualGridHeight = availableHeight * 0.5
            }
        } else {
            actualGridHeight = gridHeight
        }

        actualRowHeight = actualGridHeight / 6

        // 确保行高至少为日期字体大小，否则进一步调整
        if actualRowHeight < config.style.dayFont.pointSize {
            let neededGridHeight = config.style.dayFont.pointSize * 6
            let remainingHeight = availableHeight - neededGridHeight

            if remainingHeight > 0 {
                // 在月份标题和星期标题之间分配剩余高度
                actualMonthTitleHeight = remainingHeight * 0.6
                actualWeekdayTitleHeight = remainingHeight * 0.4
                actualGridHeight = neededGridHeight
                actualRowHeight = config.style.dayFont.pointSize
            } else {
                // 空间极度不足，使用最小可能高度
                actualGridHeight = availableHeight * 0.7
                actualRowHeight = actualGridHeight / 6
                actualMonthTitleHeight = availableHeight * 0.2
                actualWeekdayTitleHeight = availableHeight * 0.1
            }
        }

        // 列宽（7列）
        let columnWidth = availableWidth / 7

        return CalendarLayout(
            padding: adjustedPadding,
            monthTitleHeight: actualMonthTitleHeight,
            weekdayTitleHeight: actualWeekdayTitleHeight,
            rowHeight: actualRowHeight,
            columnWidth: columnWidth,
            availableWidth: availableWidth,
            availableHeight: availableHeight
        )
    }

    /// 绘制月份标题（在指定区域内）
    private func drawMonthTitle(year: Int, month: Int, layout: CalendarLayout,
                               monthLayout: MonthLayout, config: CalendarConfig) {
        let monthName = DateCalculator.monthName(for: month)
        let title = "\(monthName) \(year)"

        let font = config.style.monthTitleFont
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.style.monthTitleColor
        ]

        let textSize = title.size(withAttributes: attributes)
        let textRect = NSRect(
            x: monthLayout.x + layout.padding + (layout.availableWidth - textSize.width) / 2,
            y: monthLayout.y + layout.padding + layout.availableHeight - textSize.height,
            width: textSize.width,
            height: textSize.height
        )

        title.draw(in: textRect, withAttributes: attributes)
    }

    /// 绘制星期标题（在指定区域内）
    private func drawWeekdayTitles(layout: CalendarLayout, monthLayout: MonthLayout, config: CalendarConfig) {
        let weekdayNames = DateCalculator.weekdayNames()
        let font = config.style.weekdayTitleFont
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.style.weekdayTitleColor
        ]

        let startY = monthLayout.y + layout.padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight

        for (index, weekdayName) in weekdayNames.enumerated() {
            let textSize = weekdayName.size(withAttributes: attributes)
            let x = monthLayout.x + layout.padding + (CGFloat(index) * layout.columnWidth) + (layout.columnWidth - textSize.width) / 2
            let textRect = NSRect(
                x: x,
                y: startY + (layout.weekdayTitleHeight - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            weekdayName.draw(in: textRect, withAttributes: attributes)
        }
    }

    /// 绘制日期网格（在指定区域内）
    private func drawDayGrid(year: Int, month: Int, layout: CalendarLayout,
                            monthLayout: MonthLayout, todayDay: Int?, config: CalendarConfig) {
        let matrix = DateCalculator.generateCalendarMatrix(year: year, month: month)
        let today = todayDay

        // 日期网格的起始Y坐标
        let startY = monthLayout.y + layout.padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight - layout.rowHeight

        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, day) in row.enumerated() {
                guard let day = day else { continue }

                // 计算单元格位置（相对于月份区域）
                let cellX = monthLayout.x + layout.padding + (CGFloat(colIndex) * layout.columnWidth)
                let cellY = startY - (CGFloat(rowIndex) * layout.rowHeight)

                // 检查是否是周末（周日或周六）
                let isWeekend = colIndex == 0 || colIndex == 6  // 周日(0)和周六(6)
                let isToday = today == day

                // 绘制今天的高亮背景
                if isToday {
                    drawTodayHighlight(
                        cellX: cellX,
                        cellY: cellY,
                        cellWidth: layout.columnWidth,
                        cellHeight: layout.rowHeight,
                        config: config
                    )
                }

                // 绘制日期文本
                drawDayText(
                    day: day,
                    cellX: cellX,
                    cellY: cellY,
                    cellWidth: layout.columnWidth,
                    cellHeight: layout.rowHeight,
                    isWeekend: isWeekend,
                    isToday: isToday,
                    config: config
                )
            }
        }
    }

    /// 绘制今天的高亮背景
    private func drawTodayHighlight(cellX: CGFloat, cellY: CGFloat,
                                   cellWidth: CGFloat, cellHeight: CGFloat,
                                   config: CalendarConfig) {
        // 绘制圆形高亮
        let circleDiameter = min(cellWidth, cellHeight) * 0.8
        let circleRect = NSRect(
            x: cellX + (cellWidth - circleDiameter) / 2,
            y: cellY + (cellHeight - circleDiameter) / 2,
            width: circleDiameter,
            height: circleDiameter
        )

        config.style.todayHighlightColor.setFill()
        let path = NSBezierPath(ovalIn: circleRect)
        path.fill()
    }

    /// 绘制日期文本
    private func drawDayText(day: Int, cellX: CGFloat, cellY: CGFloat,
                            cellWidth: CGFloat, cellHeight: CGFloat,
                            isWeekend: Bool, isToday: Bool,
                            config: CalendarConfig) {
        let dayString = "\(day)"

        // 选择字体和颜色
        let font: NSFont
        if isToday {
            // 今天使用粗体版本
            let baseFont = config.style.dayFont
            font = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
        } else {
            font = config.style.dayFont
        }

        let textColor: NSColor
        if isToday {
            // 今天日期使用对比色（在高亮背景上可见）
            textColor = config.style.todayTextColor
        } else if isWeekend {
            textColor = config.style.weekendTextColor
        } else {
            textColor = config.style.dayTextColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textSize = dayString.size(withAttributes: attributes)
        let textRect = NSRect(
            x: cellX + (cellWidth - textSize.width) / 2,
            y: cellY + (cellHeight - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        dayString.draw(in: textRect, withAttributes: attributes)
    }
}