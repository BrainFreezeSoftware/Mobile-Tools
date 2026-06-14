//
//  LoadingOverlayView.swift
//  Mobile Tools
//
//  Created by Steve Stasinos on 6/9/26.
//

import SwiftUI

struct LoadingOverlayView: View {
    let message: String
    let isPad: Bool
    
    var body: some View {
        ZStack {
            // Semi-transparent dark overlay covering full screen bounds
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // Centered visual loading platter card
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(isPad ? 1.5 : 1.2)
                
                Text(message)
                    .font(.custom("KievitOffcPro-Medium", size: isPad ? 16 : 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            // Translucent frosted glass panel styling block
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 3/255, green: 32/255, blue: 74/255).opacity(0.85))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 40)
        }
    }
}
