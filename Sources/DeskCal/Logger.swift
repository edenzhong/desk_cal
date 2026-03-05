// Logger.swift
// DeskCal - macOS Desktop Calendar
// 日志系统模块，负责记录应用运行状态和错误信息

import Foundation
import os.log

/// 日志级别
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"

    var symbol: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

/// 日志目的地
struct LogDestination: OptionSet {
    let rawValue: Int

    static let console = LogDestination(rawValue: 1 << 0)
    static let file = LogDestination(rawValue: 1 << 1)
    static let osLog = LogDestination(rawValue: 1 << 2)

    static let all: LogDestination = [.console, .file, .osLog]
}

/// 日志管理器
@MainActor
class Logger {
    /// 单例实例
    static let shared = Logger()

    /// 日志队列（确保线程安全）
    private let logQueue = DispatchQueue(label: "com.deskcal.logger", qos: .utility)

    /// 日志文件URL
    private var logFileURL: URL?

    /// 日志目的地
    private var destinations: LogDestination = .console

    /// 是否已初始化
    private var initialized = false

    /// 初始化日志系统
    /// - Parameters:
    ///   - destinations: 日志目的地
    ///   - logToFile: 是否记录到文件（如果为true，则创建日志文件）
    func initialize(destinations: LogDestination = .console, logToFile: Bool = false) {
        logQueue.sync {
            self.destinations = destinations

            if logToFile && destinations.contains(.file) {
                setupLogFile()
            }

            self.initialized = true
            self.log(level: .info, message: "Logger initialized with destinations: \(destinations)")
        }
    }

    /// 记录日志
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志消息
    ///   - file: 文件名（自动获取）
    ///   - function: 函数名（自动获取）
    ///   - line: 行号（自动获取）
    func log(level: LogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logQueue.async {
            // 如果没有初始化，使用默认设置
            if !self.initialized {
                self.destinations = .console
                self.initialized = true
            }

            // 构建日志条目
            let timestamp = self.timestampString()
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            let logEntry = self.formatLogEntry(
                timestamp: timestamp,
                level: level,
                message: message,
                file: fileName,
                function: function,
                line: line
            )

            // 输出到各个目的地
            if self.destinations.contains(.console) {
                print(logEntry)
            }

            if self.destinations.contains(.osLog) {
                self.logToOSLog(level: level, message: message, file: fileName, function: function, line: line)
            }

            if self.destinations.contains(.file), let fileURL = self.logFileURL {
                self.writeToFile(logEntry: logEntry, fileURL: fileURL)
            }
        }
    }

    // MARK: - 快捷方法

    /// 记录调试信息
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }

    /// 记录一般信息
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    /// 记录警告信息
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    /// 记录错误信息
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    /// 记录错误异常
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: "\(error)", file: file, function: function, line: line)
    }

    /// 获取日志文件路径
    func getLogFileURL() -> URL? {
        return logQueue.sync { logFileURL }
    }

    // MARK: - 私有方法

    /// 设置日志文件
    private func setupLogFile() {
        let fileManager = FileManager.default

        // 创建日志目录
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let logsDirectory = appSupportURL.appendingPathComponent("DeskCal/Logs")

        do {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)

            // 创建日志文件名（基于日期）
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            let logFileName = "deskcal-\(dateString).log"
            let logFileURL = logsDirectory.appendingPathComponent(logFileName)

            self.logFileURL = logFileURL

            // 如果文件不存在，创建它
            if !fileManager.fileExists(atPath: logFileURL.path) {
                let header = "=== DeskCal Log - \(dateString) ===\n"
                try header.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to setup log file: \(error)")
        }
    }

    /// 格式化日志条目
    private func formatLogEntry(timestamp: String, level: LogLevel, message: String,
                               file: String, function: String, line: Int) -> String {
        return "\(timestamp) \(level.symbol) [\(level.rawValue)] \(file):\(line) \(function) - \(message)"
    }

    /// 获取时间戳字符串
    private func timestampString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return dateFormatter.string(from: Date())
    }

    /// 写入日志文件
    private func writeToFile(logEntry: String, fileURL: URL) {
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()

            if let data = "\(logEntry)\n".data(using: .utf8) {
                fileHandle.write(data)
            }

            fileHandle.closeFile()
        } catch {
            // 如果文件句柄打开失败，尝试创建文件并写入
            do {
                try "\(logEntry)\n".write(to: fileURL, atomically: true, encoding: .utf8)
            } catch {
                print("Failed to write to log file: \(error)")
            }
        }
    }

    /// 记录到系统日志（os_log）
    private func logToOSLog(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let log = OSLog(subsystem: "com.deskcal", category: "DeskCal")

        switch level {
        case .debug:
            os_log("%{public}@", log: log, type: .debug, message)
        case .info:
            os_log("%{public}@", log: log, type: .info, message)
        case .warning:
            os_log("%{public}@", log: log, type: .default, message)
        case .error:
            os_log("%{public}@", log: log, type: .error, message)
        }
    }
}

// MARK: - 全局快捷函数

/// 全局日志函数
@MainActor
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

@MainActor
func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

@MainActor
func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

@MainActor
func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}

@MainActor
func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(error, file: file, function: function, line: line)
}