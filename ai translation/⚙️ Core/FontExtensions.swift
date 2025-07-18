// FontExtensions.swift - 全域字體管理系統
// 位置：ai translation/⚙️ Core/FontExtensions.swift

import SwiftUI
import UIKit

// MARK: - 字體類型定義

enum AppFontStyle {
    case chineseDefault      // 中文預設（思源宋體）
    case englishRounded      // 英文圓潤
    case englishSerif        // 英文襯線（Times New Roman 類型）
    case system              // 系統字體（後備方案）
}

enum AppFontWeight {
    case light
    case regular
    case medium
    case semibold
    case bold
    
    var uiWeight: UIFont.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
    
    var swiftUIWeight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

// MARK: - 字體管理器

struct AppFont {
    
    // 字體名稱常數 - 使用正確的 Variable Font 名稱
    private struct FontNames {
        // 中文字體：使用思源宋體 Variable Font（根據控制台輸出的正確名稱）
        static let chineseSerif = "SourceHanSerifTCVF-Regular"
        static let chineseSerifBold = "SourceHanSerifTCVF-Bold"
        static let chineseSerifLight = "SourceHanSerifTCVF-Light"
        
        // 英文圓潤字體：使用系統圓角字體
        static let englishRounded = "SFRounded-Regular"
        static let englishRoundedBold = "SFRounded-Bold"
        static let englishRoundedMedium = "SFRounded-Medium"
        static let englishRoundedLight = "SFRounded-Light"
        
        // 英文襯線字體：使用系統內建的襯線字體
        static let englishSerif = "TimesNewRomanPSMT"
        static let englishSerifBold = "TimesNewRomanPS-BoldMT"
        
        // 系統字體（後備方案）
        static let systemFont = "SFProText-Regular"
        static let systemFontBold = "SFProText-Bold"
        static let systemFontMedium = "SFProText-Medium"
        static let systemFontLight = "SFProText-Light"
    }
    
    // 智慧字體選擇 - 根據文字內容自動選擇合適字體
    static func smartFont(for text: String, size: CGFloat, weight: AppFontWeight = .regular) -> Font {
        let fontStyle = detectFontStyle(for: text)
        return font(style: fontStyle, size: size, weight: weight)
    }
    
    // UIFont 版本的智慧字體選擇
    static func smartUIFont(for text: String, size: CGFloat, weight: AppFontWeight = .regular) -> UIFont {
        let fontStyle = detectFontStyle(for: text)
        return uiFont(style: fontStyle, size: size, weight: weight)
    }
    
    // 指定字體樣式
    static func font(style: AppFontStyle, size: CGFloat, weight: AppFontWeight = .regular) -> Font {
        let fontName = getFontName(for: style, weight: weight)
        if let customFont = UIFont(name: fontName, size: size) {
            return Font(customFont)
        }
        // 後備方案：使用系統字體
        return .system(size: size, weight: weight.swiftUIWeight)
    }
    
    // UIFont 版本
    static func uiFont(style: AppFontStyle, size: CGFloat, weight: AppFontWeight = .regular) -> UIFont {
        let fontName = getFontName(for: style, weight: weight)
        return UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size, weight: weight.uiWeight)
    }
    
    // 偵測文字主要語言並選擇字體樣式
    private static func detectFontStyle(for text: String) -> AppFontStyle {
        // 計算中文字符比例
        let chineseRange = text.range(of: "[\u{4e00}-\u{9fff}]", options: .regularExpression)
        let hasChinese = chineseRange != nil
        
        // 計算中文字符數量
        let chineseCount = text.filter { char in
            return "\u{4e00}" <= char && char <= "\u{9fff}"
        }.count
        
        let totalCount = text.count
        let chineseRatio = totalCount > 0 ? Double(chineseCount) / Double(totalCount) : 0.0
        
        // 如果中文字符比例超過 30%，使用中文字體
        if chineseRatio > 0.3 || hasChinese {
            return .chineseDefault
        }
        
        // 判斷英文內容的類型
        // 如果包含正式文件常見詞彙，使用襯線字體
        let formalKeywords = ["therefore", "furthermore", "however", "moreover", "consequently", "nevertheless"]
        let lowercaseText = text.lowercased()
        let hasFormalWords = formalKeywords.contains { lowercaseText.contains($0) }
        
        // 如果文字較長且包含正式詞彙，使用襯線字體
        if text.count > 50 && hasFormalWords {
            return .englishSerif
        }
        
        // 預設使用圓潤字體
        return .englishRounded
    }
    
