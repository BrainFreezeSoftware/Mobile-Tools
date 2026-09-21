//
//  VideoPlayerView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 9/21/26.
//

import SwiftUI
import WebKit

struct VideoPlayerView: View {
    let video: YouTubeVideo

    @State private var isLoading = true

    var body: some View {
        ZStack {
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            if let url = playerURL {
                YouTubeEmbedWebView(url: url, isLoading: $isLoading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
            }

            if isLoading {
                ProgressView("Loading Video...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .navigationTitle(video.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // Preserves the legacy Beko app's YouTube embed wrapper page
    private var playerURL: URL? {
        URL(string: "https://islipsonline.com/youtube.html?v=\(video.videoId)&autoplay=1")
    }
}

// MARK: - WKWebView Representable

private struct YouTubeEmbedWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Do NOT reload in updateUIView to prevent re-render loops
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: YouTubeEmbedWebView

        init(_ parent: YouTubeEmbedWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}
