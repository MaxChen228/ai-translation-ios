// SettingsManager.swift

import Foundation

class SettingsManager {
    static let shared = SettingsManager() // 使用單例模式，讓 App 中只有一個實例
    
    private let reviewCountKey = "reviewCount"
    private let newCountKey = "newCount"
    
    var reviewCount: Int {
        get {
            // 如果從未設定過，預設為 3
            UserDefaults.standard.integer(forKey: reviewCountKey) == 0 ? 3 : UserDefaults.standard.integer(forKey: reviewCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reviewCountKey)
        }
    }
    
    var newCount: Int {
        get {
            // 如果從未設定過，預設為 2
            UserDefaults.standard.integer(forKey: newCountKey) == 0 ? 2 : UserDefaults.standard.integer(forKey: newCountKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: newCountKey)
        }
    }
    
    private init() {}
}
