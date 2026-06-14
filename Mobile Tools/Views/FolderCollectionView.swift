//
//  FolderCollectionView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/11/26.
//


import SwiftUI

struct FolderCollectionView: View {
    // Reusable properties passed down during navigation initialization
    let docTypeName: String
    let typeCode: String

    @Environment(\.dismiss) private var dismiss

    // Explicit dynamic grid arrangement columns
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    // Safely typed fetch helper to resolve SwiftUI compiler nesting overhead
    private var folderGroups: [[String: Any]] {
        if let rawGroups = OnlineFilesManager.shared.getGroupsWithFiles(typeCode: typeCode) {
            return rawGroups
        }
        return []
    }

    var body: some View {
        NavigationStack {
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()
                .overlay(
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {

                            LazyVGrid(columns: columns, spacing: 16) {
                                // FIXED: Resolved broken brace loop syntax and type safety issues
                                ForEach(0..<folderGroups.count, id: \.self) { index in
                                    let group = folderGroups[index]
                                    let groupName = OnlineFilesManager.manager.getGroupName(group) ?? ""
                                    let filesCount = OnlineFilesManager.manager.filesFilteredByType(typeCode, group: groupName)?.count ?? 0
                                    let thumbnailName = OnlineFilesManager.manager.getGroupThumbnailPath(group) ?? ""

                                    NavigationLink(value: groupName) {
                                        FolderGridCell(
                                            title: groupName,
                                            documentCount: filesCount,
                                            imageName: thumbnailName
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 16)
                    }
                )
                .navigationTitle(docTypeName)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Home") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                    }
                }
            // Decoupled type-safe destination stack
                .navigationDestination(for: String.self) { selectedGroup in
                    Text("Document View For: \(selectedGroup)")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(ZColorTheme.darkNavyWrapper.ignoresSafeArea())
                }
        }
    }
}

// MARK: - Reusable Grid Cell Component
struct FolderGridCell: View {
    let title: String
    let documentCount: Int
    let imageName: String

    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 65, height: 65)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("\(documentCount) Documents  >")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 140)
        .background(ZColorTheme.punchyBlueButton)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Core Theme Management
struct ZColorTheme {
    static let darkNavyWrapper = Color(red: 11 / 255, green: 27 / 255, blue: 49 / 255)
    static let punchyBlueButton = Color(red: 23 / 255, green: 115 / 255, blue: 219 / 255)
}
