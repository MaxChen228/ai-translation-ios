// ModernDesignSystem.swift - 現代美學設計系統

import SwiftUI

// MARK: - 現代色彩系統
extension Color {
    // 主色調 - 溫暖駝色系
    static let modernBackground = Color(hex: "#e3dacd")      // 駝色背景
    static let modernSurface = Color(hex: "#f5f2ed")         // 卡片表面
    static let modernSurfaceElevated = Color.white           // 高層次表面
    
    // 文字色彩層次
    static let modernTextPrimary = Color(hex: "#4d4442")     // 深咖啡主文字
    static let modernTextSecondary = Color(hex: "#8b7d77")   // 次要文字
    static let modernTextTertiary = Color(hex: "#c4b5ad")    // 三級文字
    
    // 功能色彩
    static let modernAccent = Color(hex: "#da7453")          // 橙棕強調色
    static let modernAccentSoft = Color(hex: "#da7453").opacity(0.15) // 柔和強調
    static let modernSpecial = Color(hex: "#389bff")         // 藍色特殊狀態
    static let modernSpecialSoft = Color(hex: "#389bff").opacity(0.15)
    
    // 狀態色彩（融入暖色調）
    static let modernSuccess = Color(hex: "#7ba05b")         // 溫暖綠
    static let modernWarning = Color(hex: "#d49c3d")         // 暖黃
    static let modernError = Color(hex: "#c85a54")           // 暖紅
    
    // 邊框和分隔線
    static let modernBorder = Color(hex: "#d4c5b9")          // 邊框色
    static let modernDivider = Color(hex: "#e8ddd4")         // 分隔線色
    
    // Hex Color Extension
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 現代圓角系統
struct ModernRadius {
    static let xs: CGFloat = 4    // 小元素：標籤、徽章
    static let sm: CGFloat = 8    // 按鈕、輸入框
    static let md: CGFloat = 12   // 卡片、面板
    static let lg: CGFloat = 16   // 大卡片、模態
    static let xl: CGFloat = 20   // 特大容器
    static let full: CGFloat = 999 // 圓形元素
}

// MARK: - 現代間距系統
struct ModernSpacing {
    static let xs: CGFloat = 4     // 緊密元素
    static let sm: CGFloat = 8     // 小間距
    static let md: CGFloat = 16    // 標準間距
    static let lg: CGFloat = 24    // 大間距
    static let xl: CGFloat = 32    // 超大間距
    static let xxl: CGFloat = 48   // 區塊間距
}

// MARK: - 現代陰影系統
struct ModernShadow {
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    static let subtle = ShadowStyle(
        color: Color.black.opacity(0.03),
        radius: 2, x: 0, y: 1
    )
    
    static let soft = ShadowStyle(
        color: Color.black.opacity(0.04),
        radius: 4, x: 0, y: 2
    )
    
    static let medium = ShadowStyle(
        color: Color.black.opacity(0.06),
        radius: 8, x: 0, y: 4
    )
}

// MARK: - View Extensions for Modern Design
extension View {
    // 現代卡片樣式
    func modernCard(_ style: ModernCardStyle = .standard) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(style.backgroundColor)
                    .shadow(color: style.shadow.color, radius: style.shadow.radius, x: style.shadow.x, y: style.shadow.y)
            }
    }
    
    // 現代按鈕樣式
    func modernButton(_ style: ModernButtonStyle = .primary) -> some View {
        self
            .padding(.horizontal, ModernSpacing.md)
            .padding(.vertical, ModernSpacing.sm + 2)
            .background {
                RoundedRectangle(cornerRadius: ModernRadius.sm)
                    .fill(style.backgroundColor)
                    .overlay {
                        if style.hasBorder {
                            RoundedRectangle(cornerRadius: ModernRadius.sm)
                                .stroke(style.borderColor, lineWidth: 1)
                        }
                    }
            }
    }
    
    // 現代輸入框樣式
    func modernInput(isFocused: Bool = false) -> some View {
        self
            .padding(ModernSpacing.md)
            .background {
                RoundedRectangle(cornerRadius: ModernRadius.sm)
                    .fill(Color.modernSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: ModernRadius.sm)
                            .stroke(
                                isFocused ? Color.modernAccent : Color.modernBorder,
                                lineWidth: isFocused ? 1.5 : 1
                            )
                    }
            }
    }
}

// MARK: - Modern Style Definitions
enum ModernCardStyle {
    case standard, elevated, subtle
    
    var backgroundColor: Color {
        switch self {
        case .standard: return .modernSurface
        case .elevated: return .modernSurfaceElevated
        case .subtle: return .modernBackground
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .standard, .elevated: return ModernRadius.md
        case .subtle: return ModernRadius.sm
        }
    }
    
    var shadow: ModernShadow.ShadowStyle {
        switch self {
        case .standard: return ModernShadow.soft
        case .elevated: return ModernShadow.medium
        case .subtle: return ModernShadow.subtle
        }
    }
}

enum ModernButtonStyle {
    case primary, secondary, tertiary, special
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .modernAccent
        case .secondary: return .modernAccentSoft
        case .tertiary: return .clear
        case .special: return .modernSpecial
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary, .special: return .white
        case .secondary: return .modernAccent
        case .tertiary: return .modernTextSecondary
        }
    }
    
    var hasBorder: Bool {
        switch self {
        case .tertiary: return true
        default: return false
        }
    }
    
    var borderColor: Color {
        return .modernBorder
    }
}