//
//  WebContentView.swift
//  Mobile Tools
//

import SwiftUI
import WebKit

// Generic stylized web view screen (dark navy backdrop + loading spinner) used for
// any external URL destinations reached from the Home dashboard, e.g. e-Learning.
struct WebContentView: View {
    let title: String
    let url: URL

    @State private var isLoading = true

    var body: some View {
        ZStack {
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            StyledWebView(url: url, isLoading: $isLoading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)

            if isLoading {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - WKWebView Representable

private struct StyledWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
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
        var parent: StyledWebView

        init(_ parent: StyledWebView) {
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
