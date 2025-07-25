// AudioPlayerManager.swift - 統一音頻播放管理器
// 為應用程式提供統一的音頻播放服務

import Foundation
import AVFoundation
import SwiftUI

@MainActor
class AudioPlayerManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AudioPlayerManager()
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentIdentifier: String?
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Never>?
    private var audioPlayerDelegate: AudioPlayerDelegate?
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Public Methods
    
    /// 播放音頻
    /// - Parameters:
    ///   - audioUrl: 音頻URL字串
    ///   - identifier: 音頻識別碼（用於狀態追蹤）
    func playAudio(from audioUrl: String, for identifier: String) {
        // 取消之前的播放任務
        currentTask?.cancel()
        
        currentTask = Task {
            await performAudioPlayback(audioUrl: audioUrl, identifier: identifier)
        }
    }
    
    /// 停止當前播放
    func stopPlayback() {
        currentTask?.cancel()
        audioPlayer?.stop()
        resetPlaybackState()
    }
    
    /// 暫停/繼續播放
    func togglePlayback() {
        guard let player = audioPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.error("音頻會話設定失敗: \(error.localizedDescription)", category: .general)
        }
    }
    
    private func performAudioPlayback(audioUrl: String, identifier: String) async {
        guard !Task.isCancelled else { return }
        
        // 重置錯誤狀態
        errorMessage = nil
        
        // 驗證URL
        guard let url = URL(string: audioUrl), url.scheme != nil else {
            await handlePlaybackError("無效的音頻URL", for: identifier)
            return
        }
        
        // 開始載入狀態
        isLoading = true
        currentIdentifier = identifier
        
        do {
            // 下載音頻資料
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard !Task.isCancelled else {
                resetPlaybackState()
                return
            }
            
            // 驗證HTTP回應
            if let httpResponse = response as? HTTPURLResponse {
                guard httpResponse.statusCode == 200 else {
                    await handlePlaybackError("音頻載入失敗 (HTTP \(httpResponse.statusCode))", for: identifier)
                    return
                }
            }
            
            // 驗證音頻資料
            guard !data.isEmpty else {
                await handlePlaybackError("音頻檔案為空", for: identifier)
                return
            }
            
            // 創建音頻播放器
            let player = try AVAudioPlayer(data: data)
            audioPlayerDelegate = AudioPlayerDelegate(manager: self)
            player.delegate = audioPlayerDelegate
            player.prepareToPlay()
            
            guard !Task.isCancelled else {
                resetPlaybackState()
                return
            }
            
            // 停止之前的播放
            audioPlayer?.stop()
            audioPlayer = player
            
            // 開始播放
            isLoading = false
            isPlaying = true
            
            let success = player.play()
            if !success {
                await handlePlaybackError("音頻播放啟動失敗", for: identifier)
                return
            }
            
            Logger.info("開始播放: \(identifier)", category: .general)
            
        } catch {
            guard !Task.isCancelled else {
                resetPlaybackState()
                return
            }
            
            await handlePlaybackError("音頻載入錯誤: \(error.localizedDescription)", for: identifier)
        }
    }
    
    private func handlePlaybackError(_ message: String, for identifier: String) async {
        Logger.error("音頻播放錯誤 (\(identifier)): \(message)", category: .general)
        errorMessage = message
        resetPlaybackState()
    }
    
    private func resetPlaybackState() {
        isLoading = false
        isPlaying = false
        currentIdentifier = nil
        audioPlayerDelegate = nil
    }
    
    /// 播放完成時呼叫
    fileprivate func didFinishPlaying() {
        Logger.success("播放完成: \(currentIdentifier ?? "未知")", category: .general)
        resetPlaybackState()
    }
    
    /// 播放中斷時呼叫
    fileprivate func playbackInterrupted() {
        Logger.warning("播放中斷: \(currentIdentifier ?? "未知")", category: .general)
        resetPlaybackState()
    }
}

// MARK: - AVAudioPlayerDelegate

private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    weak var manager: AudioPlayerManager?
    
    init(manager: AudioPlayerManager) {
        self.manager = manager
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            manager?.didFinishPlaying()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            if let error = error {
                Logger.error("音頻解碼錯誤: \(error.localizedDescription)", category: .general)
            }
            manager?.playbackInterrupted()
        }
    }
}

// MARK: - View Extension for Easy Usage

extension View {
    /// 為視圖提供音頻播放功能
    /// - Parameters:
    ///   - audioUrl: 音頻URL
    ///   - identifier: 音頻識別碼
    /// - Returns: 更新後的視圖
    func audioPlayback(for audioUrl: String, identifier: String) -> some View {
        self.onTapGesture {
            AudioPlayerManager.shared.playAudio(from: audioUrl, for: identifier)
        }
    }
}

// MARK: - Audio Player Button Component

struct AudioPlayerButton: View {
    let audioUrl: String
    let identifier: String
    
    @StateObject private var audioManager = AudioPlayerManager.shared
    
    var body: some View {
        Button(action: {
            if audioManager.isPlaying && audioManager.currentIdentifier == identifier {
                audioManager.togglePlayback()
            } else {
                audioManager.playAudio(from: audioUrl, for: identifier)
            }
        }) {
            Group {
                if audioManager.isLoading && audioManager.currentIdentifier == identifier {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if audioManager.isPlaying && audioManager.currentIdentifier == identifier {
                    Image(systemName: "pause.circle.fill")
                } else {
                    Image(systemName: "play.circle.fill")
                }
            }
            .font(.appTitle2())
            .foregroundStyle(Color.modernAccent)
        }
        .disabled(audioManager.isLoading)
    }
}

// MARK: - Error Display Component

struct AudioErrorView: View {
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: ModernSpacing.sm) {
            HStack(spacing: ModernSpacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.modernError)
                
                Text("音頻播放失敗")
                    .font(.appCaption())
                    .foregroundStyle(Color.modernError)
            }
            
            Text(errorMessage)
                .font(.appCaption())
                .foregroundStyle(Color.modernTextSecondary)
                .multilineTextAlignment(.center)
            
            Button("重試", action: onRetry)
                .font(.appCaption())
                .foregroundStyle(Color.modernAccent)
        }
        .padding(ModernSpacing.sm)
        .background {
            RoundedRectangle(cornerRadius: ModernRadius.xs)
                .fill(Color.modernError.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: ModernRadius.xs)
                        .stroke(Color.modernError.opacity(0.3), lineWidth: 1)
                }
        }
    }
}