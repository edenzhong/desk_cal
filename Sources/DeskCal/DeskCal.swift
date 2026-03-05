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

@main
struct DeskCal {
    static func main() {
        print("DeskCal starting...")

        // 解析命令行参数
        let arguments = CommandLine.arguments
        var mode: String = "year"  // 默认全年日历
        var testOnly: Bool = false

        for i in 1..<arguments.count {
            let arg = arguments[i]
            if arg == "--month" || arg == "-m" {
                mode = "month"
            } else if arg == "--year" || arg == "-y" {
                mode = "year"
            } else if arg == "--test" || arg == "-t" {
                testOnly = true
            } else if arg == "--help" || arg == "-h" {
                printHelp()
                exit(0)
            }
        }

        do {
            // 1. 创建日历图片
            let image: NSImage
            if mode == "month" {
                print("Generating single month calendar...")
                image = try createCalendarImage()
            } else {
                print("Generating year calendar...")
                image = try createYearCalendarImage()
            }

            // 2. 保存图片到临时文件
            let tempURL = try saveImageToTempFile(image)
            print("Created calendar image at: \(tempURL.path)")

            if testOnly {
                // 测试模式：复制到桌面
                let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
                let desktopFileURL = desktopURL.appendingPathComponent("deskcal-test.png")
                // 删除已存在的文件
                if FileManager.default.fileExists(atPath: desktopFileURL.path) {
                    try FileManager.default.removeItem(at: desktopFileURL)
                }
                try FileManager.default.copyItem(at: tempURL, to: desktopFileURL)
                print("Copied test image to desktop: \(desktopFileURL.path)")
            } else {
                // 3. 设置图片为墙纸
                try setWallpaper(imageURL: tempURL)
                print("Wallpaper set successfully")
            }

        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }

    static func printHelp() {
        print("""
        DeskCal - macOS Desktop Calendar

        Usage:
          DeskCal [options]

        Options:
          -m, --month     Generate single month calendar (default: year)
          -y, --year      Generate year calendar (12 months)
          -t, --test      Test mode: save image to desktop instead of setting wallpaper
          -h, --help      Show this help message

        Examples:
          DeskCal --year      # Generate and set year calendar wallpaper
          DeskCal --month     # Generate and set single month wallpaper
          DeskCal --year --test # Generate year calendar and save to desktop for testing
        """)
    }

    static func createCalendarImage() throws -> NSImage {
        // 获取当前年份和月份
        let (year, month) = DateCalculator.currentYearAndMonth()
        let (_, _, todayDay) = DateCalculator.today()

        print("Generating calendar for \(DateCalculator.monthName(for: month)) \(year), today is \(todayDay)")

        // 获取屏幕尺寸
        guard let mainScreen = NSScreen.main else {
            throw NSError(domain: "DeskCal", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "No main screen found"])
        }

        let screenSize = mainScreen.frame.size
        let width = screenSize.width
        let height = screenSize.height

        print("Screen size: \(width)x\(height)")

        // 创建日历生成器配置
        let config = CalendarConfig.default(width: width, height: height)

        // 创建日历生成器
        let generator = CalendarGenerator(config: config)

        // 生成日历图片
        return try generator.generateMonthCalendar(year: year, month: month, todayDay: todayDay)
    }

    static func createYearCalendarImage() throws -> NSImage {
        // 获取当前年份
        let (year, _) = DateCalculator.currentYearAndMonth()
        let (_, todayMonth, todayDay) = DateCalculator.today()

        print("Generating year calendar for \(year), today is \(DateCalculator.monthName(for: todayMonth)) \(todayDay)")

        // 获取屏幕尺寸
        guard let mainScreen = NSScreen.main else {
            throw NSError(domain: "DeskCal", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "No main screen found"])
        }

        let screenSize = mainScreen.frame.size
        let width = screenSize.width
        let height = screenSize.height

        print("Screen size: \(width)x\(height)")

        // 创建日历生成器配置
        let config = CalendarConfig.default(width: width, height: height)

        // 创建日历生成器
        let generator = CalendarGenerator(config: config)

        // 生成全年日历图片
        return try generator.generateYearCalendar(
            year: year,
            todayDate: (month: todayMonth, day: todayDay)
        )
    }

    static func saveImageToTempFile(_ image: NSImage) throws -> URL {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "deskcal-\(UUID().uuidString).png"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // 获取PNG数据
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "DeskCal", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG"])
        }

        // 写入文件
        try pngData.write(to: fileURL)

        return fileURL
    }

    static func setWallpaper(imageURL: URL) throws {
        // 获取所有屏幕
        let screens = NSScreen.screens
        print("Found \(screens.count) screen(s)")

        // 获取主屏幕
        guard let mainScreen = NSScreen.main else {
            throw NSError(domain: "DeskCal", code: 3, userInfo: [NSLocalizedDescriptionKey: "No main screen found"])
        }

        print("Setting wallpaper for main screen (ID: \(mainScreen.displayID ?? 0), size: \(mainScreen.frame.size))")

        // 设置墙纸选项
        let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue,
            .allowClipping: true
        ]

        // 设置墙纸
        try NSWorkspace.shared.setDesktopImageURL(imageURL, for: mainScreen, options: options)

        print("Wallpaper set successfully for main screen")
    }
}
