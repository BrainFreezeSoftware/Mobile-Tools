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
    let fileType: FileType

    @Environment(\.dismiss) private var dismiss

    // Explicit dynamic grid arrangement columns
    private let columns = [
        GridItem(.flexible(), spacing: 16)
    ]

    // Safely typed fetch helper utilizing the enum's raw string representation
    private var folderGroups: [BekoFile] {
        OnlineFilesManager.manager.getGroupsWithFileType(fileType: fileType)
    }

    var body: some View {
        ZStack {
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(folderGroups) { group in
                            let groupName = group.groupName

                            NavigationLink(value: groupName) {
                                FolderGridCell(file: group)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle(docTypeName)
        .navigationBarTitleDisplayMode(.inline)
        // Decoupled type-safe destination stack hook [cite: 1038]
        .navigationDestination(for: String.self) { selectedGroup in
            OnlineDocCollectionView(docTypeName: docTypeName, fileType: fileType, group: selectedGroup)
        }
    }
}

// MARK: - Reusable Grid Cell Component
struct FolderGridCell: View {
    let file: BekoFile

    var body: some View {
        VStack(spacing: 12) {
            if let imageURL = file.localAssetURL {
                Image(contentsOf: imageURL, fallbackName: "")
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .shadow(radius: 10.0)
            }

            VStack(spacing: 4) {
                Text(file.groupName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                .lineLimit(2)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 200)
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
