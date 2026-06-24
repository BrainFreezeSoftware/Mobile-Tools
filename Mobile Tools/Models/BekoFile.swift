//
//  BekoFile.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/11/26.
//


import Foundation

public enum FileType: String, Codable {
    case manual = "MAN"
    case brochure = "BRO"
    case drawing = "DRA"
    case presentation = "PRE"
    case priceBook = "PRI"
    case group = "GROUP"
}

public enum FileLanguage: String, Codable {
    case english = "EN"
    case spanish = "ES"
    case french = "FR"
    case portuguese = "PT"
}

public struct BekoFile: Codable, Identifiable {
    public let id: Int
    public let date: String
    public let link: String
    public let mimeType: String

    // Strongly-typed data properties populated directly via custom encoding/decoding
    public let fileType: FileType
    public let groupName: String
    public let languages: [FileLanguage]

    private let title: RenderedText
    private let caption: RenderedText
    private let mediaDetails: MediaDetails

    enum CodingKeys: String, CodingKey {
        case id, date, link, title, caption
        case mimeType = "mime_type"
        case mediaDetails = "media_details"
    }

    // MARK: - Helper Nested Structural Types
    private struct RenderedText: Codable {
        let rendered: String
    }

    private struct MediaDetails: Codable {
        let file: String?
        let sizes: ImageSizes
    }

    private struct ImageSizes: Codable {
        let full: ImageSource?
        let thumbnail: ImageSource?
    }

    public struct ImageSource: Codable {
        let file: String?
        let sourceUrl: String

        enum CodingKeys: String, CodingKey {
            case file
            case sourceUrl = "source_url"
        }
    }

    // MARK: - Custom Decoder Init
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode standard fields
        self.id = try container.decode(Int.self, forKey: .id)
        self.date = try container.decode(String.self, forKey: .date)
        self.link = try container.decode(String.self, forKey: .link)
        self.mimeType = try container.decode(String.self, forKey: .mimeType)
        self.title = try container.decode(RenderedText.self, forKey: .title)
        self.mediaDetails = try container.decode(MediaDetails.self, forKey: .mediaDetails)

        // Decode raw caption data
        let decodedCaption = try container.decode(RenderedText.self, forKey: .caption)
        self.caption = decodedCaption

        // Inline extraction and sanitization mapping
        let cleanCaption = decodedCaption.rendered
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "\n", with: "")

        let components = cleanCaption.components(separatedBy: "|").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Populate strongly-typed properties safely
        let rawType = components.indices.contains(0) ? components[0] : ""
        self.fileType = FileType(rawValue: rawType.uppercased()) ?? .manual

        if components.count > 2 {
            self.groupName = components.indices.contains(2) ? components[2] : ""
        }
        else if fileType == .group {
            groupName = components.indices.contains(1) ? components[1] : ""
        }
        else {
            self.groupName = ""
        }

        if components.indices.contains(1) {
            self.languages = components[1]
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
                .compactMap { FileLanguage(rawValue: $0) }
        } else {
            self.languages = []
        }
    }

    // MARK: - Custom Encoder Hook
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(link, forKey: .link)
        try container.encode(mimeType, forKey: .mimeType)
        try container.encode(title, forKey: .title)
        try container.encode(mediaDetails, forKey: .mediaDetails)

        // Synthesizes the custom string component safely back into expected CMS caption format
        let rawLangs = languages.map { $0.rawValue }.joined(separator: ",")
        let assembledCaption = "\(fileType.rawValue) | \(groupName) | \(rawLangs)"
        try container.encode(RenderedText(rendered: assembledCaption), forKey: .caption)
    }

    // MARK: - Safe Parsed Computed Properties

    /// Returns the clean name of the file (strips out HTML artifacts).
    public var fileName: String {
        return title.rendered
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Fallback logic: GROUP type uses 'full', others use 'thumbnail'
    public var assetURLString: String? {
        if fileType == .group {
            return mediaDetails.sizes.full?.sourceUrl ?? mediaDetails.sizes.thumbnail?.sourceUrl
        } else {
            return mediaDetails.sizes.thumbnail?.sourceUrl ?? mediaDetails.sizes.full?.sourceUrl
        }
    }

    public var onlineAssetURL: URL? {
        guard let assetURLString else { return nil }
        return URL(string: assetURLString)
    }

    public var localAssetURL: URL? {
        guard let urlString = assetURLString,
              let lastComponent = urlString.components(separatedBy: "/").last else { return nil }

        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(lastComponent)
    }
}
