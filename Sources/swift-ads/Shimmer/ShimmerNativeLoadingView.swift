//
//  ShimmerNativeLoadingView.swift
//  AdsSwift
//
//  Created by VanTuan8802 on 13/8/26.
//

import SwiftUI
import GoogleMobileAds

struct ShimmerNativeLoadingView: View {
    let style: NativeAdViewStyle
    let height: CGFloat?
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            if style == .nativeLargeMediaCtaTop || style == .nativeLargeMediaCtaBottom {
                LargeShimmerView()
            } else {
                NormalShimmerView()
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

struct LargeShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(height: 8)
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(shimmerGradient)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(width: 40, height: 16)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(shimmerGradient)
                        .frame(height: 20)
                }

                Spacer()
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(height: 150)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 200, height: 16)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(height: 44)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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

struct NormalShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(shimmerGradient)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 40, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 18)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(width: 120, height: 14)
                
                RoundedRectangle(cornerRadius: 6)
                    .fill(shimmerGradient)
                    .frame(width: 80, height: 32)
            }

            Spacer()
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
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
