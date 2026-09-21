//
//  YouTubeVideo.swift
//  Mobile Tools
//

import Foundation

public struct YouTubeVideo: Identifiable, Hashable {
    public let videoId: String
    public let title: String
    public let thumbnailURLString: String

    public var id: String { videoId }

    public var thumbnailURL: URL? {
        URL(string: thumbnailURLString)
    }
}
