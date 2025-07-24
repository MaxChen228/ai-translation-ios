//
//  CoreModelsUnitTests.swift
//  LinkerTests
//
//  Unit tests for core data models
//

import Testing
import Foundation
@testable import Linker

// MARK: - CompositeKnowledgePointID Tests

struct CompositeKnowledgePointUnitTests {
    
    @Test("複合ID字串表示測試")
    func testStringRepresentation() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        #expect(compositeId.stringRepresentation == "123:456")
        
        let compositeId2 = CompositeKnowledgePointID(userId: 1, sequenceId: 1)
        #expect(compositeId2.stringRepresentation == "1:1")
    }
    
    @Test("複合ID等值比較測試")
    func testEquality() throws {
        let id1 = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let id2 = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let id3 = CompositeKnowledgePointID(userId: 123, sequenceId: 789)
        
        #expect(id1 == id2)
        #expect(id1 != id3)
    }
    
    @Test("複合ID JSON 編碼解碼測試")
    func testJSONCoding() throws {
        let originalId = CompositeKnowledgePointID(userId: 42, sequenceId: 99)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalId)
        
        let decoder = JSONDecoder()
        let decodedId = try decoder.decode(CompositeKnowledgePointID.self, from: data)
        
        #expect(originalId == decodedId)
        #expect(decodedId.userId == 42)
        #expect(decodedId.sequenceId == 99)
    }
    
    @Test("複合ID Hash值測試")
    func testHashable() throws {
        let id1 = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let id2 = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let id3 = CompositeKnowledgePointID(userId: 456, sequenceId: 123)
        
        let set: Set<CompositeKnowledgePointID> = [id1, id2, id3]
        
        // id1 和 id2 相同，所以 Set 中只有兩個元素
        #expect(set.count == 2)
        #expect(set.contains(id1))
        #expect(set.contains(id3))
    }
}

// MARK: - KnowledgePoint Tests

struct KnowledgePointUnitTests {
    
    private func createTestKnowledgePoint(
        compositeId: CompositeKnowledgePointID? = nil,
        legacyId: Int? = nil,
        oldId: Int? = nil,
        masteryLevel: Double = 0.5
    ) -> KnowledgePoint {
        return KnowledgePoint(
            compositeId: compositeId,
            legacyId: legacyId,
            oldId: oldId,
            category: "Grammar",
            subcategory: "Verb Tense",
            correctPhrase: "I have been studying English.",
            explanation: "Present perfect continuous tense",
            userContextSentence: "我一直在學習英語。",
            incorrectPhraseInContext: "I am studying English for 2 years.",
            keyPointSummary: "時態錯誤",
            masteryLevel: masteryLevel,
            mistakeCount: 2,
            correctCount: 5,
            nextReviewDate: "2025-07-25T10:00:00Z",
            isArchived: false,
            aiReviewNotes: "Good understanding of grammar structure",
            lastAiReviewDate: "2025-07-21T10:00:00Z"
        )
    }
    
    @Test("effectiveId 複合ID優先測試")
    func testEffectiveIdCompositeIdPriority() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let point = createTestKnowledgePoint(
            compositeId: compositeId,
            legacyId: 789,
            oldId: 999
        )
        
