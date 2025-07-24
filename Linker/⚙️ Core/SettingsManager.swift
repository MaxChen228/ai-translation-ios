// SettingsManager.swift

import Foundation

class SettingsManager {
    static let shared = SettingsManager() // 使用單例模式，讓 App 中只有一個實例
    
    // 定義儲存用的 Key
    private let reviewCountKey = "reviewCount"
    private let newCountKey = "newCount"
    private let difficultyKey = "difficulty"
    private let lengthKey = "length"
    private let dailyGoalKey = "dailyGoal"
    // 【vNext 新增】模型選擇用的 Key
    private let generationModelKey = "generationModel"
    private let gradingModelKey = "gradingModel"

    // 【vNext 新增】定義可選的模型
    // 這個列表應該要和後端 ai_service.py 中的 AVAILABLE_MODELS 的 key 一致
    enum AIModel: String, CaseIterable, Identifiable {
        case gemini_2_5_pro = "gemini-2.5-pro"
        case gemini_2_5_flash = "gemini-2.5-flash"
        case gpt_4o = "gpt-4o"
        case gpt_4_turbo = "gpt-4-turbo"
        
        var id: Self { self }
        
        // 顯示在 Picker 上的名稱
        var displayName: String {
            switch self {
            case .gemini_2_5_pro: return "Gemini 2.5 Pro"
            case .gemini_2_5_flash: return "Gemini 2.5 Flash"
            case .gpt_4o: return "GPT-4o"
            case .gpt_4_turbo: return "GPT-4 Turbo"
            }
        }
    }

    // 題數設定 (不變)
    var reviewCount: Int {
        get { UserDefaults.standard.object(forKey: reviewCountKey) as? Int ?? 3 }
        set { UserDefaults.standard.set(newValue, forKey: reviewCountKey) }
    }
    
    var newCount: Int {
        get { UserDefaults.standard.object(forKey: newCountKey) as? Int ?? 2 }
        set { UserDefaults.standard.set(newValue, forKey: newCountKey) }
    }
    
    // 難度設定 (不變)
    var difficulty: Int {
        get { UserDefaults.standard.object(forKey: difficultyKey) as? Int ?? 3 }
        set { UserDefaults.standard.set(newValue, forKey: difficultyKey) }
    }
    
    // 句子長度 (不變)
    enum SentenceLength: String, CaseIterable, Identifiable {
        case short, medium, long
        var id: Self { self }
        var displayName: String {
            switch self {
            case .short: return "短句"
            case .medium: return "中等"
            case .long: return "長句"
            }
        }
    }
    
    var length: SentenceLength {
        get { SentenceLength(rawValue: UserDefaults.standard.string(forKey: lengthKey) ?? "medium") ?? .medium }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: lengthKey) }
    }

    // 每日目標 (不變)
    var dailyGoal: Int {
        get { UserDefaults.standard.object(forKey: dailyGoalKey) as? Int ?? 10 }
        set { UserDefaults.standard.set(newValue, forKey: dailyGoalKey) }
    }
    
    // 【vNext 新增】出題模型設定
    var generationModel: AIModel {
        get { AIModel(rawValue: UserDefaults.standard.string(forKey: generationModelKey) ?? "gemini-2.5-pro") ?? .gemini_2_5_pro }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: generationModelKey) }
    }
    
    // 【vNext 新增】批改模型設定
    var gradingModel: AIModel {
        get { AIModel(rawValue: UserDefaults.standard.string(forKey: gradingModelKey) ?? "gemini-2.5-flash") ?? .gemini_2_5_flash }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: gradingModelKey) }
    }
    
    private init() {}
}
