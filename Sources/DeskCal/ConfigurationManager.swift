// ConfigurationManager.swift
// DeskCal - macOS Desktop Calendar
// 配置文件管理器：负责加载、保存和应用用户配置

import AppKit
import Foundation

/// 配置中的今天高亮样式（可编码版本）
enum ConfigTodayHighlightStyle: Codable {
    case circle
    case roundedRect(cornerRadius: CGFloat)
    case underline(thickness: CGFloat)

    enum CodingKeys: String, CodingKey {
        case type
        case cornerRadius
        case thickness
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "circle":
            self = .circle
        case "roundedRect":
            let cornerRadius = try container.decode(CGFloat.self, forKey: .cornerRadius)
            self = .roundedRect(cornerRadius: cornerRadius)
        case "underline":
            let thickness = try container.decode(CGFloat.self, forKey: .thickness)
            self = .underline(thickness: thickness)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown highlight style type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .circle:
            try container.encode("circle", forKey: .type)
        case .roundedRect(let cornerRadius):
            try container.encode("roundedRect", forKey: .type)
            try container.encode(cornerRadius, forKey: .cornerRadius)
        case .underline(let thickness):
            try container.encode("underline", forKey: .type)
            try container.encode(thickness, forKey: .thickness)
        }
    }

    /// 转换为VisualStyle.TodayHighlightStyle
    func toVisualStyleHighlightStyle() -> VisualStyle.TodayHighlightStyle {
        switch self {
        case .circle:
            return .circle
        case .roundedRect(let cornerRadius):
            return .roundedRect(cornerRadius: cornerRadius)
        case .underline(let thickness):
            return .underline(thickness: thickness)
        }
    }
}

/// 应用程序配置
struct AppConfig: Codable {
    /// 主题类型
    enum Theme: String, Codable {
        case light
        case dark
        case auto
        case transparent
    }

    /// 日历模式
    enum CalendarMode: String, Codable {
        case month
        case year
    }

    /// 主题
    var theme: Theme = .auto

    /// 日历模式
    var calendarMode: CalendarMode = .year

    /// 是否显示周末颜色
    var showWeekendColors: Bool = true

    /// 是否显示月份分隔线
    var showMonthSeparators: Bool = true

    /// 是否显示年份标题
    var showYearTitle: Bool = true

    /// 背景透明度 (0.0 - 1.0)
    var backgroundAlpha: CGFloat = 0.85

    /// 是否在登录时自动启动（可选，缺失时默认为false）
    var launchAtLogin: Bool? = false

    /// 自定义颜色映射（颜色名称到十六进制字符串）
    var customColors: [String: String]?

    /// 今天高亮样式
    var todayHighlightStyle: ConfigTodayHighlightStyle?

    /// 是否显示农历日期
    var showLunarDate: Bool = false

    /// 农历日期格式
    enum LunarDateFormat: String, Codable {
        case short   // 初一/十五
        case full    // 三月初五
        case numeric // 3/5
    }

    /// 农历日期格式
    var lunarDateFormat: LunarDateFormat = .short

    /// 农历文字大小（相对于公历字体大小的比例）
    var lunarTextSize: CGFloat = 0.75

    /// 是否显示假期
    var showHolidays: Bool = false

    /// 假期缓存有效期（天）
    var holidayCacheDays: Int = 30

    /// 假期高亮样式
    enum HolidayHighlightStyle: String, Codable {
        case background // 背景色
        case border    // 边框
        case icon      // 图标
    }

    /// 假期高亮样式
    var holidayHighlightStyle: HolidayHighlightStyle = .background

    /// 是否为所有屏幕设置墙纸（默认 true）
    var setWallpaperForAllScreens: Bool = true

    /// 默认配置
    static let `default` = AppConfig()

