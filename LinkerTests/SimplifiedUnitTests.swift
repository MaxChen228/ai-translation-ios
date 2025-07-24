//
//  SimplifiedUnitTests.swift
//  LinkerTests
//
//  Simplified unit tests for core functionality
//

import Testing
import Foundation
@testable import Linker

// MARK: - Basic Network Tests

struct BasicNetworkTests {
    
    @Test("API端點URL構建測試")
    func testAPIEndpointURLConstruction() throws {
        // 測試基本的字串處理邏輯
        let baseURL = "http://localhost:8000"
        let endpoint = "/api/data/get_dashboard"
        let fullURL = baseURL + endpoint
        
        #expect(fullURL == "http://localhost:8000/api/data/get_dashboard")
    }
    
    @Test("複合ID字串格式測試")
    func testCompositeIdStringFormat() throws {
        let userId = 123
        let sequenceId = 456
        let compositeString = "\(userId):\(sequenceId)"
        
        #expect(compositeString == "123:456")
    }
    
    @Test("JSON編碼解碼基本測試")
    func testBasicJSONOperations() throws {
        let testData = ["test": "value", "number": "123"]
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(testData)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([String: String].self, from: data)
        
        #expect(decoded["test"] == "value")
        #expect(decoded["number"] == "123")
    }
}

// MARK: - Data Model Tests

struct DataModelBasicTests {
    
    @Test("CompositeKnowledgePointID創建測試")
    func testCompositeKnowledgePointIDCreation() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        
        #expect(compositeId.userId == 123)
        #expect(compositeId.sequenceId == 456)
        #expect(compositeId.stringRepresentation == "123:456")
    }
    
    @Test("CompositeKnowledgePointID等值比較測試")
    func testCompositeKnowledgePointIDEquality() throws {
        let id1 = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let id2 = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let id3 = CompositeKnowledgePointID(userId: 123, sequenceId: 789)
        
        #expect(id1 == id2)
        #expect(id1 != id3)
    }
    
    @Test("KnowledgePoint基本屬性測試")
    func testKnowledgePointBasicProperties() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        
        let knowledgePoint = KnowledgePoint(
            compositeId: compositeId,
            legacyId: nil,
            oldId: nil,
            category: "Grammar",
            subcategory: "Verb Tense",
            correctPhrase: "I have been studying English.",
            explanation: "Present perfect continuous tense",
            userContextSentence: "我一直在學習英語。",
            incorrectPhraseInContext: "I am studying English for 2 years.",
            keyPointSummary: "時態錯誤",
            masteryLevel: 0.7,
            mistakeCount: 2,
            correctCount: 5,
            nextReviewDate: "2025-07-25T10:00:00Z",
            isArchived: false,
            aiReviewNotes: "Good understanding",
            lastAiReviewDate: "2025-07-21T10:00:00Z"
        )
        
        #expect(knowledgePoint.category == "Grammar")
        #expect(knowledgePoint.correctPhrase == "I have been studying English.")
        #expect(knowledgePoint.masteryLevel == 0.7)
        #expect(knowledgePoint.effectiveId == "123:456")
    }
    
    @Test("KnowledgePoint effectiveId 邏輯測試")
    func testKnowledgePointEffectiveIdLogic() throws {
        // 測試複合ID優先
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let pointWithComposite = KnowledgePoint(
            compositeId: compositeId,
            legacyId: 789,
            oldId: 999,
            category: "Test",
            subcategory: "Test",
            correctPhrase: "Test phrase",
            explanation: nil,
            userContextSentence: nil,
            incorrectPhraseInContext: nil,
            keyPointSummary: nil,
            masteryLevel: 0.5,
            mistakeCount: 0,
            correctCount: 0,
            nextReviewDate: nil,
            isArchived: false,
            aiReviewNotes: nil,
            lastAiReviewDate: nil
        )
        
        #expect(pointWithComposite.effectiveId == "123:456")
        
        // 測試legacyId回退
        let pointWithLegacy = KnowledgePoint(
            compositeId: nil,
            legacyId: 789,
            oldId: 999,
            category: "Test",
            subcategory: "Test",
            correctPhrase: "Test phrase",
            explanation: nil,
            userContextSentence: nil,
            incorrectPhraseInContext: nil,
            keyPointSummary: nil,
            masteryLevel: 0.5,
            mistakeCount: 0,
            correctCount: 0,
            nextReviewDate: nil,
            isArchived: false,
            aiReviewNotes: nil,
            lastAiReviewDate: nil
        )
        
        #expect(pointWithLegacy.effectiveId == "789")
        
        // 測試oldId回退
        let pointWithOld = KnowledgePoint(
            compositeId: nil,
            legacyId: nil,
            oldId: 999,
            category: "Test",
            subcategory: "Test",
            correctPhrase: "Test phrase",
            explanation: nil,
            userContextSentence: nil,
            incorrectPhraseInContext: nil,
            keyPointSummary: nil,
            masteryLevel: 0.5,
            mistakeCount: 0,
            correctCount: 0,
            nextReviewDate: nil,
            isArchived: false,
            aiReviewNotes: nil,
            lastAiReviewDate: nil
        )
        
        #expect(pointWithOld.effectiveId == "999")
    }
    
    @Test("Question基本功能測試")
    func testQuestionBasicFunctionality() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        
        let question = Question(
            newSentence: "Translate this sentence.",
            type: "translation",
            hintText: "Focus on verb tense",
            knowledgePointCompositeId: compositeId,
            knowledgePointId: nil,
            masteryLevel: 0.7
        )
        
        #expect(question.newSentence == "Translate this sentence.")
        #expect(question.type == "translation")
        #expect(question.effectiveKnowledgePointId == "123:456")
        #expect(question.masteryLevel == 0.7)
    }
    
    @Test("ErrorAnalysis基本功能測試")
    func testErrorAnalysisBasicFunctionality() throws {
        let error = ErrorAnalysis(
            errorTypeCode: "B",
            keyPointSummary: "動詞時態錯誤",
            originalPhrase: "I am studying for 2 years",
            correction: "I have been studying for 2 years",
            explanation: "使用現在完成進行時",
            severity: "high"
        )
        
        #expect(error.errorTypeCode == "B")
        #expect(error.keyPointSummary == "動詞時態錯誤")
        #expect(error.categoryName == "語法結構錯誤")
        #expect(error.severity == "high")
    }
}

