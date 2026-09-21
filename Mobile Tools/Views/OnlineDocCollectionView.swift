//
//  OnlineDocCollectionView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/25/26.
//

import SwiftUI

struct OnlineDocCollectionView: View {
    // Reusable view properties passed down during navigation
    let docTypeName: String
    let fileType: FileType
    let group: String
    let singleColumn: Bool = true

    // Core data sources mapped from your updated OnlineFilesManager
    @State private var searchText = ""
    @State private var selectedLanguageIndex = 0
    @State private var selectedFiles: Set<BekoFile> = []

    @Environment(\.dismiss) private var dismiss

    var currentLanguage = FileLanguage.english // Default language selection
    private let languageFilters: [FileLanguage] = [.english, .spanish, .french, .portuguese]
    private var columns: [GridItem] {
        if fileType.usesSingleColumnGrid {
            return [GridItem(.flexible(), spacing: 16)] // Single column wide rows
        } else {
            return [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 16)]
        }
    }

    // Combined Filter Logic matching original NSPredicate block
    private var filteredFiles: [BekoFile] {
        let baseFiles = OnlineFilesManager.manager.filesFilteredByFileType(fileType: fileType, group: group)

        return baseFiles.filter { file in
            // Search text title matching
            let matchesSearch = searchText.isEmpty ||
            file.fileName.localizedCaseInsensitiveContains(searchText)

            if matchesSearch {
                let currentLanguage = languageFilters[selectedLanguageIndex]
                let matchesLanguage = file.languages.contains(currentLanguage)

                return matchesLanguage
            }

            return matchesSearch
        }
    }

    var body: some View {
        ZStack {
            // Theme Background Canvas
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar Container
                SearchBarView(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                // Language Filter Segmented Picker
                Picker("Language", selection: $selectedLanguageIndex) {
                    ForEach(0..<languageFilters.count, id: \.self) { index in
                        Text(languageFilters[index].name).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))

                Divider()
                    .background(Color.white.opacity(0.1))

                // Documents Grid Area
                ScrollView {
                    if filteredFiles.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(.white.opacity(0.4))
                            Text("No Documents Found")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredFiles, id: \.id) { file in
                                // NavigationLink transitions to detail view on main tap
                                NavigationLink(destination: DocumentDetailView(file: file)) {
                                    DocumentGridCell(
                                        file: file,
                                        showFileName: fileType.showFileName,
                                        isSelected: selectedFiles.contains(file),
                                        onToggleSelection: {
                                            toggleSelection(for: file)
                                        }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle(docTypeName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    // Clear Selection Action
                    if !selectedFiles.isEmpty {
                        Button("Clear") {
                            selectedFiles.removeAll()
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    }

                    // Compose/Send Action Email trigger
                    Button(action: sendSelectedFilesByEmail) {
                        Image(systemName: "square.and.pencil")
                            .imageScale(.large)
                            .foregroundColor(.white)
                    }
                    .disabled(selectedFiles.isEmpty)
                    .opacity(selectedFiles.isEmpty ? 0.5 : 1.0)
                }
            }
        }
    }

    // MARK: - Core Action Handlers

    private func toggleSelection(for file: BekoFile) {
        if selectedFiles.contains(file) {
            selectedFiles.remove(file)
        } else {
            selectedFiles.insert(file)
        }
    }

    private func sendSelectedFilesByEmail() {
        let filePaths = selectedFiles.compactMap { $0.localAssetURL }
        print("Triggering mail composition composer context for \(filePaths.count) files.")
    }
}

// MARK: - Dedicated Document Cell Component

struct DocumentGridCell: View {
    let file: BekoFile
    let showFileName: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void

    var body: some View {
        // Standard Sheet Aspect Ratio Layout (1 : 1.414 ratio matches standard paper/A4)
        VStack(alignment: .center, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                cellThumbnailImage
                    .cornerRadius(8)
                    .clipped()

                selectionIndicator
                    .padding(8)
            }

            if showFileName {
                Text(file.fileName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
        }
        .padding(4)
        .background(ZColorTheme.punchyBlueButton)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
        )
    }

    private var cellThumbnailImage: some View {
        Group {
            if let imageURL = file.localAssetURL {
                Image(contentsOf: imageURL, fallbackName: "doc.text.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "doc.text.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(10)
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }

    // Dedicated tap target for selection logic
    private var selectionIndicator: some View {
        Button(action: {
            onToggleSelection()
        }) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .font(.system(size: 22, weight: .medium))
                .background(Circle().fill(Color.black.opacity(0.3)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Internal SearchBar View

struct SearchBarView: View {
    @Binding var text: String
    var placeholder: String = "Search documents..."

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))

            TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.12))
        .cornerRadius(10)
    }
}
