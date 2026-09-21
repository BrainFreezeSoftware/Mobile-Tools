//
//  YouTubeManager.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 9/21/26.
//

import Foundation

public enum YouTubePlaylist: String, CaseIterable {
    case us = "PL-9rlvh1BMleL4gOseLKsjOxe9Tf2flsn"
    case latinAmerica = "PL-9rlvh1BMleQXKvGyGPX1vD6OT2zePMw"

    public var name: String {
        switch self {
        case .us: return "US"
        case .latinAmerica: return "Latin America"
        }
    }
}

public final class YouTubeManager: NSObject {
    public static let manager = YouTubeManager()

    // Same key/playlists used by the legacy Beko app's YTManager
    private static let apiKey = "AIzaSyB5_Nez-tVfqEXRNTofTvA7TOvSz1QJHSY"

    private override init() {
        super.init()
    }

    public func getVideos(playlist: YouTubePlaylist) async -> [YouTubeVideo] {
        let urlString = "https://www.googleapis.com/youtube/v3/playlistItems?key=\(Self.apiKey)&playlistId=\(playlist.rawValue)&part=snippet,id&order=date&maxResults=20"
        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PlaylistItemsResponse.self, from: data)

            return response.items.compactMap { item in
                guard let videoId = item.snippet.resourceId.videoId else { return nil }
                let thumbnailURLString = item.snippet.thumbnails.high?.url
                    ?? item.snippet.thumbnails.medium?.url
                    ?? item.snippet.thumbnails.defaultThumbnail?.url
                    ?? ""

                return YouTubeVideo(videoId: videoId, title: item.snippet.title, thumbnailURLString: thumbnailURLString)
            }
        } catch {
            print("Error fetching YouTube playlist videos: \(error)")
            return []
        }
    }

    // MARK: - Decoding Types

    private struct PlaylistItemsResponse: Decodable {
        let items: [PlaylistItem]
    }

    private struct PlaylistItem: Decodable {
        let snippet: Snippet
    }

    private struct Snippet: Decodable {
        let title: String
        let thumbnails: Thumbnails
        let resourceId: ResourceId
    }

    private struct ResourceId: Decodable {
        let videoId: String?
    }

    private struct Thumbnails: Decodable {
        let defaultThumbnail: Thumbnail?
        let medium: Thumbnail?
        let high: Thumbnail?

        enum CodingKeys: String, CodingKey {
            case defaultThumbnail = "default"
            case medium
            case high
        }
    }

    private struct Thumbnail: Decodable {
        let url: String
    }
}
