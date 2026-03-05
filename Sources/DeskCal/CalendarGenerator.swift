// CalendarGenerator.swift
// DeskCal - macOS Desktop Calendar
// 日历图片生成器，负责创建日历图片的绘图和布局

import AppKit

/// 日历生成器配置
struct CalendarConfig {
    /// 图片宽度
    var width: CGFloat
    /// 图片高度
    var height: CGFloat
    /// 背景颜色
    var backgroundColor: NSColor
    /// 月份标题颜色
    var monthTitleColor: NSColor
    /// 星期标题颜色
    var weekdayTitleColor: NSColor
    /// 日期文本颜色
    var dayTextColor: NSColor
    /// 周末日期颜色
    var weekendTextColor: NSColor
    /// 今天高亮颜色
    var todayHighlightColor: NSColor
    /// 月份标题字体大小
    var monthTitleFontSize: CGFloat
    /// 星期标题字体大小
    var weekdayTitleFontSize: CGFloat
    /// 日期字体大小
    var dayFontSize: CGFloat
    /// 内边距
    var padding: CGFloat

    /// 默认配置
    static func `default`(width: CGFloat = 1920, height: CGFloat = 1080) -> CalendarConfig {
        return CalendarConfig(
            width: width,
            height: height,
            backgroundColor: NSColor.systemBlue.withAlphaComponent(0.8),
            monthTitleColor: NSColor.white,
            weekdayTitleColor: NSColor.white,
            dayTextColor: NSColor.white,
            weekendTextColor: NSColor.systemYellow,
            todayHighlightColor: NSColor.systemRed,
            monthTitleFontSize: 48,
            weekdayTitleFontSize: 24,
            dayFontSize: 32,
            padding: 40
        )
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
        config.backgroundColor.setFill()
        NSRect(x: 0, y: 0, width: config.width, height: config.height).fill()
    }

    /// 计算日历布局
    private func calculateLayout() -> CalendarLayout {
        let availableWidth = config.width - (2 * config.padding)
        let availableHeight = config.height - (2 * config.padding)

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
            padding: config.padding,
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

        let font = NSFont.systemFont(ofSize: config.monthTitleFontSize, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.monthTitleColor
        ]

        let textSize = title.size(withAttributes: attributes)
        let textRect = NSRect(
            x: config.padding + (layout.availableWidth - textSize.width) / 2,
            y: config.padding + layout.availableHeight - textSize.height,
            width: textSize.width,
            height: textSize.height
        )

        title.draw(in: textRect, withAttributes: attributes)
    }

    /// 绘制星期标题
    private func drawWeekdayTitles(layout: CalendarLayout) {
        let weekdayNames = DateCalculator.weekdayNames()
        let font = NSFont.systemFont(ofSize: config.weekdayTitleFontSize, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.weekdayTitleColor
        ]

        let startY = config.padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight

        for (index, weekdayName) in weekdayNames.enumerated() {
            let textSize = weekdayName.size(withAttributes: attributes)
            let x = config.padding + (CGFloat(index) * layout.columnWidth) + (layout.columnWidth - textSize.width) / 2
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

        _ = NSFont.systemFont(ofSize: config.dayFontSize, weight: .regular)  // Unused, kept for symmetry
        _ = NSFont.systemFont(ofSize: config.dayFontSize, weight: .regular)  // Unused, kept for symmetry

        // 日期网格的起始Y坐标
        let startY = config.padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight - layout.rowHeight

        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, day) in row.enumerated() {
                guard let day = day else { continue }

                // 计算单元格位置
                let cellX = config.padding + (CGFloat(colIndex) * layout.columnWidth)
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
        // 绘制圆形高亮
        let circleDiameter = min(cellWidth, cellHeight) * 0.8
        let circleRect = NSRect(
            x: cellX + (cellWidth - circleDiameter) / 2,
            y: cellY + (cellHeight - circleDiameter) / 2,
            width: circleDiameter,
            height: circleDiameter
        )

        config.todayHighlightColor.setFill()
        let path = NSBezierPath(ovalIn: circleRect)
        path.fill()
    }

    /// 绘制日期文本
    private func drawDayText(day: Int, cellX: CGFloat, cellY: CGFloat,
                            cellWidth: CGFloat, cellHeight: CGFloat,
                            isWeekend: Bool, isToday: Bool) {
        let dayString = "\(day)"

        // 选择字体和颜色
        let font = NSFont.systemFont(ofSize: config.dayFontSize, weight: isToday ? .bold : .regular)
        let textColor: NSColor

        if isToday {
            // 今天日期使用对比色（在高亮背景上可见）
            textColor = NSColor.white
        } else if isWeekend {
            textColor = config.weekendTextColor
        } else {
            textColor = config.dayTextColor
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