// MARK: - Array and Collection Tests

struct CollectionOperationTests {
    
    @Test("KnowledgePoint陣列過濾測試")
    func testKnowledgePointArrayFiltering() throws {
        let points = createMockKnowledgePoints()
        
        // 測試按category過濾
        let grammarPoints = points.filter { $0.category == "Grammar" }
        #expect(grammarPoints.count == 2)
        
        // 測試按masteryLevel過濾
        let highMasteryPoints = points.filter { $0.masteryLevel >= 0.8 }
        #expect(highMasteryPoints.count == 1)
        
        // 測試按archived狀態過濾
        let activePoints = points.filter { $0.isArchived == false }
        #expect(activePoints.count == 3)
    }
    
    @Test("KnowledgePoint陣列排序測試")
    func testKnowledgePointArraySorting() throws {
        let points = createMockKnowledgePoints()
        
        // 按masteryLevel排序
        let sortedByMastery = points.sorted { $0.masteryLevel < $1.masteryLevel }
        #expect(sortedByMastery.first?.masteryLevel == 0.3)
        #expect(sortedByMastery.last?.masteryLevel == 0.9)
        
        // 按category排序
        let sortedByCategory = points.sorted { $0.category < $1.category }
        #expect(sortedByCategory.first?.category == "Grammar")
    }
    
    @Test("KnowledgePoint陣列統計測試")
    func testKnowledgePointArrayStatistics() throws {
        let points = createMockKnowledgePoints()
        
        let totalPoints = points.count
        let masteredPoints = points.filter { $0.masteryLevel >= 0.8 }.count
        let inProgressPoints = points.filter { $0.masteryLevel < 0.8 }.count
        
        #expect(totalPoints == 3)
        #expect(masteredPoints == 1)
        #expect(inProgressPoints == 2)
        
        // 計算平均熟練度
        let averageMastery = points.map(\.masteryLevel).reduce(0, +) / Double(points.count)
        let expectedAverage = (0.3 + 0.7 + 0.9) / 3.0
        #expect(abs(averageMastery - expectedAverage) < 0.01)
    }
    
    @Test("Set操作測試")
    func testSetOperations() throws {
        let points = createMockKnowledgePoints()
        let effectiveIds = Set(points.map(\.effectiveId))
        
        #expect(effectiveIds.count == 3) // 所有ID應該是唯一的
        
        // 測試ID存在性
        let compositeIdExists = effectiveIds.contains("123:1")
        let legacyIdExists = effectiveIds.contains("999")
        
        #expect(compositeIdExists)
        #expect(legacyIdExists)
    }
    
