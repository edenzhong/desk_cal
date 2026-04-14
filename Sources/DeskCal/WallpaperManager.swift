// WallpaperManager.swift
// DeskCal - macOS Desktop Calendar
// 墙纸管理模块，负责设置桌面墙纸，包含错误处理和权限检查

import AppKit
import Foundation

// MARK: - 日志快捷方法

@MainActor
private func logInfo(_ message: String) {
    Logger.shared.info("[WallpaperManager] \(message)")
}

@MainActor
private func logError(_ message: String) {
    Logger.shared.error("[WallpaperManager] \(message)")
}

/// 墙纸管理错误类型
enum WallpaperManagerError: Error {
    case noMainScreen
    case imageConversionFailed
    case permissionDenied
    case systemError(description: String)
}

/// 墙纸管理选项
struct WallpaperOptions {
    /// 图片缩放方式
    var scaling: NSImageScaling = .scaleProportionallyUpOrDown
    /// 是否允许裁剪
    var allowClipping: Bool = true
    /// 填充颜色（可选）
    var fillColor: NSColor? = nil

    static var `default`: WallpaperOptions {
        WallpaperOptions()
    }
}

/// 墙纸管理器
struct WallpaperManager {

    /// 设置墙纸
    /// - Parameters:
    ///   - image: 要设置为墙纸的图片
    ///   - options: 墙纸选项（默认值使用默认选项）
    ///   - screen: 目标屏幕（默认为主屏幕）
    /// - Throws: WallpaperManagerError 错误
    static func setWallpaper(
        image: NSImage,
        options: WallpaperOptions = .default,
        screen: NSScreen? = nil
    ) throws {
        // 确定目标屏幕
        let targetScreen = screen ?? NSScreen.main
        guard let targetScreen = targetScreen else {
            throw WallpaperManagerError.noMainScreen
        }

        // 保存图片到临时文件
        let tempURL = try saveImageToTempFile(image)

        // 准备墙纸选项
        let workspaceOptions: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: options.scaling.rawValue,
            .allowClipping: options.allowClipping
        ]

        // 设置墙纸
        do {
            try NSWorkspace.shared.setDesktopImageURL(tempURL, for: targetScreen, options: workspaceOptions)
        } catch {
            // 检查是否权限问题
            if error.localizedDescription.contains("permission") ||
               error.localizedDescription.contains("denied") ||
               error.localizedDescription.contains("access") {
                throw WallpaperManagerError.permissionDenied
            } else {
                throw WallpaperManagerError.systemError(description: error.localizedDescription)
            }
        }

        // 清理临时文件（延迟清理，确保系统有时间读取文件）
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 5.0) {
            try? FileManager.default.removeItem(at: tempURL)
        }
    }

    /// 设置墙纸（通过图片URL）
    /// - Parameters:
    ///   - imageURL: 图片文件URL
    ///   - options: 墙纸选项
    ///   - screen: 目标屏幕
    /// - Throws: WallpaperManagerError 错误
    static func setWallpaper(
        imageURL: URL,
        options: WallpaperOptions = .default,
        screen: NSScreen? = nil
    ) throws {
        // 确定目标屏幕
        let targetScreen = screen ?? NSScreen.main
        guard let targetScreen = targetScreen else {
            throw WallpaperManagerError.noMainScreen
        }

        // 准备墙纸选项
        let workspaceOptions: [NSWorkspace.DesktopImageOptionKey: Any] = [
            .imageScaling: options.scaling.rawValue,
            .allowClipping: options.allowClipping
        ]

        // 设置墙纸
        do {
            try NSWorkspace.shared.setDesktopImageURL(imageURL, for: targetScreen, options: workspaceOptions)
        } catch {
            // 检查是否权限问题
            if error.localizedDescription.contains("permission") ||
               error.localizedDescription.contains("denied") ||
               error.localizedDescription.contains("access") {
                throw WallpaperManagerError.permissionDenied
            } else {
                throw WallpaperManagerError.systemError(description: error.localizedDescription)
            }
        }
    }

    /// 检查是否具有设置墙纸的权限
    /// - Returns: 如果有权限返回true，否则返回false
    static func hasPermission() -> Bool {
        // 尝试设置一个临时测试图片来检查权限
        let testImage = NSImage(size: NSSize(width: 100, height: 100))
        testImage.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: 100, height: 100).fill()
        testImage.unlockFocus()

        do {
            // 尝试设置到临时屏幕（如果存在）
            if let screen = NSScreen.main {
                let tempURL = try saveImageToTempFile(testImage)
                try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [:])
                // 立即清理临时文件
                try? FileManager.default.removeItem(at: tempURL)
                return true
            }
        } catch {
            // 权限错误或无权限
            return false
        }

        return false
    }

    /// 获取所有屏幕
    /// - Returns: 屏幕数组
    static func getAllScreens() -> [NSScreen] {
        return NSScreen.screens
    }

    /// 获取主屏幕
    /// - Returns: 主屏幕，如果没有则返回nil
    static func getMainScreen() -> NSScreen? {
        return NSScreen.main
    }

    /// 为所有屏幕设置墙纸
    /// 如果某个屏幕设置失败，会继续设置其他屏幕
    /// - Parameters:
    ///   - image: 要设置为墙纸的图片
    ///   - options: 墙纸选项（默认值使用默认选项）
    /// - Returns: 成功设置的屏幕数量
    /// - Throws: 如果所有屏幕都设置失败，则抛出错误
    @MainActor
    static func setWallpaperForAllScreens(
        image: NSImage,
        options: WallpaperOptions = .default
    ) throws -> Int {
        let screens = NSScreen.screens
        guard !screens.isEmpty else {
            throw WallpaperManagerError.noMainScreen
        }

        var successCount = 0
        var errors: [String] = []

        for (index, screen) in screens.enumerated() {
            do {
                try setWallpaper(image: image, options: options, screen: screen)
                successCount += 1
                logInfo("Successfully set wallpaper for screen \(index)")
            } catch {
                let errorMessage = "Failed to set wallpaper for screen \(index): \(error.localizedDescription)"
                logError(errorMessage)
                errors.append(errorMessage)
                // 继续设置其他屏幕
            }
        }

        if successCount == 0 {
            throw WallpaperManagerError.systemError(description: "Failed to set wallpaper on any screen. Errors: \(errors.joined(separator: "; "))")
        }

        logInfo("Wallpaper set for \(successCount) out of \(screens.count) screens")
        return successCount
    }

    // MARK: - 私有方法

    /// 保存图片到临时文件
    /// - Parameter image: 要保存的图片
    /// - Returns: 临时文件URL
    private static func saveImageToTempFile(_ image: NSImage) throws -> URL {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "deskcal-wallpaper-\(UUID().uuidString).png"
        let fileURL = tempDir.appendingPathComponent(fileName)

        // 获取PNG数据
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw WallpaperManagerError.imageConversionFailed
        }

        // 写入文件
        try pngData.write(to: fileURL)

        return fileURL
    }
}