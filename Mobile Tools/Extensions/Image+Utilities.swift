//
//  Image+Utilities.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/23/26.
//

import SwiftUI
import UIKit

extension Image {
    /// Initializes a SwiftUI Image from a local file system URL (e.g., Documents directory).
    /// Falls back to a named asset or a system icon if the file cannot be loaded.
    init(contentsOf url: URL, fallbackName: String = "") {
        // 1. Ensure it's a local file URL and the file exists
        if url.isFileURL, FileManager.default.fileExists(atPath: url.path) {
            // 2. Try to load the data and convert it to a UIImage
            if let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
                self.init(uiImage: uiImage)
                return
            } else {
                print("⚠️ File exists at URL, but could not be parsed as an image: \(url)")
            }
        } else {
            print("❌ No file found or invalid file URL: \(url)")
        }

        // 3. Fallback if something goes wrong
        self.init(fallbackName.isEmpty ? "placeholder" : fallbackName)
    }
}
