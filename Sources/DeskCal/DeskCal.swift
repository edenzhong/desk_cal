// DeskCal - macOS Desktop Calendar
// Main entry point for the DeskCal application

import AppKit
import CoreServices
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
        var modeSpecified = false       // 用户是否指定了模式
        var testOnly: Bool = false
        var daemonMode: Bool = false
        var updateOnly: Bool = false
        var checkOnly: Bool = false
        var showStatus: Bool = false
        var installService: Bool = false
        var uninstallService: Bool = false
        var startService: Bool = false
        var stopService: Bool = false
        var serviceStatus: Bool = false
        var addLoginItem: Bool = false
        var removeLoginItem: Bool = false
        var configPath: String? = nil

        var index = 1
        while index < arguments.count {
            let arg = arguments[index]
            switch arg {
            case "--month", "-m":
                mode = .month
                modeSpecified = true
            case "--year", "-y":
                mode = .year
                modeSpecified = true
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
            case "--install-service":
                installService = true
            case "--uninstall-service":
                uninstallService = true
            case "--start-service":
                startService = true
            case "--stop-service":
                stopService = true
            case "--service-status":
                serviceStatus = true
            case "--add-login-item":
                addLoginItem = true
            case "--remove-login-item":
                removeLoginItem = true
            case "--help", "-h":
                printHelp()
                exit(0)
            case "--config":
                // 需要下一个参数作为配置文件路径
                if index + 1 < arguments.count {
                    configPath = arguments[index + 1]
                    // 跳过下一个参数
                    index += 1
                } else {
                    logError("--config requires a file path")
                    printHelp()
                    exit(1)
                }
            default:
                logWarning("Unknown argument: \(arg)")
                printHelp()
                exit(1)
            }
            index += 1
        }

        // 设置自定义配置文件路径（如果提供）
        if let configPath = configPath {
            let configURL = URL(fileURLWithPath: (configPath as NSString).expandingTildeInPath)
            ConfigurationManager.customConfigURL = configURL
            logInfo("Using custom config file: \(configURL.path)")
        }

        // 如果没有指定模式，使用配置中的模式
        if !modeSpecified {
            let configMode = ConfigurationManager.shared.config.calendarMode
            mode = configMode == .month ? .month : .year
            logInfo("Using calendar mode from configuration: \(mode.rawValue)")
        }

        // 处理互斥选项
        let actionCount = [daemonMode, updateOnly, checkOnly, showStatus, testOnly, installService, uninstallService, startService, stopService, serviceStatus, addLoginItem, removeLoginItem].filter { $0 }.count
        if actionCount > 1 {
            logError("Conflicting options specified. Only one of --daemon, --update, --check, --status, --test, --install-service, --uninstall-service, --start-service, --stop-service, --service-status, --add-login-item, --remove-login-item can be used at a time.")
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
        } else if installService {
            // 安装服务
            installLaunchdService(mode: mode)
        } else if uninstallService {
            // 卸载服务
            uninstallLaunchdService()
        } else if startService {
            // 启动服务
            startLaunchdService()
        } else if stopService {
            // 停止服务
            stopLaunchdService()
        } else if serviceStatus {
            // 检查服务状态
            checkLaunchdServiceStatus()
        } else if addLoginItem {
            // 添加到登录项
            addToLoginItems()
        } else if removeLoginItem {
            // 从登录项移除
            removeFromLoginItems()
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

    /// 保存图片到文件
    private static func saveImageToFile(_ image: NSImage, url: URL) throws {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw WallpaperManagerError.imageConversionFailed
        }

        try pngData.write(to: url)
    }

    // MARK: - 服务管理

    /// 安装 launchd 服务
    private static func installLaunchdService(mode: CalendarMode) {
        logInfo("Installing launchd service...")

        let fileManager = FileManager.default

        // 获取可执行文件路径
        let executablePath: String
        if let bundleExecutableURL = Bundle.main.executableURL {
            executablePath = bundleExecutableURL.path
        } else {
            // 回退到命令行参数中的路径
            let arg0 = CommandLine.arguments[0]
            if arg0.hasPrefix("/") {
                // 已经是绝对路径
                executablePath = arg0
            } else {
                // 转换为当前工作目录的绝对路径
                let currentDirectory = fileManager.currentDirectoryPath
                executablePath = (currentDirectory as NSString).appendingPathComponent(arg0)
            }
        }

        logInfo("Using executable path: \(executablePath)")

        let launchAgentsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")

        do {
            if !fileManager.fileExists(atPath: launchAgentsURL.path) {
                try fileManager.createDirectory(at: launchAgentsURL, withIntermediateDirectories: true)
            }

            let destinationURL = launchAgentsURL.appendingPathComponent("com.deskcal.plist")

            // 生成plist内容
            let plistContent = generateLaunchdPlist(executablePath: executablePath, mode: mode)

            // 写入plist文件
            try plistContent.write(to: destinationURL, atomically: true, encoding: .utf8)
            logInfo("Plist generated and saved to \(destinationURL.path)")

            // 加载服务
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            process.arguments = ["load", destinationURL.path]
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                logInfo("Service installed and loaded successfully")
            } else {
                logError("Failed to load service (exit code: \(process.terminationStatus))")
                exit(1)
            }
        } catch {
            logError("Failed to install service: \(error)")
            exit(1)
        }
    }

    /// 卸载 launchd 服务
    private static func uninstallLaunchdService() {
        logInfo("Uninstalling launchd service...")

        let fileManager = FileManager.default
        let launchAgentsURL = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        let plistURL = launchAgentsURL.appendingPathComponent("com.deskcal.plist")

        do {
            // 如果服务已加载，先卸载
            if fileManager.fileExists(atPath: plistURL.path) {
                let unloadProcess = Process()
                unloadProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                unloadProcess.arguments = ["unload", plistURL.path]
                try unloadProcess.run()
                unloadProcess.waitUntilExit()
            }

            // 删除 plist 文件
            if fileManager.fileExists(atPath: plistURL.path) {
                try fileManager.removeItem(at: plistURL)
                logInfo("Plist file removed")
            }

            logInfo("Service uninstalled successfully")
        } catch {
            logError("Failed to uninstall service: \(error)")
            exit(1)
        }
    }

    /// 启动 launchd 服务
    private static func startLaunchdService() {
        logInfo("Starting launchd service...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["start", "com.deskcal"]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                logInfo("Service started successfully")
            } else {
                logError("Failed to start service (exit code: \(process.terminationStatus))")
                exit(1)
            }
        } catch {
            logError("Failed to start service: \(error)")
            exit(1)
        }
    }

    /// 停止 launchd 服务
    private static func stopLaunchdService() {
        logInfo("Stopping launchd service...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["stop", "com.deskcal"]

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                logInfo("Service stopped successfully")
            } else {
                logError("Failed to stop service (exit code: \(process.terminationStatus))")
                exit(1)
            }
        } catch {
            logError("Failed to stop service: \(error)")
            exit(1)
        }
    }

    /// 检查 launchd 服务状态
    private static func checkLaunchdServiceStatus() {
        logInfo("Checking launchd service status...")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list", "com.deskcal"]

        do {
            let outputPipe = Pipe()
            process.standardOutput = outputPipe
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""

            if process.terminationStatus == 0 {
                if output.contains("com.deskcal") {
                    print("Service is loaded and running.")
                    print(output)
                } else {
                    print("Service is not loaded.")
                }
            } else if process.terminationStatus == 113 {
                // launchctl error: Could not find service
                print("Service is not loaded.")
            } else {
                print("Service status unknown (exit code: \(process.terminationStatus))")
            }
        } catch {
            logError("Failed to check service status: \(error)")
            exit(1)
        }
    }

    // MARK: - Plist生成

    /// 生成launchd plist XML内容
    /// - Parameters:
    ///   - executablePath: 可执行文件路径
    ///   - mode: 日历模式
    /// - Returns: plist XML字符串
    private static func generateLaunchdPlist(executablePath: String, mode: CalendarMode) -> String {
        // 转义XML特殊字符
        func escapeXML(_ string: String) -> String {
            return string
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&apos;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
        }

        let escapedPath = escapeXML(executablePath)

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.deskcal</string>

            <key>ProgramArguments</key>
            <array>
                <string>\(escapedPath)</string>
                <string>--daemon</string>
                <string>--\(mode.rawValue)</string>
            </array>

            <key>StartCalendarInterval</key>
            <dict>
                <key>Hour</key>
                <integer>0</integer>
                <key>Minute</key>
                <integer>0</integer>
            </dict>

            <!-- 后备：每小时检查一次，确保睡眠唤醒后也能更新 -->
            <key>StartInterval</key>
            <integer>3600</integer>

            <key>RunAtLoad</key>
            <true/>

            <key>StandardOutPath</key>
            <string>/tmp/com.deskcal.log</string>
            <key>StandardErrorPath</key>
            <string>/tmp/com.deskcal.error.log</string>

            <key>EnvironmentVariables</key>
            <dict>
                <key>PATH</key>
                <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
            </dict>

            <key>KeepAlive</key>
            <false/>

            <key>ProcessType</key>
            <string>Background</string>

            <key>Nice</key>
            <integer>10</integer>

            <key>LowPriorityIO</key>
            <true/>
        </dict>
        </plist>
        """
    }

    // MARK: - 登录项支持

    /// 将应用添加到登录项
    private static func addToLoginItems() {
        logWarning("Login items support is currently disabled due to deprecated APIs. Use launchd service instead.")
    }

    /// 从登录项中移除应用
    private static func removeFromLoginItems() {
        logWarning("Login items support is currently disabled due to deprecated APIs. Use launchd service instead.")
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
          --install-service Install launchd service (copy plist to LaunchAgents and load)
          --uninstall-service Uninstall launchd service (unload and remove plist)
          --start-service Start the launchd service
          --stop-service  Stop the launchd service
          --service-status Check launchd service status
          --add-login-item Add DeskCal to login items (alternative to launchd)
          --remove-login-item Remove DeskCal from login items
          --config PATH   Use custom configuration file
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