    // 根據樣式和權重獲取字體名稱
    private static func getFontName(for style: AppFontStyle, weight: AppFontWeight) -> String {
        switch style {
        case .chineseDefault:
            switch weight {
            case .light:
                return FontNames.chineseSerifLight
            case .regular, .medium:
                return FontNames.chineseSerif
            case .semibold, .bold:
                return FontNames.chineseSerifBold
            }
            
        case .englishRounded:
            switch weight {
            case .light:
                return FontNames.englishRoundedLight
            case .regular:
                return FontNames.englishRounded
            case .medium:
                return FontNames.englishRoundedMedium
            case .semibold, .bold:
                return FontNames.englishRoundedBold
            }
            
        case .englishSerif:
            switch weight {
            case .light, .regular, .medium:
                return FontNames.englishSerif
            case .semibold, .bold:
                return FontNames.englishSerifBold
            }
            
        case .system:
            switch weight {
            case .light:
                return FontNames.systemFontLight
            case .regular:
                return FontNames.systemFont
            case .medium:
                return FontNames.systemFontMedium
            case .semibold, .bold:
                return FontNames.systemFontBold
            }
        }
    }
}

// MARK: - SwiftUI 擴展

extension Font {
    // 快捷方法：智慧字體選擇
    static func appFont(for text: String, size: CGFloat, weight: AppFontWeight = .regular) -> Font {
        return AppFont.smartFont(for: text, size: size, weight: weight)
    }
    
    // 快捷方法：指定樣式字體
    static func appFont(style: AppFontStyle, size: CGFloat, weight: AppFontWeight = .regular) -> Font {
        return AppFont.font(style: style, size: size, weight: weight)
    }
    
    // 常用字體大小的便捷方法
    static func appLargeTitle(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 34, weight: .bold) : appFont(for: text, size: 34, weight: .bold)
    }
    
    static func appTitle(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 28, weight: .bold) : appFont(for: text, size: 28, weight: .bold)
    }
    
    static func appTitle2(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 22, weight: .bold) : appFont(for: text, size: 22, weight: .bold)
    }
    
    static func appTitle3(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 20, weight: .semibold) : appFont(for: text, size: 20, weight: .semibold)
    }
    
    static func appHeadline(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 17, weight: .semibold) : appFont(for: text, size: 17, weight: .semibold)
    }
    
    static func appBody(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 17, weight: .regular) : appFont(for: text, size: 17, weight: .regular)
    }
    
    static func appCallout(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 16, weight: .regular) : appFont(for: text, size: 16, weight: .regular)
    }
    
    static func appSubheadline(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 15, weight: .regular) : appFont(for: text, size: 15, weight: .regular)
    }
    
    static func appFootnote(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 13, weight: .regular) : appFont(for: text, size: 13, weight: .regular)
    }
    
    static func appCaption(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 12, weight: .regular) : appFont(for: text, size: 12, weight: .regular)
    }
    
    static func appCaption2(for text: String = "") -> Font {
        return text.isEmpty ? appFont(style: .chineseDefault, size: 11, weight: .regular) : appFont(for: text, size: 11, weight: .regular)
    }
}

// MARK: - Text 視圖擴展

extension Text {
    // 自動套用適合的字體
    func appFont(size: CGFloat, weight: AppFontWeight = .regular) -> some View {
        // 注意：由於 SwiftUI Text 無法直接取得其內容，
        // 這個方法主要用於已知內容類型的情況
        self.font(.appFont(style: .chineseDefault, size: size, weight: weight))
    }
    
    // 指定字體樣式
    func appFont(style: AppFontStyle, size: CGFloat, weight: AppFontWeight = .regular) -> some View {
        self.font(.appFont(style: style, size: size, weight: weight))
    }
}

// MARK: - UIFont 擴展

extension UIFont {
    // 智慧字體選擇的便捷方法
    static func appFont(for text: String, size: CGFloat, weight: AppFontWeight = .regular) -> UIFont {
        return AppFont.smartUIFont(for: text, size: size, weight: weight)
    }
    
    // 指定樣式字體的便捷方法
    static func appFont(style: AppFontStyle, size: CGFloat, weight: AppFontWeight = .regular) -> UIFont {
        return AppFont.uiFont(style: style, size: size, weight: weight)
    }
}

// MARK: - 字體預覽和除錯工具

#if DEBUG
struct FontPreviewView: View {
    private let sampleTexts = [
        "中文範例文字",
        "English Sample Text",
        "Learning English grammar can be challenging",
        "學習英語語法雖然具有挑戰性，但只要方法得當，就會變得更加容易掌握。",
        "Furthermore, the comprehensive analysis demonstrates significant improvements.",
        "AI 家教點評結果"
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("字體系統預覽")
                    .font(.appTitle())
                    .padding(.bottom)
                
                ForEach(sampleTexts, id: \.self) { text in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原文：\(text)")
                            .font(.appCaption(for: "原文標籤"))
                            .foregroundStyle(.secondary)
                        
                        Text(text)
                            .font(.appFont(for: text, size: 16, weight: .regular))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("字體預覽")
    }
}

#Preview {
    NavigationView {
        FontPreviewView()
    }
}
#endif