        #expect(point.effectiveId == "123:456")
    }
    
    @Test("effectiveId legacyId 回退測試")
    func testEffectiveIdLegacyIdFallback() throws {
        let point = createTestKnowledgePoint(
            compositeId: nil,
            legacyId: 789,
            oldId: 999
        )
        
        #expect(point.effectiveId == "789")
    }
    
    @Test("effectiveId oldId 回退測試")
    func testEffectiveIdOldIdFallback() throws {
        let point = createTestKnowledgePoint(
            compositeId: nil,
            legacyId: nil,
            oldId: 999
        )
        
        #expect(point.effectiveId == "999")
    }
    
    @Test("effectiveId Hash 回退測試")
    func testEffectiveIdHashFallback() throws {
        let point = createTestKnowledgePoint()
        
        // 應該使用 correctPhrase 的 hashValue
        let expectedId = "fallback_\(point.correctPhrase.hashValue)"
        #expect(point.effectiveId == expectedId)
    }
    
    @Test("KnowledgePoint JSON 編碼解碼測試")
    func testKnowledgePointJSONCoding() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let originalPoint = createTestKnowledgePoint(
            compositeId: compositeId,
            legacyId: 789
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPoint)
        
        let decoder = JSONDecoder()
        let decodedPoint = try decoder.decode(KnowledgePoint.self, from: data)
        
        #expect(decodedPoint.effectiveId == originalPoint.effectiveId)
        #expect(decodedPoint.correctPhrase == originalPoint.correctPhrase)
        #expect(decodedPoint.category == originalPoint.category)
        #expect(decodedPoint.compositeId?.userId == 123)
        #expect(decodedPoint.compositeId?.sequenceId == 456)
        #expect(decodedPoint.legacyId == 789)
    }
    
    @Test("KnowledgePoint Identifiable 協議測試")
    func testKnowledgePointIdentifiable() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let point = createTestKnowledgePoint(compositeId: compositeId)
        
        // Identifiable.id 應該等於 effectiveId
        #expect(point.id == point.effectiveId)
        #expect(point.id == "123:456")
    }
    
    @Test("KnowledgePoint 必要欄位驗證測試")
    func testKnowledgePointRequiredFields() throws {
        let point = createTestKnowledgePoint()
        
        // 驗證必要欄位不為空
        #expect(!point.category.isEmpty)
        #expect(!point.correctPhrase.isEmpty)
        #expect(point.masteryLevel >= 0.0)
        #expect(point.masteryLevel <= 1.0)
        #expect(point.mistakeCount >= 0)
        #expect(point.correctCount >= 0)
    }
}

// MARK: - Question Tests

struct QuestionUnitTests {
    
    private func createTestQuestion(
        compositeId: CompositeKnowledgePointID? = nil,
        knowledgePointId: Int? = nil,
        masteryLevel: Double? = 0.7
    ) -> Question {
        return Question(
            newSentence: "Translate this sentence to Chinese.",
            type: "translation",
            hintText: "Focus on verb tense",
            knowledgePointCompositeId: compositeId,
            knowledgePointId: knowledgePointId,
            masteryLevel: masteryLevel
        )
    }
    
    @Test("Question effectiveKnowledgePointId 複合ID測試")
    func testQuestionEffectiveKnowledgePointIdComposite() throws {
        let compositeId = CompositeKnowledgePointID(userId: 123, sequenceId: 456)
        let question = createTestQuestion(compositeId: compositeId, knowledgePointId: 789)
        
        #expect(question.effectiveKnowledgePointId == "123:456")
    }
    
    @Test("Question effectiveKnowledgePointId 舊ID回退測試")
    func testQuestionEffectiveKnowledgePointIdLegacy() throws {
        let question = createTestQuestion(knowledgePointId: 789)
        
        #expect(question.effectiveKnowledgePointId == "789")
    }
    
    @Test("Question effectiveKnowledgePointId nil測試")
    func testQuestionEffectiveKnowledgePointIdNil() throws {
        let question = createTestQuestion()
        
        #expect(question.effectiveKnowledgePointId == nil)
    }
    
    @Test("Question JSON 編碼解碼測試")
    func testQuestionJSONCoding() throws {
        let compositeId = CompositeKnowledgePointID(userId: 42, sequenceId: 99)
        let originalQuestion = createTestQuestion(compositeId: compositeId)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalQuestion)
        
        let decoder = JSONDecoder()
        let decodedQuestion = try decoder.decode(Question.self, from: data)
        
        #expect(decodedQuestion.newSentence == originalQuestion.newSentence)
        #expect(decodedQuestion.type == originalQuestion.type)
        #expect(decodedQuestion.knowledgePointCompositeId?.userId == 42)
        #expect(decodedQuestion.knowledgePointCompositeId?.sequenceId == 99)
        #expect(decodedQuestion.masteryLevel == originalQuestion.masteryLevel)
    }
    
    @Test("Question UUID 唯一性測試")
    func testQuestionUUIDUniqueness() throws {
        let question1 = createTestQuestion()
        let question2 = createTestQuestion()
        
        #expect(question1.id != question2.id)
        
        let questions = [question1, question2]
        let uniqueIds = Set(questions.map { $0.id })
        #expect(uniqueIds.count == 2)
    }
}

// MARK: - ErrorAnalysis Tests

struct ErrorAnalysisUnitTests {
    
    private func createTestErrorAnalysis() -> ErrorAnalysis {
        return ErrorAnalysis(
            errorTypeCode: "B",
            keyPointSummary: "動詞時態錯誤",
            originalPhrase: "I am studying English for 2 years",
            correction: "I have been studying English for 2 years",
            explanation: "使用現在完成進行時來表示持續到現在的動作",
            severity: "high"
        )
    }
    
