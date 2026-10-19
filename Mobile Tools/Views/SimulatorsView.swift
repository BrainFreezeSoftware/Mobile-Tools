//
//  SimulatorsView.swift
//  Mobile Tools
//

import SwiftUI

struct SimulatorItem: Identifiable {
    let id = UUID()
    let name: String
    let url: URL
}

struct SimulatorsView: View {
    private let items: [SimulatorItem] = [
        SimulatorItem(name: "DRYPOINT XFi", url: URL(string: "https://www.beko-technologies.us/en-us/drypoint-xfi-app/")!),
        SimulatorItem(name: "QWIK-PURE", url: URL(string: "https://www.beko-technologies.us/en-us/qwik-pure-app/")!),
        SimulatorItem(name: "DRYPOINT RA LED", url: URL(string: "https://www.beko-technologies.us/en-us/drypoint-ra-led-app/")!),
        SimulatorItem(name: "DRYPOINT RX", url: URL(string: "https://www.beko-technologies.us/en-us/drypoint-ra-gen-iii-app/")!),
        SimulatorItem(name: "DRYPOINT® MDi", url: URL(string: "https://www.beko-technologies.us/en-us/drypoint-mdi-landing/")!)
    ]

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        ZStack {
            ZColorTheme.darkNavyWrapper
                .ignoresSafeArea()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(destination: WebContentView(title: item.name, url: item.url)) {
                            SimulatorGridCell(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Simulators")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Reusable Grid Cell Component

private struct SimulatorGridCell: View {
    let item: SimulatorItem

    var body: some View {
        VStack(spacing: 12) {
            Image("Buttons/Simulators")
                .resizable()
                .scaledToFit()
                .frame(height: 140)
                .foregroundColor(.white)

            Text(item.name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(ZColorTheme.punchyBlueButton)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}
