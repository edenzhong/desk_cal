import Foundation

/// 农历日期转换器，用于公历日期与农历日期之间的转换
public class LunarDateConverter {

    // MARK: - 公共结构体

    /// 农历日期信息
    public struct LunarDate {
        public let year: Int      // 农历年
        public let month: Int     // 农历月 (1-12)
        public let day: Int       // 农历日 (1-30/31)
        public let isLeapMonth: Bool  // 是否闰月
        public let monthName: String  // 月份名称 (正月至腊月)
        public let dayName: String    // 日期名称 (初一至三十)
        public let ganzhiYear: String  // 天干地支年
        public let ganzhiMonth: String // 天干地支月
        public let ganzhiDay: String   // 天干地支日
        public let animal: String      // 生肖
        public let solarTerm: String   // 当前节气
        public let festival: String    // 传统节日

        /// 短格式日期名称 (如: 初一, 十五)
        public var shortName: String {
            // 节日优先显示
            if !festival.isEmpty {
                return festival
            }
            // 节气其次
            if !solarTerm.isEmpty {
                return solarTerm
            }
            // 初一显示月份
            if day == 1 {
                return monthName
            }
            return dayName
        }

        /// 完整格式日期名称 (如: 正月初一, 三月十五)
        public var fullName: String {
            if !festival.isEmpty {
                return festival
            }
            return "\(monthName)\(dayName)"
        }

        /// 数字格式日期 (如: 3/5)
        public var numericName: String {
            if !festival.isEmpty {
                return festival
            }
            return "\(month)/\(day)"
        }
    }

    // MARK: - 私有属性

    // 系统自带的中国农历 Calendar
    private lazy var chineseCalendar: Calendar = {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }()

    // 公历 Calendar
    private lazy var gregorianCalendar: Calendar = {
        return Calendar(identifier: .gregorian)
    }()

    // 天干
    private static let tiangan = ["甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"]

    // 地支
    private static let dizhi = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]

    // 生肖
    private static let animals = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]

    // 农历月份名称
    private static let lunarMonths = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]

    // 农历日期名称
    private static let lunarDays = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    // 节气名称 (24节气)
    private static let solarTerms = [
        "小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满",
        "芒种", "夏至", "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降",
        "立冬", "小雪", "大雪", "冬至"
    ]

    // 传统节日
    private static let festivals: [String: String] = [
        "1-1": "春节", "1-15": "元宵节", "5-5": "端午节", "7-7": "七夕", "7-15": "中元节",
        "8-15": "中秋节", "9-9": "重阳节", "12-8": "腊八节", "12-24": "小年", "12-30": "除夕"
    ]

    // MARK: - 公共方法

    /// 将公历日期转换为农历日期
    /// - Parameter date: 公历日期
    /// - Returns: 农历日期信息
    public func convert(_ date: Date) -> LunarDate {
        // 获取农历年月日
        let lunarComponents = chineseCalendar.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        let lunarYear = lunarComponents.year ?? 0
        let lunarMonth = lunarComponents.month ?? 0
        let lunarDay = lunarComponents.day ?? 0
        let isLeap = lunarComponents.isLeapMonth ?? false

        // 获取公历年月日（用于节气计算）
        let gregorianComponents = gregorianCalendar.dateComponents([.year, .month, .day], from: date)
        let solarYear = gregorianComponents.year ?? 2000
        let solarMonth = gregorianComponents.month ?? 1
        let solarDay = gregorianComponents.day ?? 1

        // 系统的 Chinese Calendar 返回的年份是一个偏移值
        // 实际农历年 = 系统农历年 + 1983
        let actualYear = lunarYear + 1983

        // 限制数组索引范围
        let safeMonthIndex = max(0, min(lunarMonth - 1, 11))
        let safeDayIndex = max(0, min(lunarDay - 1, 29))

        return LunarDate(
            year: actualYear,
            month: lunarMonth,
            day: lunarDay,
            isLeapMonth: isLeap,
            monthName: Self.lunarMonths[safeMonthIndex] + "月",
            dayName: Self.lunarDays[safeDayIndex],
            ganzhiYear: getGanzhiYear(actualYear),
            ganzhiMonth: getGanzhiMonth(actualYear, lunarMonth),
            ganzhiDay: getGanzhiDay(date),
            animal: Self.animals[(actualYear - 4) % 12],
            solarTerm: getCurrentSolarTerm(solarYear, solarMonth, solarDay),
            festival: getFestival(lunarMonth, lunarDay)
        )
    }

    /// 格式化农历日期
    /// - Parameters:
    ///   - lunarDate: 农历日期
    ///   - format: 格式类型 (short, full, numeric)
    /// - Returns: 格式化后的字符串
    public func format(_ lunarDate: LunarDate, format: String = "short") -> String {
        switch format.lowercased() {
        case "full":
            return lunarDate.fullName
        case "numeric":
            return lunarDate.numericName
        default:
            return lunarDate.shortName
        }
    }

    // MARK: - 私有辅助方法

    /// 获取天干地支年
    private func getGanzhiYear(_ year: Int) -> String {
        let index = (year - 4) % 60
        return Self.tiangan[index % 10] + Self.dizhi[index % 12]
    }

    /// 获取天干地支月
    private func getGanzhiMonth(_ year: Int, _ month: Int) -> String {
        let index = (year - 4) * 12 + month
        return Self.tiangan[index % 10] + Self.dizhi[index % 12]
    }

    /// 获取天干地支日（基于日期计算）
    private func getGanzhiDay(_ date: Date) -> String {
        // 使用公历 1900-01-31 作为基准日（庚子日）
        let baseDate = Date(timeIntervalSince1970: -2203977600)
        let days = Int(date.timeIntervalSince(baseDate) / 86400)
        let index = (days + 60) % 60 // 60 是庚子的偏移
        return Self.tiangan[index % 10] + Self.dizhi[index % 12]
    }

    /// 获取当前节气
    private func getCurrentSolarTerm(_ year: Int, _ month: Int, _ day: Int) -> String {
        // 简化节气计算，使用近似日期
        // 实际节气日期每年略有变化，精确计算需要天文公式
        let solarTermDays = [
            (1, 6), (1, 20), (2, 4), (2, 19), (3, 6), (3, 21), (4, 5), (4, 20),
            (5, 6), (5, 21), (6, 6), (6, 21), (7, 7), (7, 23), (8, 8), (8, 23),
            (9, 8), (9, 23), (10, 8), (10, 23), (11, 7), (11, 22), (12, 7), (12, 22)
        ]

        for (index, (termMonth, termDay)) in solarTermDays.enumerated() {
            if month == termMonth && day == termDay {
                return Self.solarTerms[index]
            }
        }

        return ""
    }

    /// 获取传统节日
    private func getFestival(_ month: Int, _ day: Int) -> String {
        let key = "\(month)-\(day)"
        return Self.festivals[key] ?? ""
    }

    /// 检查是否是节日
    public func isFestival(_ text: String) -> Bool {
        return Self.festivals.values.contains(text)
    }

    /// 检查是否是节气
    public func isSolarTerm(_ text: String) -> Bool {
        return Self.solarTerms.contains(text)
    }
}

// MARK: - 单例扩展

extension LunarDateConverter {
    /// 共享实例
    nonisolated(unsafe) public static let shared = LunarDateConverter()
}
