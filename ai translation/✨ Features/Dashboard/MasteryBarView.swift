// MasteryBarView.swift

import SwiftUI

struct MasteryBarView: View {
    let masteryLevel: Double
    let totalLevel: Double = 5.0 // 總等級設為 5.0
    
    // 根據熟練度決定顏色
    private var barColor: Color {
        if masteryLevel < 1.5 {
            return Color.modernError
        } else if masteryLevel < 3.5 {
            return Color.modernWarning
        } else {
            return Color.modernSuccess
        }
    }
    
    var body: some View {
        // 使用 GeometryReader 來獲取父容器的尺寸，讓血條可以自適應寬度
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 1. 血條的背景 (底色)
                Capsule()
                    .frame(width: geometry.size.width, height: 12)
                    .foregroundStyle(Color.modernTextTertiary.opacity(0.3))
                
                // 2. 血條的前景 (實際的熟練度)
                Capsule()
                    .frame(width: (masteryLevel / totalLevel) * geometry.size.width, height: 12)
                    .foregroundStyle(barColor)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: masteryLevel)
            }
        }
        .frame(height: 12) // 限制整個元件的高度
    }
}