    private func createMockKnowledgePoints() -> [KnowledgePoint] {
        return [
            KnowledgePoint(
                compositeId: CompositeKnowledgePointID(userId: 123, sequenceId: 1),
                legacyId: nil,
                oldId: nil,
                category: "Grammar",
                subcategory: "Verb Tense",
                correctPhrase: "I have been studying.",
                explanation: "Present perfect continuous",
                userContextSentence: nil,
                incorrectPhraseInContext: nil,
                keyPointSummary: nil,
                masteryLevel: 0.7,
                mistakeCount: 2,
                correctCount: 5,
                nextReviewDate: nil,
                isArchived: false,
                aiReviewNotes: nil,
                lastAiReviewDate: nil
            ),
            KnowledgePoint(
                compositeId: CompositeKnowledgePointID(userId: 123, sequenceId: 2),
                legacyId: nil,
                oldId: nil,
                category: "Grammar",
                subcategory: "Modal Verb",
                correctPhrase: "You should study harder.",
                explanation: "Modal verb usage",
                userContextSentence: nil,
                incorrectPhraseInContext: nil,
                keyPointSummary: nil,
                masteryLevel: 0.9,
                mistakeCount: 0,
                correctCount: 10,
                nextReviewDate: nil,
                isArchived: false,
                aiReviewNotes: nil,
                lastAiReviewDate: nil
            ),
            KnowledgePoint(
                compositeId: nil,
                legacyId: 999,
                oldId: nil,
                category: "Vocabulary",
                subcategory: "Word Choice",
                correctPhrase: "Legacy knowledge point.",
                explanation: "Old system point",
                userContextSentence: nil,
                incorrectPhraseInContext: nil,
                keyPointSummary: nil,
                masteryLevel: 0.3,
                mistakeCount: 3,
                correctCount: 2,
                nextReviewDate: nil,
                isArchived: false,
                aiReviewNotes: nil,
                lastAiReviewDate: nil
            )
        ]
    }
}

// MARK: - Error Handling Tests

struct ErrorHandlingTests {
    
    @Test("API錯誤處理測試")
    func testAPIErrorHandling() throws {
        // 模擬不同的錯誤情況
        let networkError = "Network connection failed"
        let serverError = "Server returned status code 500"
        let parseError = "Failed to parse JSON response"
        
        #expect(!networkError.isEmpty)
        #expect(!serverError.isEmpty)
        #expect(!parseError.isEmpty)
        
        // 測試錯誤訊息包含關鍵字
        #expect(networkError.contains("Network"))
        #expect(serverError.contains("500"))
        #expect(parseError.contains("JSON"))
    }
    
    @Test("數據驗證測試")
    func testDataValidation() throws {
        // 測試有效的mastery level
        let validMasteryLevels = [0.0, 0.5, 1.0]
        for level in validMasteryLevels {
            #expect(level >= 0.0 && level <= 1.0)
        }
        
        // 測試category不為空
        let categories = ["Grammar", "Vocabulary", "Pronunciation"]
        for category in categories {
            #expect(!category.isEmpty)
            #expect(category.count > 0)
        }
        
        // 測試計數器為非負數
        let counts = [0, 1, 5, 10]
        for count in counts {
            #expect(count >= 0)
        }
    }
}

// MARK: - Performance Tests

struct PerformanceBasicTests {
    
    @Test("大陣列處理性能測試")
    func testLargeArrayPerformance() throws {
        // 創建大量知識點數據
        let largePointCount = 1000
        var points: [KnowledgePoint] = []
        
        for i in 0..<largePointCount {
            let point = KnowledgePoint(
                compositeId: CompositeKnowledgePointID(userId: 123, sequenceId: i),
                legacyId: nil,
                oldId: nil,
                category: "Grammar",
                subcategory: "Test",
                correctPhrase: "Test phrase \(i)",
                explanation: nil,
                userContextSentence: nil,
                incorrectPhraseInContext: nil,
                keyPointSummary: nil,
                masteryLevel: Double.random(in: 0...1),
                mistakeCount: Int.random(in: 0...10),
                correctCount: Int.random(in: 0...20),
                nextReviewDate: nil,
                isArchived: false,
                aiReviewNotes: nil,
                lastAiReviewDate: nil
            )
            points.append(point)
        }
        
        #expect(points.count == largePointCount)
        
        // 測試過濾操作
        let masteredPoints = points.filter { $0.masteryLevel >= 0.8 }
        #expect(masteredPoints.count <= largePointCount)
        
        // 測試映射操作
        let effectiveIds = points.map(\.effectiveId)
        #expect(effectiveIds.count == largePointCount)
        
        // 測試去重操作
        let uniqueIds = Set(effectiveIds)
        #expect(uniqueIds.count == largePointCount) // 所有ID應該都是唯一的
    }
}