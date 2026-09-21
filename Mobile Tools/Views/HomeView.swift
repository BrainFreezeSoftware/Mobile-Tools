//
//  HomeView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import SwiftUI

// MARK: - Navigation Destination Enum
enum DashboardDestination: Identifiable, CaseIterable {
    case videos, manuals, brochures
    case techDrawings, presentations, priceBooks
    case onlineInventory, eLearning, simulators
    case contactUs

    var id: Self { self }

    var title: String {
        switch self {
        case .videos: return "Videos"
        case .manuals: return "Manuals"
        case .brochures: return "Brochures"
        case .techDrawings: return "Tech Drawings"
        case .presentations: return "Presentations"
        case .priceBooks: return "Price Books"
        case .onlineInventory: return "Online Inventory"
        case .eLearning: return "e-Learning"
        case .simulators: return "Simulators"
        case .contactUs: return "Contact Us"
        }
    }
}

// MARK: - Grid Item Model
struct GridItemModel: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    var increaseWidth: CGFloat = 0.0
    let destination: DashboardDestination
}

// MARK: - Main Home View
struct HomeView: View {
    let gridItems: [GridItemModel] = [
        GridItemModel(title: "Videos", iconName: "Buttons/Videos", destination: .videos),
        GridItemModel(title: "Manuals", iconName: "Buttons/Manuals", destination: .manuals),
        GridItemModel(title: "Brochures", iconName: "Buttons/Brochures", destination: .brochures),
        GridItemModel(title: "Tech Drawings", iconName: "Buttons/Tech Drawings", destination: .techDrawings),
        GridItemModel(title: "Presentations", iconName: "Buttons/Presentations", destination: .presentations),
        GridItemModel(title: "Price Books", iconName: "Buttons/Price Books", destination: .priceBooks),
        GridItemModel(title: "Online Inventory", iconName: "Buttons/Online Inventory", increaseWidth: 10, destination: .onlineInventory),
        GridItemModel(title: "e-Learning", iconName: "Buttons/e-Learning", increaseWidth: 24.0, destination: .eLearning),
        GridItemModel(title: "Simulators", iconName: "Buttons/Simulators", destination: .simulators)
    ]

    @State private var isLoading: Bool = true
    @State private var loadingMessage: String = "Loading application files..."
    @State private var navigationPath = NavigationPath()

    // Centralizing application base color theme
    private let appBackgroundColor = Color(red: 3/255, green: 32/255, blue: 74/255)

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                let isPad = geometry.size.width > 600

                ZStack(alignment: .bottom) {
                    // Core Application Dark Background tint
                    appBackgroundColor
                        .ignoresSafeArea()

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {

                            // MARK: - Hero & Logo Header Stack
                            ZStack(alignment: .top) {
                                // Hero Asset fits perfectly to container bounds
                                Image("Hero Image")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height * (isPad ? 0.36 : 0.30))
                                    .clipped()
                                // Overlaying the original design gradient built strictly into code
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.black.opacity(0.2), // Subtle shadow at top for text visibility
                                                Color.clear,              // Main image body clear zone
                                                appBackgroundColor        // Fades perfectly down into background color
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )

                                // Floating Branding Row
                                HStack(alignment: .top) {
                                    Text("BEKO USA Tools+")
                                        .font(.custom("KievitOffcPro-Bold", size: isPad ? 26 : 22))
                                        .foregroundColor(.white)
                                        .padding(.top, isPad ? 16 : 12)

                                    Spacer()

                                    Image("beko_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: isPad ? 140 : 66, height: isPad ? 95 : 86)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                // Standard comfortable spacing since the Safe Area is handled natively by parent
                                .padding(.top, 16)
                            }

                            // MARK: - Responsive Action Grid
                            let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: isPad ? 4 : 3)

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(gridItems) { item in
                                    NavigationLink(value: item.destination) {
                                        MenuButtonView(item: item, isPad: isPad)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 24)
                            // Provides empty scrolling buffer space over fixed footer item
                            .padding(.bottom, isPad ? 100 : 80)
                        }
                    }

                    // MARK: - Sticky Footer Contact Panel
                    VStack(spacing: 0) {
                        NavigationLink(value: DashboardDestination.contactUs) {
                            Text("Contact Us")
                                .font(.custom("KievitOffcPro-Medium", size: isPad ? 19 : 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: isPad ? 58 : 48)
                                .background(Color(red: 0/255, green: 91/255, blue: 171/255))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 12)
                    }
                    // Background gradient shield so grid elements slide cleanly behind the footer button
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [appBackgroundColor.opacity(0.0), appBackgroundColor.opacity(0.95), appBackgroundColor]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // MARK: - Conditional Loading Progress Overlay
                    if isLoading {
                        LoadingOverlayView(message: loadingMessage, isPad: isPad)
                            .transition(.opacity.animation(.easeInOut(duration: 0.25)))
                    }
                }
            }
            .navigationDestination(for: DashboardDestination.self) { destination in
                switch destination {
                case .videos:
                    VideosView()
                case .manuals:
                    FolderCollectionView(docTypeName: destination.title, fileType: .manual)
                case .brochures:
                    OnlineDocCollectionView(docTypeName: destination.title, fileType: .brochure, group: "")
                case .techDrawings:
                    FolderCollectionView(docTypeName: destination.title, fileType: .drawing)
                case .presentations:
                    OnlineDocCollectionView(docTypeName: destination.title, fileType: .presentation, group: "")
                case .priceBooks:
                    OnlineDocCollectionView(docTypeName: destination.title, fileType: .priceBook, group: "")
                default:
                    PlaceholderDetailView(destination: destination)
                }
            }
        }
        .onAppear {
            isLoading = true
            OnlineFilesManager.manager.setupFiles { success in
                withAnimation {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Custom Reusable Grid Button
struct MenuButtonView: View {
    let item: GridItemModel
    let isPad: Bool

    var body: some View {
        let edgeInset: CGFloat = isPad ? 16 : 12

        VStack(alignment: .leading, spacing: 0) {
            Text(item.title)
                .font(.custom("KievitOffcPro-Medium", size: isPad ? 20 : 16))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.top, edgeInset)
                .padding(.leading, edgeInset)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)

            Spacer()

            HStack {
                Spacer()
                Image(item.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isPad ? 100 + item.increaseWidth : 70 + item.increaseWidth, height: isPad ? 100 : 70)
                    .foregroundColor(.white)
                Spacer()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: isPad ? 135 : 108)
        .background(Color(red: 0/255, green: 91/255, blue: 171/255))
        .cornerRadius(6)
    }
}

// MARK: - Destination Detail View Placeholder
struct PlaceholderDetailView: View {
    let destination: DashboardDestination

    var body: some View {
        ZStack {
            Color(red: 3/255, green: 32/255, blue: 74/255).ignoresSafeArea()
            Text("\(destination.title) Screen")
                .font(.custom("KievitOffcPro-Bold", size: 24))
                .foregroundColor(.white)
        }
        .navigationTitle(destination.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SwiftUI Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 15 Pro"))
        HomeView()
            .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
    }
}
