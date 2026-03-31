// CalendarRenderer.swift
// DeskCal - macOS Desktop Calendar
// 渲染工具方法

import AppKit

/// 日历渲染工具
enum CalendarRenderer {

    /// 创建图片上下文（支持高分辨率屏幕）
    static func createImageContext(width: CGFloat, height: CGFloat) throws -> NSBitmapImageRep {
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        let scaledWidth = Int(width * scaleFactor)
        let scaledHeight = Int(height * scaleFactor)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: scaledWidth,
            pixelsHigh: scaledHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 32
        ) else {
            throw NSError(domain: "CalendarRenderer", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create bitmap image representation"])
        }

        rep.size = NSSize(width: width, height: height)
        return rep
    }

    /// 配置高质量渲染设置
    static func configureHighQualityRendering() {
        guard let cgContext = NSGraphicsContext.current?.cgContext else { return }

        cgContext.setAllowsAntialiasing(true)
        cgContext.setShouldAntialias(true)
        cgContext.setAllowsFontSmoothing(true)
        cgContext.setShouldSmoothFonts(true)
        cgContext.setAllowsFontSubpixelPositioning(true)
        cgContext.setAllowsFontSubpixelQuantization(true)
        cgContext.interpolationQuality = .high

        if let graphicsContext = NSGraphicsContext.current {
            graphicsContext.imageInterpolation = .high
            graphicsContext.shouldAntialias = true
        }
    }

    /// 绘制背景
    static func drawBackground(_ color: NSColor, width: CGFloat, height: CGFloat) {
        color.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
    }

    /// 从位图表示创建图片
    static func createImageFromRepresentation(_ rep: NSBitmapImageRep, width: CGFloat, height: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(rep)
        return image
    }

    /// 绘制今天的高亮背景
    static func drawTodayHighlight(cellX: CGFloat, cellY: CGFloat,
                                   cellWidth: CGFloat, cellHeight: CGFloat,
                                   textWidth: CGFloat, style: VisualStyle) {
        let textHeight = style.dayFont.pointSize
        let lunarTextHeight = textHeight * style.lunarTextSize
        let totalTextHeight = max(textHeight, lunarTextHeight)

        let highlightWidth: CGFloat
        let highlightHeight: CGFloat

        if style.showLunarDate && textWidth > 0 {
            highlightWidth = min(textWidth * 1.15, cellWidth * 0.95)
            highlightHeight = min(totalTextHeight * 1.4, cellHeight * 0.9)
        } else {
            let diameter = min(cellWidth, cellHeight) * 0.95
            highlightWidth = diameter
            highlightHeight = diameter
        }

        let cornerRadius = min(highlightWidth, highlightHeight) / 2

        let highlightRect = NSRect(
            x: cellX + (cellWidth - highlightWidth) / 2,
            y: cellY + (cellHeight - highlightHeight) / 2,
            width: highlightWidth,
            height: highlightHeight
        )

        style.todayHighlightColor.setFill()
        let path = NSBezierPath(roundedRect: highlightRect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.fill()
    }

    /// 绘制假期高亮背景
    static func drawHolidayHighlight(cellX: CGFloat, cellY: CGFloat,
                                     cellWidth: CGFloat, cellHeight: CGFloat,
                                     style: VisualStyle) {
        let highlightRect = NSRect(
            x: cellX + 2,
            y: cellY + 2,
            width: cellWidth - 4,
            height: cellHeight - 4
        )

        style.holidayBackgroundColor.setFill()
        NSBezierPath(rect: highlightRect).fill()

        style.holidayBorderColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: highlightRect, xRadius: 4, yRadius: 4)
        borderPath.lineWidth = 1.5
        borderPath.stroke()
    }

    /// 计算日期文本的总宽度（公历+农历）
    @MainActor
    static func calculateDayTextWidth(day: Int, year: Int, month: Int,
                                     cellWidth: CGFloat, cellHeight: CGFloat,
                                     config: CalendarConfig) -> CGFloat {
        let dayString = "\(day)"
        let font = config.style.dayFont
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: config.style.dayTextColor
        ]

        var lunarText: String? = nil
        if config.style.showLunarDate {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar.current
            let dateComponents = DateComponents(year: year, month: month, day: day)
            if let date = dateFormatter.calendar.date(from: dateComponents) {
                let lunarDate = LunarDateConverter.shared.convert(date)
                lunarText = LunarDateConverter.shared.format(lunarDate, format: config.lunarDateFormat)
            }
        }

        let dayTextSize = dayString.size(withAttributes: attributes)
        let spacer = " "
        let spacerSize = spacer.size(withAttributes: attributes)
        var totalTextWidth = dayTextSize.width

        if let lunarText = lunarText {
            let lunarFontSize = config.style.dayFont.pointSize * config.style.lunarTextSize
            let lunarFont = NSFont.systemFont(ofSize: lunarFontSize, weight: .light)
            let lunarAttributes: [NSAttributedString.Key: Any] = [
                .font: lunarFont,
                .foregroundColor: config.style.lunarDateColor
            ]
            let lunarTextSize = lunarText.size(withAttributes: lunarAttributes)
            totalTextWidth += spacerSize.width + lunarTextSize.width
        }

