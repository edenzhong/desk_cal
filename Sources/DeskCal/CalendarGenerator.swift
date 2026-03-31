// CalendarGenerator.swift
// DeskCal - macOS Desktop Calendar
// 日历图片生成器，负责创建日历图片的绘图和布局

import AppKit

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
    @MainActor
    func generateMonthCalendar(year: Int, month: Int, todayDay: Int? = nil) throws -> NSImage {
        let imageRep = try CalendarRenderer.createImageContext(width: config.width, height: config.height)

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let context = NSGraphicsContext(bitmapImageRep: imageRep) else {
            throw NSError(domain: "CalendarGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
        }
        NSGraphicsContext.current = context

        CalendarRenderer.configureHighQualityRendering()
        CalendarRenderer.drawBackground(config.effectiveBackgroundColor, width: config.width, height: config.height)

        let layout = calculateLayout()
        drawMonthTitle(year: year, month: month, layout: layout)
        drawWeekdayTitles(layout: layout)
        drawDayGridForForSingleMonth(year: year, month: month, layout: layout, todayDay: todayDay)

        return CalendarRenderer.createImageFromRepresentation(imageRep, width: config.width, height: config.height)
    }

    /// 计算日历布局
    private func calculateLayout() -> CalendarLayout {
        let padding = config.effectivePadding
        let availableWidth = config.width - (2 * padding)
        let availableHeight = config.height - (2 * padding)

        let monthTitleHeight: CGFloat = 80
        let weekdayTitleHeight: CGFloat = 40
        let gridHeight = availableHeight - monthTitleHeight - weekdayTitleHeight
        let rowHeight = gridHeight / 6
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

    /// 绘制日期网格（单月日历版本）
    @MainActor
    private func drawDayGridForForSingleMonth(year: Int, month: Int, layout: CalendarLayout, todayDay: Int?) {
        let matrix = DateCalculator.generateCalendarMatrix(year: year, month: month)
        let today = todayDay

        let padding = config.effectivePadding
        let startY = padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight - layout.rowHeight

        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, day) in row.enumerated() {
                guard let day = day else { continue }

                let cellX = padding + (CGFloat(colIndex) * layout.columnWidth)
                let cellY = startY - (CGFloat(rowIndex) * layout.rowHeight)

                let isWeekend = colIndex == 0 || colIndex == 6
                let isToday = today == day

                var isHoliday = false
                if config.style.showHolidays {
                    let dateFormatter = DateFormatter()
                    dateFormatter.calendar = Calendar.current
                    let dateComponents = DateComponents(year: year, month: month, day: day)
                    if let date = dateFormatter.calendar.date(from: dateComponents) {
                        isHoliday = HolidayService.shared.isHolidaySync(date)
                    }
                }

                let textWidth = CalendarRenderer.calculateDayTextWidth(
                    day: day,
                    year: year,
                    month: month,
                    cellWidth: layout.columnWidth,
                    cellHeight: layout.rowHeight,
                    config: config
                )

                if isHoliday {
                    CalendarRenderer.drawHolidayHighlight(cellX: cellX, cellY: cellY,
                                                   cellWidth: layout.columnWidth, cellHeight: layout.rowHeight,
                                                   style: config.style)
                }

                if isToday {
                    CalendarRenderer.drawTodayHighlight(cellX: cellX, cellY: cellY,
                                               cellWidth: layout.columnWidth, cellHeight: layout.rowHeight,
                                               textWidth: textWidth, style: config.style)
                }

                CalendarRenderer.drawDayText(day: day, year: year, month: month, cellX: cellX, cellY: cellY,
                                   cellWidth: layout.columnWidth, cellHeight: layout.rowHeight,
                                   isWeekend: isWeekend, isToday: isToday, isHoliday: isHoliday, config: config)
            }
        }
    }
}

// MARK: - 全年日历生成扩展

extension CalendarGenerator {

