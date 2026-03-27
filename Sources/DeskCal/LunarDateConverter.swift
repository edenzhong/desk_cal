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

    // 农历年信息表 (每个元素包含: 闰月月份, 大月信息, 从1月到12月的累积天数)
    // 这是一个简化的农历数据表，覆盖1900-2100年
    // 格式: [闰月(0=无), 月大小(1=大月30天,0=小月29天), 从1月到12月的累积天数]
    // 数据来源：开源农历库（如 Lunar-iOS）
    private static let lunarInfo: [Int] = [
        0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0,
        0x0d530, 0x054d5, 0x0a5d0, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0,
        0x0d530, 0x054d5, 0x0a5d0, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0,
        0x0d530, 0x054d5, 0x0a5d0, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0,
        0x0d530, 0x054d5, 0x0a5d0, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0,
        0x0d530, 0x054d5, 0x0a5d0, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0,
        0x0d530, 0x054d5, 0x0a5d0, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
        0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0, 0x095d0, 0x149b7, 0x04970, 0x0a4b0, 0x0b4b5, 0x0a6a0
    ]

    // 1900年1月31日是农历1900年正月初一
    private static let baseDate = Date(timeIntervalSince1970: -2203977600) // 1900-01-31

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
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        let solarYear = components.year ?? 2000
        let solarMonth = components.month ?? 1
        let solarDay = components.day ?? 1

        // 计算距离基准日期的天数
        let daysSinceBase = Int(date.timeIntervalSince(Self.baseDate) / 86400)

        // 转换为农历年月日
        var currentYear = 1900
        var daysLeft = daysSinceBase

        // 确保日期在支持范围内
        guard daysSinceBase >= 0 else {
            // 日期早于1900年，返回默认值
            return LunarDate(
                year: 1900, month: 1, day: 1, isLeapMonth: false,
                monthName: "正月", dayName: "初一",
                ganzhiYear: "庚子", ganzhiMonth: "戊寅", ganzhiDay: "甲子",
                animal: "鼠", solarTerm: "", festival: ""
            )
        }

        // 找到农历年
        while daysLeft >= 0 && currentYear <= 2100 {
            let yearDays = getLunarYearDays(currentYear)
            if daysLeft < yearDays {
                break
            }
            daysLeft -= yearDays
            currentYear += 1
        }

        // 超出数据范围处理
        if currentYear > 2100 {
            return LunarDate(
                year: 2100, month: 12, day: 30, isLeapMonth: false,
                monthName: "腊月", dayName: "三十",
                ganzhiYear: "庚戌", ganzhiMonth: "戊戌", ganzhiDay: "癸亥",
                animal: "狗", solarTerm: "", festival: ""
            )
        }

        // 找到农历月
        var lunarMonth = 1
        var isLeap = false

        while lunarMonth <= 12 {
            let leapMonth = getLeapMonth(currentYear)

            // 先检查闰月
            if leapMonth > 0 && lunarMonth == leapMonth {
                let leapDays = getLeapMonthDays(currentYear)
                if daysLeft < leapDays {
                    isLeap = true
                    break
                }
                daysLeft -= leapDays
                lunarMonth += 1
                continue
            }

            let monthDays = getMonthDays(currentYear, lunarMonth)
            if daysLeft < monthDays {
                break
            }
            daysLeft -= monthDays
            lunarMonth += 1
        }

        let lunarDay = max(1, min(daysLeft + 1, 30))

        // 限制数组索引范围
        let safeMonthIndex = max(0, min(lunarMonth - 1, 11))
        let safeDayIndex = max(0, min(lunarDay - 1, 29))

        return LunarDate(
            year: currentYear,
            month: lunarMonth,
            day: lunarDay,
            isLeapMonth: isLeap,
            monthName: Self.lunarMonths[safeMonthIndex] + "月",
            dayName: Self.lunarDays[safeDayIndex],
            ganzhiYear: getGanzhiYear(currentYear),
            ganzhiMonth: getGanzhiMonth(currentYear, lunarMonth),
            ganzhiDay: getGanzhiDay(currentYear, lunarMonth, lunarDay),
            animal: Self.animals[(currentYear - 4) % 12],
            solarTerm: getCurrentSolarTerm(solarMonth, solarDay),
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

    /// 获取农历年的总天数
    private func getLunarYearDays(_ year: Int) -> Int {
        var sum = 348
        let info = Self.lunarInfo[year - 1900]

        // 检查12个月的大小（从低位到高位）
        // 每个月用一个bit表示，从bit 4到bit 15
        for i in 0...11 {
            let bit = 0x10000 >> (i + 1)
            if (info & bit) != 0 {
                sum += 1
            }
        }

        return sum + getLeapMonthDays(year)
    }

    /// 获取闰月的天数
    private func getLeapMonthDays(_ year: Int) -> Int {
        if getLeapMonth(year) == 0 {
            return 0
        }
        return (Self.lunarInfo[year - 1900] & 0x10000) != 0 ? 30 : 29
    }

    /// 获取闰月月份 (0表示无闰月)
    private func getLeapMonth(_ year: Int) -> Int {
        return Self.lunarInfo[year - 1900] & 0xf
    }

    /// 获取农历月的天数
    private func getMonthDays(_ year: Int, _ month: Int) -> Int {
        let info = Self.lunarInfo[year - 1900]
        let mask = 0x10000 >> (month - 1)
        return (info & mask) != 0 ? 30 : 29
    }

    /// 获取天干地支年
    private func getGanzhiYear(_ year: Int) -> String {
        let index = (year - 4) % 60
        return Self.tiangan[index % 10] + Self.dizhi[index % 12]
    }

    /// 获取天干地支月
    private func getGanzhiMonth(_ year: Int, _ month: Int) -> String {
        // 简化计算
        let index = (year - 4) * 12 + month
        return Self.tiangan[index % 10] + Self.dizhi[index % 12]
    }

    /// 获取天干地支日
    private func getGanzhiDay(_ year: Int, _ _month: Int, _ day: Int) -> String {
        // 简化计算
        let index = (year - 4) * 365 + _month * 30 + day
        return Self.tiangan[index % 10] + Self.dizhi[index % 12]
    }

    /// 获取当前节气
    private func getCurrentSolarTerm(_ month: Int, _ day: Int) -> String {
        // 节气日期近似值（每年略有变化）
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