        return totalTextWidth
    }

    /// 绘制日期文本
    @MainActor
    static func drawDayText(day: Int, year: Int, month: Int, cellX: CGFloat, cellY: CGFloat,
                            cellWidth: CGFloat, cellHeight: CGFloat,
                            isWeekend: Bool, isToday: Bool, isHoliday: Bool = false,
                            config: CalendarConfig) {
        let dayString = "\(day)"

        let font: NSFont
        if isToday {
            let baseFont = config.style.dayFont
            font = NSFont.systemFont(ofSize: baseFont.pointSize, weight: .bold)
        } else {
            font = config.style.dayFont
        }

        let textColor: NSColor
        if isToday {
            textColor = config.style.todayTextColor
        } else if isHoliday {
            textColor = config.style.holidayTextColor
        } else if isWeekend {
            textColor = config.style.weekendTextColor
        } else {
            textColor = config.style.dayTextColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let textY = cellY + (cellHeight - font.pointSize) / 2

        var lunarText: String? = nil
        if config.style.showLunarDate {
            let dateFormatter = DateFormatter()
            dateFormatter.calendar = Calendar.current
            let dateComponents = DateComponents(year: year, month: month, day: day)
            if let date = dateFormatter.calendar.date(from: dateComponents) {
                let lunarDate = LunarDateConverter.shared.convert(date)
                lunarText = LunarDateConverter.shared.format(lunarDate, format: config.lunarDateFormat)
            }
        }

        let dayTextSize = dayString.size(withAttributes: attributes)
        let spacer = " "
        let spacerSize = spacer.size(withAttributes: attributes)
        var totalTextWidth = dayTextSize.width

        var lunarAttributes: [NSAttributedString.Key: Any]?
        if let lunarText = lunarText {
            let lunarFontSize = config.style.dayFont.pointSize * config.style.lunarTextSize
            let lunarFont = NSFont.systemFont(ofSize: lunarFontSize, weight: .light)

            let isFestival = LunarDateConverter.shared.isFestival(lunarText)
            let isSolarTerm = LunarDateConverter.shared.isSolarTerm(lunarText)

            let lunarTextColor: NSColor
            if isToday {
                lunarTextColor = config.style.todayTextColor
            } else if isHoliday {
                lunarTextColor = config.style.todayTextColor
            } else if isFestival {
                lunarTextColor = config.style.lunarFestivalColor
            } else if isSolarTerm {
                lunarTextColor = config.style.lunarSolarTermColor
            } else {
                lunarTextColor = config.style.lunarDateColor
            }

            lunarAttributes = [
                .font: lunarFont,
                .foregroundColor: lunarTextColor
            ]

            let lunarTextSize = lunarText.size(withAttributes: lunarAttributes)
            totalTextWidth += spacerSize.width + lunarTextSize.width
        }

        let startX = cellX + (cellWidth - totalTextWidth) / 2

        let textRect = NSRect(
            x: startX,
            y: textY,
            width: dayTextSize.width,
            height: dayTextSize.height
        )
        dayString.draw(in: textRect, withAttributes: attributes)

        if let lunarText = lunarText, let lunarAttrs = lunarAttributes {
            let spacerRect = NSRect(
                x: startX + dayTextSize.width,
                y: textY,
                width: spacerSize.width,
                height: spacerSize.height
            )
            spacer.draw(in: spacerRect, withAttributes: attributes)

            let lunarTextSize = lunarText.size(withAttributes: lunarAttrs)
            let lunarRect = NSRect(
                x: startX + dayTextSize.width + spacerSize.width,
                y: textY + (font.pointSize - (config.style.dayFont.pointSize * config.style.lunarTextSize)) / 2,
                width: lunarTextSize.width,
                height: lunarTextSize.height
            )
            lunarText.draw(in: lunarRect, withAttributes: lunarAttrs)
        }
    }

    /// 绘制农历日期文本
    @MainActor
    static func drawLunarText(lunarText: String, cellX: CGFloat, cellY: CGFloat,
                               cellWidth: CGFloat, cellHeight: CGFloat,
                               config: CalendarConfig) {
        let fontSize = config.style.dayFont.pointSize * config.style.lunarTextSize
        let lunarFont = NSFont.systemFont(ofSize: fontSize, weight: .light)

        let isFestival = LunarDateConverter.shared.isFestival(lunarText)
        let isSolarTerm = LunarDateConverter.shared.isSolarTerm(lunarText)

        let textColor: NSColor
        if isFestival {
            textColor = config.style.lunarFestivalColor
        } else if isSolarTerm {
            textColor = config.style.lunarSolarTermColor
        } else {
            textColor = config.style.lunarDateColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: lunarFont,
            .foregroundColor: textColor
        ]

        let textSize = lunarText.size(withAttributes: attributes)
        let textRect = NSRect(
            x: cellX + (cellWidth - textSize.width) / 2,
            y: cellY + cellHeight * 0.25 - (fontSize / 2),
            width: textSize.width,
            height: textSize.height
        )

        lunarText.draw(in: textRect, withAttributes: attributes)
    }
}
