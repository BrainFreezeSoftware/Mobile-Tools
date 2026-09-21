//
//  VideosView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 9/21/26.
//

import SwiftUI

struct VideosView: View {
    @State private var videos: [YouTubeVideo] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedPlaylistIndex = 0

    private let playlists = YouTubePlaylist.allCases
    private let columns = [GridItem(.flexible(), spacing: 16)]

    private var filteredVideos: [YouTubeVideo] {
        guard !searchText.isEmpty else { return videos }
        return videos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack {
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                SearchBarView(text: $searchText, placeholder: "Search videos...")
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                Picker("Playlist", selection: $selectedPlaylistIndex) {
                    ForEach(playlists.indices, id: \.self) { index in
                        Text(playlists[index].name).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))

                Divider()
                    .background(Color.white.opacity(0.1))

                ScrollView {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 60)
                    } else if filteredVideos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.4))
                            Text("No Videos Found")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredVideos) { video in
                                NavigationLink(destination: VideoPlayerView(video: video)) {
                                    VideoGridCell(video: video)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedPlaylistIndex) {
            isLoading = true
            videos = await YouTubeManager.manager.getVideos(playlist: playlists[selectedPlaylistIndex])
            isLoading = false
        }
    }
}

// MARK: - Video Grid Cell

private struct VideoGridCell: View {
    let video: YouTubeVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.2))
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 30))
                        )
                }
            }

            Text(video.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(ZColorTheme.punchyBlueButton)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - SwiftUI Preview

struct VideosView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            VideosView()
        }
    }
}
