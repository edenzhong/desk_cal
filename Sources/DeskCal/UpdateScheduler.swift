// UpdateScheduler.swift
// DeskCal - macOS Desktop Calendar
// 更新调度器：负责启动时检查和记录更新状态

import AppKit
import Foundation

/// 日历模式
enum CalendarMode: String {
    case month = "month"
    case year = "year"
}

/// 更新调度器
@MainActor
struct UpdateScheduler {

    /// 检查并执行必要的更新
    /// - Parameter mode: 日历模式
    /// - Returns: 如果执行了更新返回true，否则返回false
    static func checkAndUpdateIfNeeded(mode: CalendarMode) -> Bool {
        logInfo("Checking if update is needed...")

        let lastUpdateDate = getLastUpdateDate()
        let calendar = Calendar.current
        let now = Date()

        if let lastUpdate = lastUpdateDate {
            if calendar.isDateInToday(lastUpdate) {
                logInfo("Last update was today (\(lastUpdate)), skipping update")
                return false
            } else {
                logInfo("Last update was not today (\(lastUpdate)), performing update")
                return performUpdate(mode: mode)
            }
        } else {
            logInfo("No previous update found, performing initial update")
            return performUpdate(mode: mode)
        }
    }

    /// 强制立即更新
    /// - Parameter mode: 日历模式
    /// - Returns: 更新是否成功
    static func forceUpdate(mode: CalendarMode) -> Bool {
        logInfo("Forcing immediate update (mode: \(mode.rawValue))")
        return performUpdate(mode: mode)
    }

    /// 获取上次更新日期
    /// - Returns: 上次更新日期，如果从未更新则返回nil
    static func getLastUpdateDate() -> Date? {
        if let dateData = UserDefaults.standard.data(forKey: "LastWallpaperUpdateDate"),
           let date = try? JSONDecoder().decode(Date.self, from: dateData) {
            return date
        }
        return nil
    }

    /// 记录更新成功
    static func recordUpdateSuccess() {
        let now = Date()
        if let dateData = try? JSONEncoder().encode(now) {
            UserDefaults.standard.set(dateData, forKey: "LastWallpaperUpdateDate")
            UserDefaults.standard.set(false, forKey: "LastUpdateFailed")
            UserDefaults.standard.synchronize()
            logInfo("Recorded successful update at \(now)")
        }
    }

    /// 记录更新失败
    static func recordUpdateFailure(error: Error) {
        UserDefaults.standard.set(true, forKey: "LastUpdateFailed")
        UserDefaults.standard.set(error.localizedDescription, forKey: "LastUpdateError")
        UserDefaults.standard.synchronize()
        logError("Recorded update failure: \(error)")
    }

    /// 检查上次更新是否失败
    /// - Returns: 如果上次更新失败返回true
    static func didLastUpdateFail() -> Bool {
        return UserDefaults.standard.bool(forKey: "LastUpdateFailed")
    }

    /// 获取上次更新错误信息
    /// - Returns: 错误描述，如果没有则返回nil
    static func getLastUpdateError() -> String? {
        return UserDefaults.standard.string(forKey: "LastUpdateError")
    }

    // MARK: - 私有方法

    /// 执行更新
    private static func performUpdate(mode: CalendarMode) -> Bool {
        logInfo("Performing wallpaper update (mode: \(mode.rawValue))")

        do {
            // 生成日历图片
            let image = try generateCalendarImage(mode: mode)

            // 设置墙纸
            try WallpaperManager.setWallpaper(image: image)

            // 记录成功
            recordUpdateSuccess()
            logInfo("Wallpaper update completed successfully")
            return true

        } catch {
            logError("Failed to update wallpaper: \(error)")
            recordUpdateFailure(error: error)
            return false
        }
    }

    /// 生成日历图片
    private static func generateCalendarImage(mode: CalendarMode) throws -> NSImage {
        logInfo("Generating calendar image (mode: \(mode.rawValue))")

        // 获取屏幕尺寸
        guard let mainScreen = NSScreen.main else {
            throw WallpaperManagerError.noMainScreen
        }

        let screenSize = mainScreen.frame.size
        let width = screenSize.width
        let height = screenSize.height

        logInfo("Screen size: \(width)x\(height)")

        // 使用配置管理器获取日历配置
        let config = ConfigurationManager.shared.getCalendarConfig(width: width, height: height)
        let generator = CalendarGenerator(config: config)

        // 获取当前日期
        let (year, month) = DateCalculator.currentYearAndMonth()
        let (_, todayMonth, todayDay) = DateCalculator.today()

        // 根据模式生成图片
        switch mode {
        case .month:
            logInfo("Generating single month calendar for \(DateCalculator.monthName(for: month)) \(year)")
            return try generator.generateMonthCalendar(year: year, month: month, todayDay: todayDay)

        case .year:
            logInfo("Generating year calendar for \(year)")
            return try generator.generateYearCalendar(
                year: year,
                todayDate: (month: todayMonth, day: todayDay)
            )
        }
    }

    // MARK: - 日志快捷方法

    private static func logInfo(_ message: String) {
        Logger.shared.info("[UpdateScheduler] \(message)")
    }

    private static func logError(_ message: String) {
        Logger.shared.error("[UpdateScheduler] \(message)")
    }

    private static func logError(_ error: Error) {
        Logger.shared.error("[UpdateScheduler] \(error)")
    }
}