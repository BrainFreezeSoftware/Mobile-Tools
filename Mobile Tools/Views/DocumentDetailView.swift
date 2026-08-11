//
//  DocumentDetailView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 7/29/26.
//


import SwiftUI
import PDFKit
import WebKit

struct DocumentDetailView: View {
    let file: BekoFile

    @State private var isLoading = true
    @State private var showingShareSheet = false

    var body: some View {
        ZStack {
            // Dark Navy theme canvas background
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let url = documentURL {
                    // Full-screen viewer using native PDFKit or WKWebView fallback
                    DocumentContainerView(url: url, isLoading: $isLoading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    // Fallback when document URL cannot be resolved
                    VStack(spacing: 16) {
                        Image(systemName: "doc.trianglebadge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.5))

                        Text("Unable to load document")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // Loading Overlay Indicator
            if isLoading {
                ProgressView("Loading Document...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
        .navigationTitle(file.fileName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: sendOrShareDocument) {
                    Image(systemName: "square.and.pencil")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareURL = documentURL {
                ActivityViewController(activityItems: [shareURL])
            }
        }
    }
    
    // MARK: - Helper Properties & Actions

    private var documentURL: URL? {
        if let remoteURL = file.fileURL {
            return remoteURL
        }
        return nil
    }

    private func sendOrShareDocument() {
        showingShareSheet = true
    }
}

// MARK: - Native PDFView Representable (Supports Continuous Multi-Page Scrolling)

struct DocumentContainerView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> UIView {
        // Use native PDFView if path extension is PDF
        if url.pathExtension.lowercased() == "pdf" || url.absoluteString.lowercased().hasSuffix(".pdf") {
            let pdfView = PDFView()
            pdfView.autoScales = true
            pdfView.displayMode = .singlePageContinuous // Displays all pages in a vertical continuous scroll
            pdfView.displayDirection = .vertical
            pdfView.backgroundColor = .clear

            DispatchQueue.global(qos: .userInitiated).async {
                let doc = PDFDocument(url: url)
                DispatchQueue.main.async {
                    pdfView.document = doc
                    self.isLoading = false
                }
            }
            return pdfView
        } else {
            // Fallback to WKWebView for web pages or non-PDF files
            let webView = WKWebView()
            webView.isOpaque = false
            webView.backgroundColor = .clear
            webView.navigationDelegate = context.coordinator
            webView.load(URLRequest(url: url))
            return webView
        }
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Do NOT reload in updateUIView to prevent re-render loops
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DocumentContainerView

        init(_ parent: DocumentContainerView) {
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

// MARK: - UIActivityViewController Sheet for Email / Share Actions

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
