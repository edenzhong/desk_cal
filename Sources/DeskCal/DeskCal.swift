// DeskCal - macOS Desktop Calendar
// Main entry point for the DeskCal application

import AppKit
import Foundation

extension NSScreen {
    var displayID: CGDirectDisplayID? {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }
}

@MainActor
@main
struct DeskCal {
    static func main() {
        // 初始化日志系统（默认输出到控制台）
        Logger.shared.initialize(destinations: .console, logToFile: true)
        logInfo("DeskCal starting...")

        // 解析命令行参数
        let arguments = CommandLine.arguments
        var mode: CalendarMode = .year  // 默认全年日历
        var testOnly: Bool = false
        var daemonMode: Bool = false
        var updateOnly: Bool = false
        var checkOnly: Bool = false
        var showStatus: Bool = false

        for i in 1..<arguments.count {
            let arg = arguments[i]
            switch arg {
            case "--month", "-m":
                mode = .month
            case "--year", "-y":
                mode = .year
            case "--test", "-t":
                testOnly = true
            case "--daemon", "-d":
                daemonMode = true
            case "--update", "-u":
                updateOnly = true
            case "--check", "-c":
                checkOnly = true
            case "--status":
                showStatus = true
            case "--help", "-h":
                printHelp()
                exit(0)
            default:
                logWarning("Unknown argument: \(arg)")
                printHelp()
                exit(1)
            }
        }

        // 处理互斥选项
        let actionCount = [daemonMode, updateOnly, checkOnly, showStatus, testOnly].filter { $0 }.count
        if actionCount > 1 {
            logError("Conflicting options specified. Only one of --daemon, --update, --check, --status, --test can be used at a time.")
            printHelp()
            exit(1)
        }

        // 执行相应操作
        if daemonMode {
            // 守护进程模式：执行启动检查并退出（实际由launchd定时触发）
            performLaunchCheck(mode: mode)
        } else if updateOnly {
            // 强制立即更新
            forceUpdate(mode: mode)
        } else if checkOnly {
            // 只检查不更新
            checkUpdate(mode: mode)
        } else if showStatus {
            // 显示状态
            showStatusInfo()
        } else if testOnly {
            // 测试模式
            performTest(mode: mode)
        } else {
            // 默认行为：执行启动检查并更新（如果 needed）
            performLaunchCheck(mode: mode)
        }
    }

    // MARK: - 操作处理

    /// 执行启动检查并更新（如果需要）
    private static func performLaunchCheck(mode: CalendarMode) {
        logInfo("Performing launch check...")

        let updated = UpdateScheduler.checkAndUpdateIfNeeded(mode: mode)
        if updated {
            logInfo("Launch check completed: update performed")
        } else {
            logInfo("Launch check completed: no update needed")
        }
    }

    /// 强制立即更新
    private static func forceUpdate(mode: CalendarMode) {
        logInfo("Forcing immediate update...")

        let success = UpdateScheduler.forceUpdate(mode: mode)
        if success {
            logInfo("Force update completed successfully")
        } else {
            logError("Force update failed")
            exit(1)
        }
    }

    /// 检查更新（只检查不执行）
    private static func checkUpdate(mode: CalendarMode) {
        logInfo("Checking update status...")

        let lastUpdateDate = UpdateScheduler.getLastUpdateDate()
        let didFail = UpdateScheduler.didLastUpdateFail()
        let lastError = UpdateScheduler.getLastUpdateError()

        if let lastUpdate = lastUpdateDate {
            let calendar = Calendar.current
            if calendar.isDateInToday(lastUpdate) {
                print("Status: Up to date (last update: \(lastUpdate))")
            } else {
                print("Status: Needs update (last update: \(lastUpdate))")
            }
        } else {
            print("Status: Never updated")
        }

        if didFail {
            print("Last update failed: \(lastError ?? "Unknown error")")
        }
    }

    /// 执行测试（保存图片到桌面）
    private static func performTest(mode: CalendarMode) {
        logInfo("Running in test mode (mode: \(mode.rawValue))...")

        do {
            // 生成日历图片
            let image = try generateCalendarImage(mode: mode)

            // 保存到桌面
            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let desktopFileURL = desktopURL.appendingPathComponent("deskcal-test-\(mode.rawValue).png")

            // 删除已存在的文件
            if FileManager.default.fileExists(atPath: desktopFileURL.path) {
                try FileManager.default.removeItem(at: desktopFileURL)
            }

            // 保存图片
            try saveImageToFile(image, url: desktopFileURL)
            logInfo("Test image saved to desktop: \(desktopFileURL.path)")

        } catch {
            logError("Failed to generate test image: \(error)")
            exit(1)
        }
    }

    /// 显示状态信息
    private static func showStatusInfo() {
        let lastUpdateDate = UpdateScheduler.getLastUpdateDate()
        let didFail = UpdateScheduler.didLastUpdateFail()
        let lastError = UpdateScheduler.getLastUpdateError()
        let hasPermission = WallpaperManager.hasPermission()

        print("""
        DeskCal Status:
        - Last update: \(lastUpdateDate?.description ?? "Never")
        - Last update failed: \(didFail ? "Yes" : "No")
        \(didFail ? "- Last error: \(lastError ?? "Unknown")" : "")
        - Wallpaper permission: \(hasPermission ? "Granted" : "Not granted")
        - Screen count: \(NSScreen.screens.count)
        - Main screen: \(NSScreen.main?.frame.size.debugDescription ?? "Not available")
        """)
    }

    // MARK: - 图片生成（用于测试模式）

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

        // 创建日历生成器配置
        let config = CalendarConfig.default(width: width, height: height)
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

    /// 保存图片到文件
    private static func saveImageToFile(_ image: NSImage, url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw WallpaperManagerError.imageConversionFailed
        }

        try pngData.write(to: url)
    }

    // MARK: - 帮助信息

    static func printHelp() {
        print("""
        DeskCal - macOS Desktop Calendar

        Usage:
          DeskCal [options]

        Options:
          -m, --month     Generate single month calendar (default: year)
          -y, --year      Generate year calendar (12 months)
          -t, --test      Test mode: save image to desktop instead of setting wallpaper
          -d, --daemon    Perform launch check and update if needed (for launchd)
          -u, --update    Force immediate wallpaper update
          -c, --check     Check update status without updating
          --status        Show detailed status information
          -h, --help      Show this help message

        Examples:
          DeskCal --year                # Check and update if needed (default)
          DeskCal --month               # Check and update with single month calendar
          DeskCal --year --test         # Generate year calendar and save to desktop
          DeskCal --update --month      # Force update with single month calendar
          DeskCal --check               # Check update status
          DeskCal --status              # Show detailed status

        Launchd Integration:
          - Install com.deskcal.plist to ~/Library/LaunchAgents/
          - launchd will run DeskCal --daemon --year daily at midnight
          - On launch, DeskCal checks if update is needed (if computer was off at midnight)
        """)
    }
}
