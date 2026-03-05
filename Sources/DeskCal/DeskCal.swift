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

        do {
            // 1. 创建简单图片
            let image = try createSimpleImage()

            // 2. 保存图片到临时文件
            let tempURL = try saveImageToTempFile(image)

            print("Created image at: \(tempURL.path)")

            // 3. 设置图片为墙纸
            try setWallpaper(imageURL: tempURL)

        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }

    static func createSimpleImage() throws -> NSImage {
        // 创建图片尺寸（示例：1920x1080）
        let width: CGFloat = 1920
        let height: CGFloat = 1080

        // 创建NSBitmapImageRep
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(width),
            pixelsHigh: Int(height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 32
        )!

        // 创建NSGraphicsContext
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            throw NSError(domain: "DeskCal", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context"])
        }
        NSGraphicsContext.current = context

        // 绘制纯色背景
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        // 绘制文字
        let text = "Hello Calendar"
        let font = NSFont.systemFont(ofSize: 72, weight: .bold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]

        let textSize = text.size(withAttributes: textAttributes)
        let textRect = NSRect(
            x: (width - textSize.width) / 2,
            y: (height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )

        text.draw(in: textRect, withAttributes: textAttributes)

        // 恢复上下文
        NSGraphicsContext.restoreGraphicsState()

        // 创建NSImage
        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(rep)

        return image
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
