// ModernAnimationSystem.swift - 現代動畫設計系統
// 提供統一、流暢的動畫體驗

import SwiftUI

// MARK: - 動畫時長常數
struct AnimationDuration {
    static let instant: TimeInterval = 0.1      // 即時反馈
    static let quick: TimeInterval = 0.2        // 快速交互
    static let normal: TimeInterval = 0.3       // 标准过渡
    static let relaxed: TimeInterval = 0.5      // 舒缓动画
    static let slow: TimeInterval = 0.8         // 慢速展示
    static let dramatic: TimeInterval = 1.2     // 戏剧效果
}

// MARK: - 動畫曲線定義
struct AnimationCurves {
    // 基础缓动
    static let easeIn = Animation.easeIn(duration: AnimationDuration.normal)
    static let easeOut = Animation.easeOut(duration: AnimationDuration.normal)
    static let easeInOut = Animation.easeInOut(duration: AnimationDuration.normal)
    
    // 快速缓动（用于即时反馈）
    static let quickEaseIn = Animation.easeIn(duration: AnimationDuration.quick)
    static let quickEaseOut = Animation.easeOut(duration: AnimationDuration.quick)
    static let quickEaseInOut = Animation.easeInOut(duration: AnimationDuration.quick)
    
    // Spring 动画（自然弹性）
    static let gentleSpring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let bounceSpring = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let responsiveSpring = Animation.spring(response: 0.2, dampingFraction: 0.9)
    static let dramaticSpring = Animation.spring(response: 0.8, dampingFraction: 0.5)
    
    // 特殊效果动画
    static let pulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
    static let smoothPulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
}

// MARK: - 過場動畫定義
struct TransitionEffects {
    // 基础过渡
    static let fadeIn = AnyTransition.opacity
    static let slideUp = AnyTransition.move(edge: .bottom)
    static let slideDown = AnyTransition.move(edge: .top)
    static let slideLeft = AnyTransition.move(edge: .leading)
    static let slideRight = AnyTransition.move(edge: .trailing)
    
    // 缩放过渡
    static let scaleIn = AnyTransition.scale
    static let scaleOut = AnyTransition.scale(scale: 0.8)
    
    // 组合过渡
    static let gentleAppear = AnyTransition.opacity.combined(with: .scale(scale: 0.95))
    static let modalPresent = AnyTransition.opacity.combined(with: .move(edge: .bottom))
    static let cardFlip = AnyTransition.asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale(scale: 0.8).combined(with: .opacity)
    )
    
    // 页面转场
    static let pageSlide = AnyTransition.asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
    
    static let pageSlideBack = AnyTransition.asymmetric(
        insertion: .move(edge: .leading),
        removal: .move(edge: .trailing)
    )
}

// MARK: - 微交互動畫
struct MicroInteractions {
    
    /// 按钮点击反馈
    static func buttonTap() -> Animation {
        return .spring(response: 0.15, dampingFraction: 0.8)
    }
    
    /// 卡片悬停效果
    static func cardHover() -> Animation {
        return .easeOut(duration: AnimationDuration.quick)
    }
    
    /// 输入框聚焦
    static func inputFocus() -> Animation {
        return .easeInOut(duration: AnimationDuration.quick)
    }
    
    /// 状态切换
    static func stateChange() -> Animation {
        return .easeInOut(duration: AnimationDuration.normal)
    }
    
    /// 进度条动画
    static func progressUpdate() -> Animation {
        return .easeOut(duration: AnimationDuration.relaxed)
    }
    
    /// 通知出现
    static func notification() -> Animation {
        return .spring(response: 0.4, dampingFraction: 0.7)
    }
}

// MARK: - 動畫預設組合
enum AnimationPreset {
    case instant        // 即时响应
    case quick          // 快速交互
    case smooth         // 平滑过渡
    case bouncy         // 弹性效果
    case dramatic       // 戏剧化
    case gentle         // 温和舒缓
    
    var animation: Animation {
        switch self {
        case .instant:
            return .easeInOut(duration: AnimationDuration.instant)
        case .quick:
            return AnimationCurves.quickEaseInOut
        case .smooth:
            return AnimationCurves.easeInOut
        case .bouncy:
            return AnimationCurves.bounceSpring
        case .dramatic:
            return AnimationCurves.dramaticSpring
        case .gentle:
            return AnimationCurves.gentleSpring
        }
    }
    
