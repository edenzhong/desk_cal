// HolidayService.swift
// DeskCal - macOS Desktop Calendar
// 假期服务：处理中国法定假日数据获取和缓存

import AppKit
import Foundation

/// 假期信息
public struct HolidayInfo: Codable, Sendable {
    /// 假期日期（YYYY-MM-DD格式）
    public let date: String
    /// 假期名称
    public let name: String
    /// 是否是假期
    public let isHoliday: Bool
    /// 是否是调休日（工作日）
    public let isWorkday: Bool

    public init(date: String, name: String, isHoliday: Bool, isWorkday: Bool) {
        self.date = date
        self.name = name
        self.isHoliday = isHoliday
        self.isWorkday = isWorkday
    }
}

/// 假期数据
public struct HolidayData: Codable, Sendable {
    /// 年份
    public let year: Int
    /// 假期列表
    public let holidays: [HolidayInfo]
    /// 最后更新时间
    public let lastUpdated: Date

    public init(year: Int, holidays: [HolidayInfo], lastUpdated: Date = Date()) {
        self.year = year
        self.holidays = holidays
        self.lastUpdated = lastUpdated
    }
}

/// 假期服务
public actor HolidayService {
    // MARK: - 单例

    public static let shared = HolidayService()

    // MARK: - 私有属性

    /// 假期数据缓存（按年份存储）
    private var cache: [Int: HolidayData] = [:]

    /// 缓存有效期（天）
    private let cacheValidityDays: Int

    /// 缓存文件URL
    private let cacheDirectory: URL

    /// 是否启用API请求
    private let enableAPI: Bool

    // MARK: - 初始化

    public init(cacheValidityDays: Int = 30, enableAPI: Bool = true) {
        self.cacheValidityDays = cacheValidityDays
        self.enableAPI = enableAPI

        // 设置缓存目录
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.cacheDirectory = appSupportURL.appendingPathComponent("DeskCal/HolidayCache")

        // 确保缓存目录存在
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - 公共方法

    /// 获取指定日期的假期信息
    /// - Parameter date: 日期
    /// - Returns: 假期信息，如果不是假期则返回nil
    public func getHoliday(for date: Date) -> HolidayInfo? {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)

        // 获取该年份的假期数据
        guard let holidayData = getHolidayData(for: year) else {
            return nil
        }

        // 格式化日期
        let dateString = formatDate(date)

        // 查找假期信息
        return holidayData.holidays.first { $0.date == dateString }
    }

    /// 检查指定日期是否是假期
    /// - Parameter date: 日期
    /// - Returns: 是否是假期
    public func isHoliday(_ date: Date) -> Bool {
        return getHoliday(for: date)?.isHoliday ?? false
    }

    /// 同步检查指定日期是否是假期（用于绘图）
    /// - Parameter date: 日期
    /// - Returns: 是否是假期
    nonisolated public func isHolidaySync(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        // 直接检查内置假期数据（避免并发问题）
        switch year {
        case 2025:
            let dateString = String(format: "%04d-%02d-%02d", year, month, day)
            return Self.builtin2025Holidays.contains { $0.date == dateString && $0.isHoliday }
        case 2026:
            let dateString = String(format: "%04d-%02d-%02d", year, month, day)
            return Self.builtin2026Holidays.contains { $0.date == dateString && $0.isHoliday }
        default:
            return false
        }
    }

    /// 检查指定日期是否是调休日（工作日）
    /// - Parameter date: 日期
    /// - Returns: 是否是调休日
    public func isWorkday(_ date: Date) -> Bool {
        return getHoliday(for: date)?.isWorkday ?? false
    }

    /// 获取指定年份的所有假期
    /// - Parameter year: 年份
    /// - Returns: 假期列表
    public func getHolidays(for year: Int) -> [HolidayInfo] {
        guard let holidayData = getHolidayData(for: year) else {
            return []
        }
        return holidayData.holidays.filter { $0.isHoliday }
    }

    /// 手动刷新指定年份的假期数据
    /// - Parameter year: 年份
    public func refresh(for year: Int) async {
        // 清除缓存
        cache.removeValue(forKey: year)
        // 重新加载数据
        _ = getHolidayData(for: year, forceRefresh: true)
    }

    // MARK: - 私有方法

    /// 获取指定年份的假期数据
    /// - Parameters:
    ///   - year: 年份
    ///   - forceRefresh: 是否强制刷新
    /// - Returns: 假期数据
    private func getHolidayData(for year: Int, forceRefresh: Bool = false) -> HolidayData? {
        // 检查内存缓存
        if let cachedData = cache[year] {
            // 检查缓存是否过期
            if !forceRefresh && !isCacheExpired(cachedData) {
                logInfo("Using cached holiday data for year \(year)")
                return cachedData
            }
        }

        // 尝试从文件加载缓存
        if let fileData = loadFromFile(for: year), !forceRefresh {
            if !isCacheExpired(fileData) {
                cache[year] = fileData
                logInfo("Loaded holiday data from file for year \(year)")
                return fileData
            }
        }

        // 尝试从API获取
        if enableAPI {
            if let apiData = fetchFromAPI(for: year) {
                cache[year] = apiData
                saveToFile(apiData, for: year)
                logInfo("Fetched holiday data from API for year \(year)")
                return apiData
            }
        }

        // 使用内置的假期数据作为降级策略
        if let builtinData = getBuiltinHolidayData(for: year) {
            cache[year] = builtinData
            logInfo("Using builtin holiday data for year \(year)")
            return builtinData
        }

        logWarning("Failed to get holiday data for year \(year)")
        return nil
    }

    /// 检查缓存是否过期
    /// - Parameter data: 假期数据
    /// - Returns: 是否过期
    private func isCacheExpired(_ data: HolidayData) -> Bool {
        let daysSinceUpdate = Date().timeIntervalSince(data.lastUpdated) / 86400
        return daysSinceUpdate > Double(cacheValidityDays)
    }

    /// 从文件加载假期数据
    /// - Parameter year: 年份
    /// - Returns: 假期数据
    private func loadFromFile(for year: Int) -> HolidayData? {
        let fileURL = cacheDirectory.appendingPathComponent("holidays_\(year).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let holidayData = try decoder.decode(HolidayData.self, from: data)
            return holidayData
        } catch {
            logWarning("Failed to load holiday data from file: \(error)")
            return nil
        }
    }

    /// 保存假期数据到文件
    /// - Parameters:
    ///   - data: 假期数据
    ///   - year: 年份
    private func saveToFile(_ data: HolidayData, for year: Int) {
        let fileURL = cacheDirectory.appendingPathComponent("holidays_\(year).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: fileURL)
            logInfo("Saved holiday data to file for year \(year)")
        } catch {
            logWarning("Failed to save holiday data to file: \(error)")
        }
    }

    /// 从API获取假期数据
    /// - Parameter year: 年份
    /// - Returns: 假期数据
    private func fetchFromAPI(for year: Int) -> HolidayData? {
        // 注意：实际使用时需要替换为真实的API端点
        // 这里提供一个示例，实际API可能需要认证或有不同的响应格式

        // 使用timor.tech的假期API（示例）
        let urlString = "https://timor.tech/api/holiday/\(year)"
        guard let url = URL(string: urlString) else {
            return nil
        }

        let semaphore = DispatchSemaphore(value: 0)
        var result: HolidayData?

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }

            guard error == nil, let data = data else {
                logWarning("Failed to fetch holiday data from API: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            do {
                // 这里需要根据实际API响应格式进行解析
                // 以下是示例代码，需要根据实际API调整
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let holiday = json["holiday"] as? [String: Any] {

                    var holidays: [HolidayInfo] = []

                    // 解析假期数据
                    for (date, info) in holiday {
                        if let holidayInfo = info as? [String: Any] {
                            let name = holidayInfo["holiday"] as? Bool == true
                                ? (holidayInfo["name"] as? String ?? "假期")
                                : ""
                            let isHoliday = holidayInfo["holiday"] as? Bool ?? false
                            let isWorkday = holidayInfo["work"] as? Bool ?? false

                            holidays.append(HolidayInfo(
                                date: date,
                                name: name,
                                isHoliday: isHoliday,
                                isWorkday: isWorkday
                            ))
                        }
                    }

                    result = HolidayData(year: year, holidays: holidays)
                }
            } catch {
                logWarning("Failed to parse holiday data from API: \(error)")
            }
        }

        task.resume()
        semaphore.wait()

        return result
    }

    /// 获取内置的假期数据（降级策略）
    /// - Parameter year: 年份
    /// - Returns: 假期数据
    private func getBuiltinHolidayData(for year: Int) -> HolidayData? {
        switch year {
        case 2025:
            return HolidayData(year: 2025, holidays: Self.builtin2025Holidays)
        case 2026:
            return HolidayData(year: 2026, holidays: Self.builtin2026Holidays)
        default:
            // 对于其他年份，返回空数据
            return HolidayData(year: year, holidays: [])
        }
    }

    /// 格式化日期为YYYY-MM-DD
    /// - Parameter date: 日期
    /// - Returns: 格式化后的字符串
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar.current
        return formatter.string(from: date)
    }

    // MARK: - 内置假期数据

    /// 2025年假期数据（示例数据，需要根据官方发布的假期安排更新）
    private static let builtin2025Holidays: [HolidayInfo] = [
        // 元旦
        HolidayInfo(date: "2025-01-01", name: "元旦", isHoliday: true, isWorkday: false),
        // 春节（示例数据）
        HolidayInfo(date: "2025-01-28", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-01-29", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-01-30", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-01-31", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-02-01", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-02-02", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-02-03", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-02-04", name: "春节", isHoliday: true, isWorkday: false),
        // 调休日（示例）
        HolidayInfo(date: "2025-01-26", name: "春节调休", isHoliday: false, isWorkday: true),
        HolidayInfo(date: "2025-02-08", name: "春节调休", isHoliday: false, isWorkday: true),
        // 清明节（示例）
        HolidayInfo(date: "2025-04-04", name: "清明节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-04-05", name: "清明节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-04-06", name: "清明节", isHoliday: true, isWorkday: false),
        // 劳动节（示例）
        HolidayInfo(date: "2025-05-01", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-05-02", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-05-03", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-05-04", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-05-05", name: "劳动节", isHoliday: true, isWorkday: false),
        // 端午节（示例）
        HolidayInfo(date: "2025-05-31", name: "端午节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-06-01", name: "端午节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-06-02", name: "端午节", isHoliday: true, isWorkday: false),
        // 中秋节（示例）
        HolidayInfo(date: "2025-10-06", name: "中秋节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-07", name: "中秋节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-08", name: "中秋节", isHoliday: true, isWorkday: false),
        // 国庆节（示例）
        HolidayInfo(date: "2025-10-01", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-02", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-03", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-04", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-05", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-06", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2025-10-07", name: "国庆节", isHoliday: true, isWorkday: false),
    ]

    /// 2026年假期数据（示例数据，需要根据官方发布的假期安排更新）
    private static let builtin2026Holidays: [HolidayInfo] = [
        // 元旦
        HolidayInfo(date: "2026-01-01", name: "元旦", isHoliday: true, isWorkday: false),
        // 春节（示例数据，需根据官方日期更新）
        HolidayInfo(date: "2026-02-16", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-02-17", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-02-18", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-02-19", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-02-20", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-02-21", name: "春节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-02-22", name: "春节", isHoliday: true, isWorkday: false),
        // 清明节
        HolidayInfo(date: "2026-04-04", name: "清明节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-04-05", name: "清明节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-04-06", name: "清明节", isHoliday: true, isWorkday: false),
        // 劳动节
        HolidayInfo(date: "2026-05-01", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-05-02", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-05-03", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-05-04", name: "劳动节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-05-05", name: "劳动节", isHoliday: true, isWorkday: false),
        // 端午节
        HolidayInfo(date: "2026-06-19", name: "端午节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-06-20", name: "端午节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-06-21", name: "端午节", isHoliday: true, isWorkday: false),
        // 中秋节
        HolidayInfo(date: "2026-09-25", name: "中秋节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-09-26", name: "中秋节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-09-27", name: "中秋节", isHoliday: true, isWorkday: false),
        // 国庆节
        HolidayInfo(date: "2026-10-01", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-10-02", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-10-03", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-10-04", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-10-05", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-10-06", name: "国庆节", isHoliday: true, isWorkday: false),
        HolidayInfo(date: "2026-10-07", name: "国庆节", isHoliday: true, isWorkday: false),
    ]
}

// MARK: - 日志快捷方法

nonisolated private func logInfo(_ message: String) {
    DispatchQueue.main.async {
        Logger.shared.info("[HolidayService] \(message)")
    }
}

nonisolated private func logWarning(_ message: String) {
    DispatchQueue.main.async {
        Logger.shared.warning("[HolidayService] \(message)")
    }
}
