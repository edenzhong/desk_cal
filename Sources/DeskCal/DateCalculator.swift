// DateCalculator.swift
// DeskCal - macOS Desktop Calendar
// 日期计算核心模块，负责月份天数、星期排列、闰年处理等日期相关计算

import Foundation

/// 日期计算核心模块
struct DateCalculator {

    /// 计算指定年份和月份的天数
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    /// - Returns: 该月的天数
    static func daysInMonth(year: Int, month: Int) -> Int {
        let calendar = Calendar.current

        // 创建日期组件
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month

        guard let date = calendar.date(from: dateComponents),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 0
        }

        return range.count
    }

    /// 检查指定年份是否为闰年
    /// - Parameter year: 年份
    /// - Returns: 是否为闰年
    static func isLeapYear(_ year: Int) -> Bool {
        if year % 400 == 0 {
            return true
        }
        if year % 100 == 0 {
            return false
        }
        return year % 4 == 0
    }

    /// 获取指定年份和月份的第一天是星期几
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    /// - Returns: 星期几 (0-6，其中0表示周日，6表示周六)
    static func firstWeekdayOfMonth(year: Int, month: Int) -> Int {
        let calendar = Calendar.current

        // 创建日期组件
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1

        guard let date = calendar.date(from: dateComponents) else {
            return 0
        }

        // 获取星期几（Calendar默认周日=1，周一=2，周六=7）
        let weekday = calendar.component(.weekday, from: date)

        // 调整：将1-7映射到0-6，其中周日为0，周六为6
        return (weekday - 1) % 7
    }

    /// 获取当前年份和月份
    /// - Returns: (年份, 月份) 元组
    static func currentYearAndMonth() -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return (year, month)
    }

    /// 获取今天的日期
    /// - Returns: (年份, 月份, 日) 元组
    static func today() -> (year: Int, month: Int, day: Int) {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        return (year, month, day)
    }

    /// 为指定的月份生成日期矩阵
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    /// - Returns: 二维数组，表示6行7列的日历网格，包含日期数字或nil（空白单元格）
    static func generateCalendarMatrix(year: Int, month: Int) -> [[Int?]] {
        let daysInMonth = daysInMonth(year: year, month: month)
        let firstWeekday = firstWeekdayOfMonth(year: year, month: month)

        // 创建6行7列的矩阵（6周 * 7天）
        var matrix: [[Int?]] = Array(repeating: Array(repeating: nil, count: 7), count: 6)

        var currentDay = 1

        // 填充矩阵
        for week in 0..<6 {
            for day in 0..<7 {
                // 如果是第一天之前的单元格或所有天数已用完
                if (week == 0 && day < firstWeekday) || currentDay > daysInMonth {
                    matrix[week][day] = nil
                } else {
                    matrix[week][day] = currentDay
                    currentDay += 1
                }
            }
        }

        return matrix
    }

    /// 获取月份名称（本地化）
    /// - Parameter month: 月份 (1-12)
    /// - Returns: 月份名称字符串
    static func monthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else {
            return "Unknown"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"

        // 使用任意日期获取月份名称
        var dateComponents = DateComponents()
        dateComponents.year = 2000
        dateComponents.month = month
        dateComponents.day = 1

        guard let date = Calendar.current.date(from: dateComponents) else {
            return "Month \(month)"
        }

        return dateFormatter.string(from: date)
    }

    /// 获取星期名称（本地化，简写）
    /// - Returns: 包含7个星期名称的数组，从周日开始
    static func weekdayNames() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E"  // 简写星期名称

        var weekdayNames: [String] = []

        // 创建一个日期，然后调整到周日，然后获取连续7天的名称
        // 首先找到一个已知的周日日期：2000-01-02 是周日
        var dateComponents = DateComponents()
        dateComponents.year = 2000
        dateComponents.month = 1
        dateComponents.day = 2  // 2000-01-02 是周日

        guard let startDate = Calendar.current.date(from: dateComponents) else {
            // 回退方案
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }

        // 获取从周日开始的连续7天
        for dayOffset in 0..<7 {
            guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) else {
                weekdayNames.append("Day \(dayOffset)")
                continue
            }

            let name = dateFormatter.string(from: date)
            weekdayNames.append(name)
        }

        return weekdayNames
    }
}

