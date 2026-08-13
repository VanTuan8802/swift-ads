//
//  ShimmerBannerLoadingView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI

struct ShimmerBannerLoadingView: View {
    let height: CGFloat
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(shimmerGradient)
            .frame(height: height)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray5),
                Color(.systemGray4),
                Color(.systemGray5)
            ]),
            startPoint: isAnimating ? UnitPoint(x: -1, y: 0) : UnitPoint(x: 0, y: 0),
            endPoint: isAnimating ? UnitPoint(x: 1, y: 0) : UnitPoint(x: 2, y: 0)
        )
    }
}
