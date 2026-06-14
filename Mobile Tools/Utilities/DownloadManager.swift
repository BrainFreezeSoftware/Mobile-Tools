//
//  DownloadManager.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import Foundation

@MainActor
public final class DownloadManager: NSObject {
    
    public static let manager = DownloadManager()

    private var masterFileList: [BekoFile] = []
    private var tempFileList: [[String: Any]] = []
    
    private var currentPage: Int = 1
    private var maxPages: Int = 3
    
    private override init() {
        super.init()
    }
    
    private var fileListURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("FileList.json")
    }
    
    public func getFilesArray(callback: @escaping ([BekoFile]) -> Void) {
        if tempFileList.isEmpty {
            tempFileList = []
            currentPage = 1
            maxPages = 3
        }
        
        if currentPage == 1 {
            readFilesListFromFile(callback: callback)
        }
        
        let urlString = "http://www.bekostore.com/wp/wp-json/wp/v2/media?per_page=100&page=\(currentPage)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let jsonData = data, error == nil {

                // ─── THIS IS WHERE THE DECODING CODE GOES FOR NETWORK DATA ───
                do {
                    let decoder = JSONDecoder()
                    // Decodes the data into an array of type-safe BekoFile structures
                    let verifiedFiles = try decoder.decode([BekoFile].self, from: jsonData)

                    DispatchQueue.main.async {
                        self.masterFileList = verifiedFiles
                        callback(verifiedFiles)
                    }
                } catch {
                    print("Failed mapping network models securely: \(error)")
                    DispatchQueue.main.async { callback([]) }
                }
                // ─────────────────────────────────────────────────────────────

            } else {
                DispatchQueue.main.async { callback([]) }
            }
        }.resume()
    }
    
    private func downloadAllThumbnails(files: [BekoFile]) async {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for file in files {
            guard let sourceURLString = OnlineFilesManager.manager.getFileThumbnailPath(file),
                  let sourceURL = URL(string: sourceURLString) else { continue }
            
            let imgName = sourceURL.lastPathComponent
            let writableURL = documentsDirectory.appendingPathComponent(imgName)
            
            if !FileManager.default.fileExists(atPath: writableURL.path) && !imgName.isEmpty {
                await getImageFromURLAndSave(imageName: imgName, fileURL: sourceURL, in: documentsDirectory)
            }
        }
    }
    
    private func getImageFromURLAndSave(imageName: String, fileURL: URL, in directory: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: fileURL)
            let fileURLToSave = directory.appendingPathComponent(imageName)
            try data.write(to: fileURLToSave, options: .atomic)
            print("Image \(imageName) Saved Successfully")
        } catch {
            print("Error Writing File: \(error)")
        }
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