    var transition: AnyTransition {
        switch self {
        case .instant:
            return TransitionEffects.fadeIn
        case .quick:
            return TransitionEffects.gentleAppear
        case .smooth:
            return TransitionEffects.gentleAppear
        case .bouncy:
            return TransitionEffects.scaleIn
        case .dramatic:
            return TransitionEffects.modalPresent
        case .gentle:
            return TransitionEffects.gentleAppear
        }
    }
}

// MARK: - View 擴展：統一動畫介面
extension View {
    
    /// 应用统一的动画预设
    func animate(_ preset: AnimationPreset, value: some Equatable) -> some View {
        self.animation(preset.animation, value: value)
    }
    
    /// 应用统一的过渡效果
    func transition(_ preset: AnimationPreset) -> some View {
        self.transition(preset.transition)
    }
    
    /// 按钮点击动画效果
    func buttonPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(MicroInteractions.buttonTap(), value: isPressed)
    }
    
    /// 卡片悬停动画效果
    func cardHoverAnimation(isHovered: Bool) -> some View {
        self
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: Color.black.opacity(isHovered ? 0.08 : 0.04),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .animation(MicroInteractions.cardHover(), value: isHovered)
    }
    
    /// 输入框聚焦动画
    func inputFocusAnimation(isFocused: Bool) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: ModernRadius.sm)
                    .stroke(
                        isFocused ? Color.modernAccent : Color.clear,
                        lineWidth: isFocused ? 2 : 0
                    )
                    .animation(MicroInteractions.inputFocus(), value: isFocused)
            )
    }
    
    /// 脉冲效果（用于加载或强调）
    func pulseEffect(isActive: Bool) -> some View {
        self
            .opacity(isActive ? 0.6 : 1.0)
            .animation(
                isActive ? AnimationCurves.smoothPulse : .default,
                value: isActive
            )
    }
    
    /// 呼吸效果（更柔和的脉冲）
    func breatheEffect(isActive: Bool) -> some View {
        self
            .scaleEffect(isActive ? 1.02 : 1.0)
            .animation(
                isActive ? AnimationCurves.breathe : .default,
                value: isActive
            )
    }
    
    /// 页面转场动画
    func pageTransition(isForward: Bool = true) -> some View {
        self
            .transition(isForward ? TransitionEffects.pageSlide : TransitionEffects.pageSlideBack)
    }
    
    /// 模态弹出动画
    func modalTransition() -> some View {
        self
            .transition(TransitionEffects.modalPresent)
    }
    
    /// 卡片翻转动画
    func cardFlipTransition() -> some View {
        self
            .transition(TransitionEffects.cardFlip)
    }
}

// MARK: - 高级动画工具
struct AnimationTools {
    
    /// 创建延迟动画序列
    static func delayedAnimation(
        delay: TimeInterval,
        animation: Animation = AnimationCurves.easeInOut,
        action: @escaping () -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(animation) {
                action()
            }
        }
    }
    
    /// 创建渐进式动画序列
    static func staggeredAnimation<T: Collection>(
        items: T,
        delay: TimeInterval = 0.1,
        animation: Animation = AnimationCurves.gentleSpring,
        action: @escaping (T.Index) -> Void
    ) {
        for (index, _) in items.enumerated() {
            let itemDelay = TimeInterval(index) * delay
            DispatchQueue.main.asyncAfter(deadline: .now() + itemDelay) {
                withAnimation(animation) {
                    if let itemIndex = items.index(items.startIndex, offsetBy: index, limitedBy: items.endIndex) {
                        action(itemIndex)
                    }
                }
            }
        }
    }
    
    /// 创建连锁动画效果
    static func chainedAnimation(
        steps: [(delay: TimeInterval, animation: Animation, action: () -> Void)]
    ) {
        var totalDelay: TimeInterval = 0
        
        for step in steps {
            totalDelay += step.delay
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
                withAnimation(step.animation) {
                    step.action()
                }
            }
        }
    }
}

// MARK: - 動畫狀態管理
@Observable
class AnimationState {
    var isAnimating = false
    var animationProgress: Double = 0.0
    var currentPreset: AnimationPreset = .smooth
    
    func startAnimation(preset: AnimationPreset = .smooth) {
        currentPreset = preset
        withAnimation(preset.animation) {
            isAnimating = true
        }
    }
    
    func stopAnimation() {
        withAnimation(currentPreset.animation) {
            isAnimating = false
            animationProgress = 0.0
        }
    }
    
    func updateProgress(_ progress: Double) {
        withAnimation(AnimationCurves.easeOut) {
            animationProgress = min(max(progress, 0.0), 1.0)
        }
    }
}