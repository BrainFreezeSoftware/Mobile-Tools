//
//  Utilities.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import Foundation
import UIKit
import AVFoundation

public final class Utilities: NSObject {

    public static func createThumbnailFromPDF(pdfPath: String, thumbnailPath: String) {
        autoreleasepool {
            let url = URL(fileURLWithPath: pdfPath)
            guard let pdfData = try? Data(contentsOf: url),
                  let provider = CGDataProvider(data: pdfData as CFData),
                  let pdf = CGPDFDocument(provider) else { return }

            if let pdfPage = pdf.page(at: 1) {
                let baseSize = CGSize(width: 612, height: 792)
                let view = UIView(frame: CGRect(origin: .zero, size: baseSize))

                let pageRect = pdfPage.getBoxRect(.mediaBox)
                let pdfScale = view.frame.size.width / pageRect.size.width
                let scaledSize = CGSize(width: pageRect.size.width * pdfScale, height: pageRect.size.height * pdfScale)
                let scaledRect = CGRect(origin: .zero, size: scaledSize)

                let renderer = UIGraphicsImageRenderer(size: scaledSize)
                let backgroundImage = renderer.image { rendererContext in
                    let context = rendererContext.cgContext

                    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                    context.fill(scaledRect)

                    context.saveGState()
                    context.translateBy(x: 0.0, y: scaledSize.height)
                    context.scaleBy(x: 1.0, y: -1.0)

                    context.scaleBy(x: pdfScale, y: pdfScale)
                    context.drawPDFPage(pdfPage)
                    context.restoreGState()
                }

                let backgroundImageView = UIImageView(image: backgroundImage)
                backgroundImageView.frame = scaledRect
                backgroundImageView.contentMode = .scaleAspectFit
                view.addSubview(backgroundImageView)
                view.sendSubviewToBack(backgroundImageView)

                if let finalImage = backgroundImageView.image,
                   let imageData = finalImage.pngData() {
                    try? imageData.write(to: URL(fileURLWithPath: thumbnailPath), options: [])
                }
            }
        }
    }

    public static func createThumbnailsFromPDFs(path: String, directory: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error: Create folder failed \(path)")
        }

        let fileList = Bundle.main.paths(forResourcesOfType: "pdf", inDirectory: directory)
        for pdfPath in fileList {
            let url = URL(fileURLWithPath: pdfPath)
            let filename = url.deletingPathExtension().lastPathComponent
            let thumbnailPath = "\(path)/\(filename).png"
            createThumbnailFromPDF(pdfPath: pdfPath, thumbnailPath: thumbnailPath)
        }
    }

    public static func createThumbnailsFromPDFsWithSubFolders(path: String, directory: String) {
        let directories = Bundle.main.paths(forResourcesOfType: "", inDirectory: directory)
        for subDirectory in directories {
            let tempPath = URL(fileURLWithPath: subDirectory).lastPathComponent
            let subFolder = "\(path)/\(tempPath)"
            let tempDirectory = "\(directory)/\(tempPath)"
            createThumbnailsFromPDFs(path: subFolder, directory: tempDirectory)
        }
    }

    public static func createThumbnailFromVideo(videoPath: String, thumbnailPath: String) async {
        let videoURL = URL(fileURLWithPath: videoPath)
        let asset = AVURLAsset(url: videoURL, options: nil)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        let thumbTime = CMTimeMakeWithSeconds(32, preferredTimescale: 30)
        generator.maximumSize = CGSize(width: 425, height: 355)

        do {
            // Modernized: Uses the non-deprecated async generator API
            let (imgRef, _) = try await generator.image(at: thumbTime)
            let thumbnail = UIImage(cgImage: imgRef)
            if let imageData = thumbnail.pngData() {
                try imageData.write(to: URL(fileURLWithPath: thumbnailPath), options: [])
            }
        } catch {
            print("Video thumbnail generation failed: \(error)")
        }
    }

    public static func createThumbnailsForViewType(videoType: String, path: String, directory: String) async {
        let fileList = Bundle.main.paths(forResourcesOfType: videoType, inDirectory: directory)
        for filePath in fileList {
            let filename = URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
            let thumbnailPath = "\(path)/\(filename).png"
            await createThumbnailFromVideo(videoPath: filePath, thumbnailPath: thumbnailPath)
        }
    }

    public static func createThumbnailsFromVideo(path: String, directory: String) async {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error: Create folder failed \(path)")
        }

        await createThumbnailsForViewType(videoType: "mp4", path: path, directory: directory)
        await createThumbnailsForViewType(videoType: "wmv", path: path, directory: directory)
    }

    public static func createThumbnails() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].path
        let mediaPath = "\(documentsDirectory)/Media"
        let fileManager = FileManager.default

        var isDir: ObjCBool = false
        var update = false
        let userDefaults = UserDefaults.standard

        // Fixed: Changed 'version.initValue' to 'version.intValue'
        if let version = userDefaults.object(forKey: "UpdateVersion") as? NSNumber {
            if version.intValue > 2 {
                update = true
            }
        } else {
            update = true
        }

        if !fileManager.fileExists(atPath: mediaPath, isDirectory: &isDir) || update {
            if update {
                try? fileManager.removeItem(atPath: mediaPath)
            }

            do {
                try fileManager.createDirectory(atPath: mediaPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error: Create folder failed \(mediaPath)")
            }

            _ = addSkipBackupAttributeToItem(atPath: mediaPath)

            var path = "\(mediaPath)/Brochures"
            createThumbnailsFromPDFs(path: path, directory: "Media/Brochures")

            path = "\(mediaPath)/Technical Docs"
            createThumbnailsFromPDFs(path: path, directory: "Media/Technical Docs")

            path = "\(mediaPath)/Manuals"
            createThumbnailsFromPDFsWithSubFolders(path: path, directory: "Media/Manuals")

            path = "\(mediaPath)/Presentations"
            createThumbnailsFromPDFs(path: path, directory: "Media/Presentations")

            path = "\(mediaPath)/Price Books"
            createThumbnailsFromPDFs(path: path, directory: "Media/Price Books")

            userDefaults.set(2, forKey: "UpdateVersion")
        }
    }

    public static func addSkipBackupAttributeToItem(atPath filePathString: String) -> Bool {
        var url = URL(fileURLWithPath: filePathString)
        assert(FileManager.default.fileExists(atPath: url.path))

        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
            return true
        } catch {
            print("Error excluding \(url.lastPathComponent) from backup \(error)")
            return false
        }
    }
}