    /// 生成全年日历图片
    /// - Parameters:
    ///   - year: 年份
    ///   - todayDate: 今天的日期（可选，用于高亮显示）
    /// - Returns: 生成的日历图片
    @MainActor
    func generateYearCalendar(year: Int, todayDate: (month: Int, day: Int)? = nil) throws -> NSImage {
        let imageRep = try CalendarRenderer.createImageContext(width: config.width, height: config.height)

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let context = NSGraphicsContext(bitmapImageRep: imageRep) else {
            throw NSError(domain: "CalendarGenerator", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
        }
        NSGraphicsContext.current = context

        CalendarRenderer.configureHighQualityRendering()
        CalendarRenderer.drawBackground(config.effectiveBackgroundColor, width: config.width, height: config.height)

        let layoutResult = LayoutCalculator.calculateLayout(config: LayoutConfig.default(
            screenWidth: config.width,
            screenHeight: config.height,
            monthCount: 12
        ))

        for monthLayout in layoutResult.monthLayouts {
            let month = monthLayout.monthIndex + 1

            var monthConfig = config
            monthConfig.style.monthTitleFont = NSFont.systemFont(ofSize: layoutResult.monthTitleFontSize, weight: .bold)
            monthConfig.style.weekdayTitleFont = NSFont.systemFont(ofSize: layoutResult.weekdayTitleFontSize, weight: .medium)
            monthConfig.style.dayFont = NSFont.systemFont(ofSize: layoutResult.dayFontSize, weight: .regular)

            let todayDay: Int? = {
                guard let today = todayDate, today.month == month else {
                    return nil
                }
                return today.day
            }()

            try drawMonthCalendar(
                year: year,
                month: month,
                todayDay: todayDay,
                in: monthLayout,
                config: monthConfig
            )
        }

        return CalendarRenderer.createImageFromRepresentation(imageRep, width: config.width, height: config.height)
    }

    /// 在指定位置绘制单个月份日历
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    ///   - todayDay: 今天的日期（可选）
    ///   - monthLayout: 月份布局信息
    ///   - config: 月份特定的配置
    @MainActor
    private func drawMonthCalendar(
        year: Int,
        month: Int,
        todayDay: Int?,
        in monthLayout: MonthLayout,
        config: CalendarConfig
    ) throws {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        let clipRect = NSRect(x: monthLayout.x, y: monthLayout.y,
                              width: monthLayout.width, height: monthLayout.height)
        NSBezierPath(rect: clipRect).addClip()

        let layout = calculateMonthLayout(in: monthLayout, config: config)

        drawMonthTitle(year: year, month: month, layout: layout, monthLayout: monthLayout, config: config)
        drawWeekdayTitles(layout: layout, monthLayout: monthLayout, config: config)
        drawDayGrid(year: year, month: month, layout: layout, monthLayout: monthLayout,
                    todayDay: todayDay, config: config)
    }

    /// 计算月份内的布局
    private func calculateMonthLayout(in monthLayout: MonthLayout, config: CalendarConfig) -> CalendarLayout {
        let minMonthSize = min(monthLayout.width, monthLayout.height)
        let adjustedPadding = min(config.effectivePadding, minMonthSize * 0.1)

        let availableWidth = monthLayout.width - (2 * adjustedPadding)
        let availableHeight = monthLayout.height - (2 * adjustedPadding)

        let monthTitleHeight: CGFloat = config.style.monthTitleFont.pointSize * 1.5
        let weekdayTitleHeight: CGFloat = config.style.weekdayTitleFont.pointSize * 1.5
        let gridHeight = availableHeight - monthTitleHeight - weekdayTitleHeight

        let minRowHeight = config.style.dayFont.pointSize * 1.2
        let minGridHeight = minRowHeight * 6

        var actualMonthTitleHeight = monthTitleHeight
        var actualWeekdayTitleHeight = weekdayTitleHeight
        var actualGridHeight = gridHeight
        var actualRowHeight: CGFloat = 0

        if gridHeight < minGridHeight {
            let totalNeededHeight = monthTitleHeight + weekdayTitleHeight + minGridHeight
            if totalNeededHeight > 0 {
                let scaleFactor = availableHeight / totalNeededHeight

                actualMonthTitleHeight = monthTitleHeight * scaleFactor
                actualWeekdayTitleHeight = weekdayTitleHeight * scaleFactor
                actualGridHeight = minGridHeight * scaleFactor
            } else {
                actualMonthTitleHeight = availableHeight * 0.3
                actualWeekdayTitleHeight = availableHeight * 0.2
                actualGridHeight = availableHeight * 0.5
            }
        } else {
            actualGridHeight = gridHeight
        }

        actualRowHeight = actualGridHeight / 6

        if actualRowHeight < config.style.dayFont.pointSize {
            let neededGridHeight = config.style.dayFont.pointSize * 6
            let remainingHeight = availableHeight - neededGridHeight

            if remainingHeight > 0 {
                actualMonthTitleHeight = remainingHeight * 0.6
                actualWeekdayTitleHeight = remainingHeight * 0.4
                actualGridHeight = neededGridHeight
                actualRowHeight = config.style.dayFont.pointSize
            } else {
                actualGridHeight = availableHeight * 0.7
                actualRowHeight = actualGridHeight / 6
                actualMonthTitleHeight = availableHeight * 0.2
                actualWeekdayTitleHeight = availableHeight * 0.1
            }
        }

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
    @MainActor
    private func drawDayGrid(year: Int, month: Int, layout: CalendarLayout,
                            monthLayout: MonthLayout, todayDay: Int?, config: CalendarConfig) {
        let matrix = DateCalculator.generateCalendarMatrix(year: year, month: month)
        let today = todayDay

        let startY = monthLayout.y + layout.padding + layout.availableHeight - layout.monthTitleHeight - layout.weekdayTitleHeight - layout.rowHeight

        for (rowIndex, row) in matrix.enumerated() {
            for (colIndex, day) in row.enumerated() {
                guard let day = day else { continue }

                let cellX = monthLayout.x + layout.padding + (CGFloat(colIndex) * layout.columnWidth)
                let cellY = startY - (CGFloat(rowIndex) * layout.rowHeight)

                let isWeekend = colIndex == 0 || colIndex == 6
                let isToday = today == day

                var isHoliday = false
                if config.style.showHolidays {
                    let dateFormatter = DateFormatter()
                    dateFormatter.calendar = Calendar.current
                    let dateComponents = DateComponents(year: year, month: month, day: day)
                    if let date = dateFormatter.calendar.date(from: dateComponents) {
                        isHoliday = HolidayService.shared.isHolidaySync(date)
                    }
                }

                let textWidth = CalendarRenderer.calculateDayTextWidth(
                    day: day,
                    year: year,
                    month: month,
            cellWidth: layout.columnWidth,
            cellHeight: layout.rowHeight,
                    config: config
                )

                if isHoliday {
                    CalendarRenderer.drawHolidayHighlight(cellX: cellX, cellY: cellY,
                                                   cellWidth: layout.columnWidth, cellHeight: layout.rowHeight,
                                                   style: config.style)
                }

                if isToday {
                    CalendarRenderer.drawTodayHighlight(cellX: cellX, cellY: cellY,
                                               cellWidth: layout.columnWidth, cellHeight: layout.rowHeight,
                                               textWidth: textWidth, style: config.style)
                }

                CalendarRenderer.drawDayText(
                    day: day,
                    year: year,
                    month: month,
                    cellX: cellX,
                    cellY: cellY,
                    cellWidth: layout.columnWidth,
                    cellHeight: layout.rowHeight,
                    isWeekend: isWeekend,
                    isToday: isToday,
                    isHoliday: isHoliday,
                    config: config
                )
            }
        }
    }
}