    /// 从配置文件加载
    /// - Parameter url: 配置文件URL
    /// - Returns: 加载的配置，如果失败则返回默认配置
    @MainActor
    static func load(from url: URL) -> AppConfig {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let config = try decoder.decode(AppConfig.self, from: data)
            logInfo("Configuration loaded from \(url.path)")
            return config
        } catch {
            logWarning("Failed to load configuration from \(url.path): \(error). Using default configuration.")
            return .default
        }
    }

    /// 保存配置到文件
    /// - Parameter url: 配置文件URL
    @MainActor
    func save(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(self)
        try data.write(to: url)
        logInfo("Configuration saved to \(url.path)")
    }

    /// 转换为VisualStyle
    /// - Returns: 根据配置生成的VisualStyle
    @MainActor
    func toVisualStyle() -> VisualStyle {
        let baseStyle: VisualStyle

        switch theme {
        case .light:
            baseStyle = .lightTheme()
        case .dark:
            baseStyle = .darkTheme()
        case .auto:
            baseStyle = .autoTheme()
        case .transparent:
            baseStyle = .transparentTheme()
        }

        // 应用自定义颜色（如果提供）
        var modifiedStyle = baseStyle
        modifiedStyle.showMonthSeparators = showMonthSeparators
        modifiedStyle.showYearTitle = showYearTitle
        modifiedStyle.backgroundAlpha = backgroundAlpha

        // 应用自定义颜色映射
        if let customColors = customColors {
            modifiedStyle = applyCustomColors(customColors, to: modifiedStyle)
        }

        // 应用今天高亮样式（如果提供）
        if let todayHighlightStyle = todayHighlightStyle {
            modifiedStyle.todayHighlightStyle = todayHighlightStyle.toVisualStyleHighlightStyle()
        }

        // 处理是否显示周末颜色
        if !showWeekendColors {
            modifiedStyle.weekendTextColor = modifiedStyle.dayTextColor
        }

        // 应用农历配置
        modifiedStyle.showLunarDate = showLunarDate
        modifiedStyle.lunarTextSize = lunarTextSize

        // 应用假期配置
        modifiedStyle.showHolidays = showHolidays

        return modifiedStyle
    }

    /// 应用自定义颜色到样式
    @MainActor
    private func applyCustomColors(_ colorMap: [String: String], to style: VisualStyle) -> VisualStyle {
        var modifiedStyle = style

        for (colorName, hexString) in colorMap {
            guard let color = NSColor.fromHex(hexString) else {
                logWarning("Invalid color hex string for \(colorName): \(hexString)")
                continue
            }

            // 支持驼峰和下划线两种命名方式
            let normalizedKey = colorName.replacingOccurrences(of: "_", with: "").lowercased()

            switch normalizedKey {
            case "backgroundcolor":
                modifiedStyle.backgroundColor = color
            case "monthtitlecolor":
                modifiedStyle.monthTitleColor = color
            case "weekdaytitlecolor":
                modifiedStyle.weekdayTitleColor = color
            case "daytextcolor":
                modifiedStyle.dayTextColor = color
            case "weekendtextcolor":
                modifiedStyle.weekendTextColor = color
            case "todayhighlightcolor":
                modifiedStyle.todayHighlightColor = color
            case "todaytextcolor":
                modifiedStyle.todayTextColor = color
            case "monthseparatorcolor":
                modifiedStyle.monthSeparatorColor = color
            case "yeartitlecolor":
                modifiedStyle.yearTitleColor = color
            case "lunardatecolor":
                modifiedStyle.lunarDateColor = color
            case "lunarfestivalcolor":
                modifiedStyle.lunarFestivalColor = color
            case "lunarsolarmtermcolor", "lunarsolartermcolor":
                modifiedStyle.lunarSolarTermColor = color
            case "holidaybackgroundcolor":
                modifiedStyle.holidayBackgroundColor = color
            case "holidaytextcolor":
                modifiedStyle.holidayTextColor = color
            case "holidaybordercolor":
                modifiedStyle.holidayBorderColor = color
            default:
                logWarning("Unknown color name: \(colorName)")
            }
        }

        return modifiedStyle
    }
}

/// 配置管理器单例
@MainActor
class ConfigurationManager {
    static let shared = ConfigurationManager()

    /// 自定义配置文件URL（如果设置，则覆盖默认路径）
    static var customConfigURL: URL?

    /// 当前配置
    private(set) var config: AppConfig

    /// 配置文件URL
    private let configURL: URL

    private init() {
        // 确定配置文件路径
        let fileManager = FileManager.default
        if let customURL = ConfigurationManager.customConfigURL {
            self.configURL = customURL
            logInfo("Using custom config URL: \(customURL.path)")
        } else {
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let deskcalURL = appSupportURL.appendingPathComponent("DeskCal")
            self.configURL = deskcalURL.appendingPathComponent("config.json")
            logInfo("Using default config URL: \(self.configURL.path)")

            // 确保目录存在
            if !fileManager.fileExists(atPath: deskcalURL.path) {
                try? fileManager.createDirectory(at: deskcalURL, withIntermediateDirectories: true)
            }
        }

        // 加载配置
        if fileManager.fileExists(atPath: configURL.path) {
            self.config = AppConfig.load(from: configURL)
        } else {
            // 使用默认配置
            self.config = .default
            // 尝试保存默认配置
            try? config.save(to: configURL)
        }

        logInfo("ConfigurationManager initialized with config from \(configURL.path)")
    }

    /// 重新加载配置
    func reload() {
        if FileManager.default.fileExists(atPath: configURL.path) {
            config = AppConfig.load(from: configURL)
        } else {
            config = .default
        }
    }

    /// 保存当前配置
    func save() throws {
        try config.save(to: configURL)
    }

    /// 更新配置
    /// - Parameter newConfig: 新的配置
    func update(with newConfig: AppConfig) throws {
        config = newConfig
        try save()
    }

    /// 获取日历配置
    /// - Parameters:
    ///   - width: 图片宽度
    ///   - height: 图片高度
    /// - Returns: 日历配置
    func getCalendarConfig(width: CGFloat, height: CGFloat) -> CalendarConfig {
        let visualStyle = config.toVisualStyle()
        let lunarFormat = config.lunarDateFormat.rawValue
        return CalendarConfig(width: width, height: height, style: visualStyle, lunarDateFormat: lunarFormat)
    }
}

// MARK: - NSColor扩展（十六进制颜色支持）

extension NSColor {
    /// 从十六进制字符串创建颜色
    /// - Parameter hex: 十六进制颜色字符串（例如 "#RRGGBB" 或 "#RRGGBBAA"）
    /// - Returns: NSColor对象，如果字符串无效则返回nil
    static func fromHex(_ hex: String) -> NSColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 移除 "#" 前缀
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }

        // 验证长度
        guard hexString.count == 6 || hexString.count == 8 else {
            return nil
        }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        if hexString.count == 6 {
            // RGB格式
            return NSColor(
                red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else {
            // RGBA格式
            return NSColor(
                red: CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgbValue & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgbValue & 0x000000FF) / 255.0
            )
        }
    }
}

// MARK: - 日志快捷方法

@MainActor
private func logInfo(_ message: String) {
    Logger.shared.info("[ConfigurationManager] \(message)")
}

@MainActor
private func logWarning(_ message: String) {
    Logger.shared.warning("[ConfigurationManager] \(message)")
}