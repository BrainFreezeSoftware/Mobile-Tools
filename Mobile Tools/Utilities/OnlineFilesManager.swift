//
//  OnlineFilesManager.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import Foundation

public final class OnlineFilesManager: NSObject {
    public static let manager = OnlineFilesManager()
    private var onlineFiles: [BekoFile] = []

    private override init() {
        super.init()
    }

    public func setupFiles(completion: @escaping (Bool) -> Void) {
        Task { @MainActor in
            let files = await DownloadManager.manager.getFilesArray()

            self.onlineFiles = files
            completion(true)
        }
    }

    public func filesFilteredByFileType(fileType: FileType, group: String = "") -> [BekoFile] {
        return onlineFiles.filter { file in
            let match = fileType == file.fileType
            if match && !group.isEmpty {
                return file.groupName.uppercased() == group.uppercased()
            }
            return match
        }
    }

    public func getFileTags(file: BekoFile) -> [String] {
        // Maps FileLanguage enums to their raw string representations, then joins them
        let rawLanguagesString = file.languages.map { $0.rawValue }.joined(separator: ",")
        return [file.fileType.rawValue, file.groupName, rawLanguagesString]
    }

    public func getFileLanguages(file: BekoFile) -> [String] {
        // Converts the [FileLanguage] enum array to a clean [String] array
        return file.languages.map { $0.rawValue }
    }

    public func getLanguagesForFiles(files: [BekoFile]) -> [String] {
        var langSet = Set<String>()
        for file in files {
            // Extracts raw string languages and unions them to prevent duplication
            let rawLangs = file.languages.map { $0.rawValue }
            langSet.formUnion(rawLangs)
        }
        return Array(langSet).sorted() // Optional: Sorted results ensure a consistent order in UI filters
    }

    public func getFileName(file: BekoFile) -> String? {
        return file.fileName
    }

    public func getFileURL(file: BekoFile) -> String? {
        return file.link
    }

    public func getGroups() -> [BekoFile] {
        return filesFilteredByFileType(fileType: .group)
    }

    public func getGroupsWithFileType(fileType: FileType) -> [BekoFile] {
        let groups = getGroups()

        let filtered = groups.filter { group in
            let groupName = group.fileName
            let files = filesFilteredByFileType(fileType: fileType, group: groupName)
            return !files.isEmpty
        }

        return filtered.sorted { obj1, obj2 in
            return obj1.fileName.localizedCompare(obj2.fileName) == .orderedAscending
        }
    }

    public func getGroupName(group: BekoFile) -> String? {
        return group.fileName
    }
}
