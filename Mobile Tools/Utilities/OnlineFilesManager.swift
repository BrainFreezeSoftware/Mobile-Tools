//
//  OnlineFilesManager.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import Foundation

public final class OnlineFilesManager {
    public static let manager = OnlineFilesManager()
    private var onlineFiles: [BekoFile] = []

    private init() {}

    public func setupFiles(callback: @escaping (Bool) -> Void) {
        DownloadManager.manager.getFilesArray { [weak self] files in
            self?.onlineFiles = files
            callback(!files.isEmpty)
        }
    }

    /// Filters files safely using strongly typed properties instead of untyped dictionary string evaluations.
    public func filesFilteredBy(typeCode: String, group: String) -> [BekoFile] {
        return onlineFiles.filter { file in
            file.typeCode.uppercased() == typeCode.uppercased() &&
            file.groupName.uppercased() == group.uppercased()
        }
    }

    public func filesFilteredBy(typeCode: String) -> [BekoFile] {
        return onlineFiles.filter { $0.typeCode.uppercased() == typeCode.uppercased() }
    }

    // MARK: - Interface Interoperability Layer
    // These methods match your original manager's method names but drop unstructured dictionaries

    public func getFileName(_ file: BekoFile) -> String { return file.fileName }
    public func getFileURL(_ file: BekoFile) -> String { return file.assetURLString }
    public func getFileLanguages(_ file: BekoFile) -> [String] { return file.languages }
    public func getFileThumbnailPath(_ file: BekoFile) -> String? { return file.targetThumbnailPath }
}