    @Test("ErrorAnalysis 基本屬性測試")
    func testErrorAnalysisBasicProperties() throws {
        let error = createTestErrorAnalysis()
        
        #expect(error.errorTypeCode == "B")
        #expect(error.keyPointSummary == "動詞時態錯誤")
        #expect(error.originalPhrase == "I am studying English for 2 years")
        #expect(error.correction == "I have been studying English for 2 years")
        #expect(error.severity == "high")
        #expect(!error.explanation.isEmpty)
    }
    
    @Test("ErrorAnalysis 分類名稱測試")
    func testErrorAnalysisCategoryName() throws {
        let errorA = ErrorAnalysis(
            errorTypeCode: "A",
            keyPointSummary: "詞彙錯誤",
            originalPhrase: "test",
            correction: "test",
            explanation: "test",
            severity: "high"
        )
        
        let errorB = createTestErrorAnalysis()
        
        #expect(errorA.categoryName == "詞彙與片語錯誤")
        #expect(errorB.categoryName == "語法結構錯誤")
    }
    
    @Test("ErrorAnalysis JSON 編碼解碼測試")
    func testErrorAnalysisJSONCoding() throws {
        let originalError = createTestErrorAnalysis()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalError)
        
        let decoder = JSONDecoder()
        let decodedError = try decoder.decode(ErrorAnalysis.self, from: data)
        
        #expect(decodedError.errorTypeCode == originalError.errorTypeCode)
        #expect(decodedError.keyPointSummary == originalError.keyPointSummary)
        #expect(decodedError.originalPhrase == originalError.originalPhrase)
        #expect(decodedError.correction == originalError.correction)
        #expect(decodedError.explanation == originalError.explanation)
        #expect(decodedError.severity == originalError.severity)
    }
    
    @Test("ErrorAnalysis UUID 唯一性測試")
    func testErrorAnalysisUUIDUniqueness() throws {
        let error1 = createTestErrorAnalysis()
        let error2 = createTestErrorAnalysis()
        
        #expect(error1.id != error2.id)
        
        let errors = [error1, error2]
        let uniqueIds = Set(errors.map { $0.id })
        #expect(uniqueIds.count == 2)
    }
}

// MARK: - Response Models Tests

struct ResponseModelsUnitTests {
    
    @Test("QuestionsResponse 解碼測試")
    func testQuestionsResponseDecoding() throws {
        let jsonString = """
        {
            "questions": [
                {
                    "new_sentence": "Test sentence 1",
                    "type": "translation",
                    "hint_text": "Test hint 1",
                    "knowledge_point_id": 123,
                    "mastery_level": 0.7
                },
                {
                    "new_sentence": "Test sentence 2",
                    "type": "correction",
                    "hint_text": "Test hint 2",
                    "knowledge_point_composite_id": {
                        "user_id": 456,
                        "sequence_id": 789
                    },
                    "mastery_level": 0.8
                }
            ]
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(QuestionsResponse.self, from: data)
        
        #expect(response.questions.count == 2)
        #expect(response.questions[0].newSentence == "Test sentence 1")
        #expect(response.questions[0].knowledgePointId == 123)
        #expect(response.questions[1].newSentence == "Test sentence 2")
        #expect(response.questions[1].knowledgePointCompositeId?.userId == 456)
        #expect(response.questions[1].knowledgePointCompositeId?.sequenceId == 789)
    }
    
    @Test("FeedbackResponse 解碼測試")
    func testFeedbackResponseDecoding() throws {
        let jsonString = """
        {
            "is_generally_correct": true,
            "overall_suggestion": "Great job!",
            "error_analysis": [
                {
                    "error_type_code": "B",
                    "key_point_summary": "Verb tense error",
                    "original_phrase": "I am study",
                    "correction": "I am studying",
                    "explanation": "Use present continuous tense",
                    "severity": "medium"
                }
            ],
            "did_master_review_concept": true
        }
        """
        
        let data = jsonString.data(using: .utf8)!
        let decoder = JSONDecoder()
        let response = try decoder.decode(FeedbackResponse.self, from: data)
        
        #expect(response.isGenerallyCorrect == true)
        #expect(response.overallSuggestion == "Great job!")
        #expect(response.errorAnalysis.count == 1)
        #expect(response.errorAnalysis[0].errorTypeCode == "B")
        #expect(response.didMasterReviewConcept == true)
    }
}