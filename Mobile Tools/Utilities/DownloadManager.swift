//
//  DownloadManager.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import Foundation

public final class DownloadManager: NSObject {
    
    public static let manager = DownloadManager()

    private var masterFileList: [BekoFile] = []
    private var tempFileList: [BekoFile] = []
    
    private var currentPage: Int = 1
    private var maxPages: Int = 10

    private override init() {
        super.init()
    }
    
    private var fileListURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("FileList.json")
    }

    @MainActor
    public func getFilesArray() async -> [BekoFile] {
        if currentPage == 1 && tempFileList.isEmpty {
            tempFileList = []
            // Optional local reading: if you convert readFilesListFromFile to async/await:
            // let localFiles = await readFilesListFromFile()
        }

        if currentPage > maxPages {
            let finalResults = tempFileList
            self.tempFileList = []
            self.currentPage = 1

            await self.downloadAllThumbnails(files: self.masterFileList)

            self.masterFileList = finalResults
            return finalResults
        }

        let urlString = "http://www.bekostore.com/wp/wp-json/wp/v2/media?per_page=100&page=\(currentPage)"
        guard let url = URL(string: urlString) else {
            return []
        }

        do {
            // Use Swift Concurrency for the network request directly
            let (data, _) = try await URLSession.shared.data(from: url)

            let decoder = JSONDecoder()
            let verifiedFiles = try decoder.decode([BekoFile].self, from: data)

            self.tempFileList.append(contentsOf: verifiedFiles)

            if verifiedFiles.count < 100 {
                self.currentPage = self.maxPages + 1
            } else {
                self.currentPage += 1
            }

            // Clean, direct recursive call with await
            return await self.getFilesArray()

        } catch {
            print("Network request or mapping failed on page \(self.currentPage): \(error)")

            let errorStateFallback = self.tempFileList
            return errorStateFallback
        }
    }

    private func downloadAllThumbnails(files: [BekoFile]) async {
        for file in files {
            if let localAssetURL = file.localAssetURL,
               FileManager.default.fileExists(atPath: localAssetURL.path()) == false {
                await downloadThumbnailForFile(file: file)
            }
        }
    }

    private func downloadThumbnailForFile(file: BekoFile) async {
        do {
            guard let onlineAssetURL = file.onlineAssetURL,
            let localAssetURL = file.localAssetURL
            else {
                return
            }
            let (data, _) = try await URLSession.shared.data(from: onlineAssetURL)
            try data.write(to: localAssetURL, options: .atomic)
        } catch {
            print("Error Writing File: \(error)")
        }
    }
    private func getImageFromURLAndSave(imageName: String, fileURL: URL, in directory: URL) async {
    }
    
    func writeFilesListToFile() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

        if let documentsDirectoryPath = urls.first {
            let path = documentsDirectoryPath.appendingPathComponent("FileList.json")

            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted // Optional: makes the JSON readable
                let jsonData = try encoder.encode(self.masterFileList)
                try jsonData.write(to: path)
            } catch {
                print("Failed encoding and saving master file list to disk: \(error)")
            }
        }
    }

    func readFilesListFromFile(callback: @escaping ([BekoFile]) -> Void) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)

        if let documentsDirectoryPath = urls.first {
            let path = documentsDirectoryPath.appendingPathComponent("FileList.json")

            if fileManager.fileExists(atPath: path.path) {
                do {
                    let jsonData = try Data(contentsOf: path)

                    // ─── THIS IS WHERE THE DECODING CODE GOES FOR LOCAL DATA ───
                    let decoder = JSONDecoder()
                    // Decodes your locally saved file cache straight into your structs
                    let loadedFiles = try decoder.decode([BekoFile].self, from: jsonData)

                    self.masterFileList = loadedFiles
                    callback(loadedFiles)
                    // ─────────────────────────────────────────────────────────────

                } catch {
                    print("Error reading or decoding local JSON file: \(error)")
                    callback([])
                }
            }
        }
    }

    public func fileListFileExists() -> Bool {
        return FileManager.default.fileExists(atPath: fileListURL.path)
    }
}
