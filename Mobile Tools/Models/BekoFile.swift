//
//  BekoFile.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/11/26.
//


import Foundation

/// Represents a type-safe media asset item from the server payload.
public struct BekoFile: Codable, Identifiable {
    public let id: Int
    public let date: String
    public let link: String
    public let mimeType: String
    
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
        let file: String
        let sizes: ImageSizes
    }
    
    private struct ImageSizes: Codable {
        let full: ImageSource
    }
    
    public struct ImageSource: Codable {
        let file: String
        let sourceUrl: String
        
        enum CodingKeys: String, CodingKey {
            case file
            case sourceUrl = "source_url"
        }
    }
    
    // MARK: - Safe Parsed Computed Properties
    
    /// Returns the clean name of the file (strips out HTML artifacts).
    public var fileName: String {
        return title.rendered
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Safely parses the complex WordPress HTML caption string into structured parts: (Type, Group, Language Codes).
    /// Expected format in CMS caption layout: "TYPE | GROUP | EN,FR,ES"
    private var captionParts: [String] {
        let cleanCaption = caption.rendered
            .replacingOccurrences(of: "<p>", with: "")
            .replacingOccurrences(of: "</p>\n", with: "")
        return cleanCaption.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    /// Extracted item type code (e.g., "Brochures", "Manuals")
    public var typeCode: String {
        return captionParts.indices.contains(0) ? captionParts[0] : ""
    }
    
    /// Extracted categorization subgroup item name
    public var groupName: String {
        return captionParts.indices.contains(1) ? captionParts[1] : ""
    }
    
    /// Safe parsed language localization arrays derived from individual item context strings
    public var languages: [String] {
        guard captionParts.indices.contains(2) else { return [] }
        return captionParts[2].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    /// Direct URL asset link location reference
    public var assetURLString: String {
        return mediaDetails.sizes.full.sourceUrl
    }
    
    /// Local cache location identity path construction
    public var targetThumbnailPath: String? {
        guard let lastComponent = assetURLString.components(separatedBy: "/").last else { return nil }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(lastComponent).path
    }
}
