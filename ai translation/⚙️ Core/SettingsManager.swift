// SettingsManager.swift

import Foundation

class SettingsManager {
    static let shared = SettingsManager() // 使用單例模式，讓 App 中只有一個實例
    
    // 定義儲存用的 Key
    private let reviewCountKey = "reviewCount"
    private let newCountKey = "newCount"
    private let difficultyKey = "difficulty"
    private let lengthKey = "length"
    
    // 題數設定
    var reviewCount: Int {
        get {
            // 如果從未設定過，預設為 3
            UserDefaults.standard.object(forKey: reviewCountKey) as? Int ?? 3
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reviewCountKey)
        }
    }
    
    var newCount: Int {
        get {
            // 如果從未設定過，預設為 2
            UserDefaults.standard.object(forKey: newCountKey) as? Int ?? 2
        }
        set {
            UserDefaults.standard.set(newValue, forKey: newCountKey)
        }
    }
    
    // 難度設定
    var difficulty: Int {
        get {
            // 如果從未設定過，預設為 3
            UserDefaults.standard.object(forKey: difficultyKey) as? Int ?? 3
        }
        set {
            UserDefaults.standard.set(newValue, forKey: difficultyKey)
        }
    }
    
    // 【核心修正】讓 rawValue 是後端需要的英文 key
    enum SentenceLength: String, CaseIterable, Identifiable {
        case short
        case medium
        case long
        
        var id: Self { self }
        
        // 新增一個計算屬性，專門給 UI 顯示用
        var displayName: String {
            switch self {
            case .short:
                return "短句"
            case .medium:
                return "中等"
            case .long:
                return "長句"
            }
        }
    }
    
    var length: SentenceLength {
        get {
            // 如果從未設定過，預設為 medium
            SentenceLength(rawValue: UserDefaults.standard.string(forKey: lengthKey) ?? "medium") ?? .medium
        }
        set {
            // 儲存枚舉的 rawValue (即 "short", "medium", "long")
            UserDefaults.standard.set(newValue.rawValue, forKey: lengthKey)
        }
    }
    
    private init() {}
}
