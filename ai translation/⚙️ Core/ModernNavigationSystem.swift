// ModernNavigationSystem.swift - 現代導航轉場系統
// 提供流暢的頁面轉場動畫體驗

import SwiftUI

// MARK: - 導航方向定義
enum NavigationDirection: Hashable {
    case forward    // 前進（右到左）
    case backward   // 後退（左到右）
    case up         // 向上
    case down       // 向下
    case present    // 模態展示
    case dismiss    // 模態關閉
}

// MARK: - 頁面轉場樣式
enum PageTransitionStyle: Hashable {
    case slide      // 滑動轉場
    case fade       // 淡入淡出
    case scale      // 縮放
    case push       // 推送
    case cover      // 覆蓋
    case reveal     // 揭示
    case flip       // 翻轉
    case custom(insertion: AnyTransition, removal: AnyTransition) // 自定義
    
    // 實現 Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .slide:
            hasher.combine("slide")
        case .fade:
            hasher.combine("fade")
        case .scale:
            hasher.combine("scale")
        case .push:
            hasher.combine("push")
        case .cover:
            hasher.combine("cover")
        case .reveal:
            hasher.combine("reveal")
        case .flip:
            hasher.combine("flip")
        case .custom:
            hasher.combine("custom")
        }
    }
    
    // 實現 Equatable
    static func == (lhs: PageTransitionStyle, rhs: PageTransitionStyle) -> Bool {
        switch (lhs, rhs) {
        case (.slide, .slide), (.fade, .fade), (.scale, .scale),
             (.push, .push), (.cover, .cover), (.reveal, .reveal), (.flip, .flip):
            return true
        case (.custom, .custom):
            return true // 簡化比較，實際上可能需要更詳細的比較
        default:
            return false
        }
    }
    
    func transition(for direction: NavigationDirection) -> AnyTransition {
        switch self {
        case .slide:
            switch direction {
            case .forward:
                return .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                )
            case .backward:
                return .asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                )
            case .up:
                return .asymmetric(
                    insertion: .move(edge: .top),
                    removal: .move(edge: .bottom)
                )
            case .down:
                return .asymmetric(
                    insertion: .move(edge: .bottom),
                    removal: .move(edge: .top)
                )
            case .present:
                return .asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                )
            case .dismiss:
                return .asymmetric(
                    insertion: .opacity,
                    removal: .move(edge: .bottom).combined(with: .opacity)
                )
            }
            
        case .fade:
            return .opacity
            
        case .scale:
            return .asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 1.1).combined(with: .opacity)
            )
            
        case .push:
            switch direction {
            case .forward:
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .leading).combined(with: .scale(scale: 1.05))
                )
            case .backward:
                return .asymmetric(
                    insertion: .move(edge: .leading).combined(with: .scale(scale: 0.95)),
                    removal: .move(edge: .trailing).combined(with: .scale(scale: 1.05))
                )
            default:
                return .scale.combined(with: .opacity)
            }
            
        case .cover:
            return .asymmetric(
                insertion: .move(edge: direction == .forward ? .trailing : .leading),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            )
            
        case .reveal:
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 1.05)),
                removal: .move(edge: direction == .forward ? .leading : .trailing)
            )
            
        case .flip:
            return .asymmetric(
                insertion: .scale(scale: 0.1).combined(with: .opacity),
                removal: .scale(scale: 0.1).combined(with: .opacity)
            )
            
        case .custom(let insertion, let removal):
            return .asymmetric(insertion: insertion, removal: removal)
        }
    }
}

// MARK: - 導航管理器
@Observable
class ModernNavigationManager {
    var currentDirection: NavigationDirection = .forward
    var transitionStyle: PageTransitionStyle = .slide
    var animationDuration: TimeInterval = AnimationDuration.normal
    var isNavigating: Bool = false
    
    // 導航歷史堆疊
    private var navigationStack: [String] = []
    
    // 預定義的頁面轉場組合
    static let defaultTransitions: [String: PageTransitionStyle] = [
        "authentication": .slide,
        "dashboard": .push,
        "details": .slide,
        "settings": .cover,
        "modal": .fade,
        "picker": .scale
    ]
    
    func navigate(
        to destination: String,
        direction: NavigationDirection = .forward,
        style: PageTransitionStyle? = nil,
        animated: Bool = true
    ) {
        // 設置導航參數
        currentDirection = direction
        transitionStyle = style ?? Self.defaultTransitions[destination] ?? .slide
        
        // 更新導航堆疊
        if direction == .forward {
            navigationStack.append(destination)
        } else if direction == .backward && !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
        
        // 執行導航動畫
        if animated {
            withAnimation(getNavigationAnimation()) {
                isNavigating = true
            }
            
            // 重置導航狀態
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                self.isNavigating = false
            }
        }
    }
    
    func goBack(animated: Bool = true) {
        navigate(to: "", direction: .backward, animated: animated)
    }
    
    func presentModal(destination: String, style: PageTransitionStyle = .fade) {
        navigate(to: destination, direction: .present, style: style)
    }
    
    func dismissModal(animated: Bool = true) {
        navigate(to: "", direction: .dismiss, animated: animated)
    }
    
    func getNavigationAnimation() -> Animation {
        switch transitionStyle {
        case .slide, .push, .cover, .reveal:
            return AnimationCurves.gentleSpring
        case .fade:
            return AnimationCurves.easeInOut
        case .scale, .flip:
            return AnimationCurves.bounceSpring
        case .custom:
            return AnimationCurves.easeInOut
        }
    }
    
    // 取得當前轉場
    func getCurrentTransition() -> AnyTransition {
        return transitionStyle.transition(for: currentDirection)
    }
}

// MARK: - View 擴展：導航動畫
extension View {
    
    /// 應用導航轉場動畫
    func navigationTransition(
        _ manager: ModernNavigationManager,
        isPresented: Bool
    ) -> some View {
        self
            .transition(manager.getCurrentTransition())
            .animation(manager.getNavigationAnimation(), value: isPresented)
    }
    
    /// 頁面轉場包裝器
    func pageTransition(
        style: PageTransitionStyle = .slide,
        direction: NavigationDirection = .forward
    ) -> some View {
        self
            .transition(style.transition(for: direction))
    }
    
    /// 模態轉場
    func modalTransition(style: PageTransitionStyle = .fade) -> some View {
        self
            .transition(style.transition(for: .present))
            .animation(AnimationCurves.gentleSpring, value: true)
    }
    
    /// 標籤轉場
    func tabTransition() -> some View {
        self
            .transition(TransitionEffects.gentleAppear)
            .animation(AnimationCurves.quickEaseOut, value: true)
    }
}

// MARK: - 導航路由系統
struct NavigationRoute: Hashable {
    let id: String
    let title: String
    let style: PageTransitionStyle
    let direction: NavigationDirection
    
    init(
        _ id: String,
        title: String = "",
        style: PageTransitionStyle = .slide,
        direction: NavigationDirection = .forward
    ) {
        self.id = id
        self.title = title
        self.style = style
        self.direction = direction
    }
}

// MARK: - 現代導航容器
struct ModernNavigationContainer<Content: View>: View {
    @State private var navigationManager = ModernNavigationManager()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(navigationManager)
    }
}

// MARK: - 導航按鈕組件
struct ModernNavigationButton: View {
    let title: String
    let icon: String?
    let destination: NavigationRoute
    let style: ModernButtonStyle
    let action: (() -> Void)?
    
    @Environment(ModernNavigationManager.self) private var navigationManager
    
    init(
        _ title: String,
        icon: String? = nil,
        destination: NavigationRoute,
        style: ModernButtonStyle = .primary,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.icon = icon
        self.destination = destination
        self.style = style
        self.action = action
    }
    
    var body: some View {
        ModernButton(
            title,
            icon: icon,
            style: style
        ) {
            // 執行自定義動作
            action?()
            
            // 執行導航
            navigationManager.navigate(
                to: destination.id,
                direction: destination.direction,
                style: destination.style
            )
            
            // 觸覺反饋
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - 頁面切換動畫控制器
@Observable
class PageSwitchAnimator {
    var currentPageIndex: Int = 0
    var previousPageIndex: Int = 0
    var isAnimating: Bool = false
    
    func switchTo(
        pageIndex: Int,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard pageIndex != currentPageIndex else { return }
        
        previousPageIndex = currentPageIndex
        
        if animated {
            withAnimation(AnimationCurves.gentleSpring) {
                isAnimating = true
                currentPageIndex = pageIndex
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.normal) {
                self.isAnimating = false
                completion?()
            }
        } else {
            currentPageIndex = pageIndex
            completion?()
        }
    }
    
    func getTransitionDirection() -> NavigationDirection {
        return currentPageIndex > previousPageIndex ? .forward : .backward
    }
    
    func getTransitionForPage(at index: Int) -> AnyTransition {
        let direction = getTransitionDirection()
        return PageTransitionStyle.slide.transition(for: direction)
    }
}

// MARK: - 增強的 TabView 替代方案
struct ModernTabContainer<Content: View>: View {
    @Binding var selection: Int
    let content: Content
    @State private var animator = PageSwitchAnimator()
    
    init(selection: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(animator)
            .onChange(of: selection) { oldValue, newValue in
                animator.switchTo(pageIndex: newValue)
            }
    }
}

// MARK: - 預覽和測試
#if DEBUG
struct NavigationSystemPreview: View {
    @State private var showSecondPage = false
    @State private var showModal = false
    @State private var navigationManager = ModernNavigationManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: ModernSpacing.xl) {
                Text("導航系統展示")
                    .font(.appTitle2())
                
                VStack(spacing: ModernSpacing.lg) {
                    // 基本導航按鈕
                    ModernNavigationButton(
                        "滑動轉場",
                        icon: "arrow.right",
                        destination: NavigationRoute("slide", style: .slide)
                    ) {
                        showSecondPage = true
                    }
                    
                    ModernNavigationButton(
                        "淡入轉場",
                        icon: "circle.fill",
                        destination: NavigationRoute("fade", style: .fade)
                    ) {
                        showSecondPage = true
                    }
                    
                    ModernNavigationButton(
                        "縮放轉場",
                        icon: "plus.magnifyingglass",
                        destination: NavigationRoute("scale", style: .scale)
                    ) {
                        showSecondPage = true
                    }
                    
                    ModernNavigationButton(
                        "模態展示",
                        icon: "square.and.arrow.up",
                        destination: NavigationRoute("modal", style: .cover, direction: .present),
                        style: .secondary
                    ) {
                        showModal = true
                    }
                }
            }
            .padding(ModernSpacing.xl)
            .environment(navigationManager)
            .navigationTitle("導航系統")
        }
        .sheet(isPresented: $showModal) {
            VStack(spacing: ModernSpacing.xl) {
                Text("模態頁面")
                    .font(.appTitle2())
                
                ModernButton("關閉", style: .secondary) {
                    showModal = false
                }
            }
            .padding(ModernSpacing.xl)
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showSecondPage) {
            SecondPageView(isPresented: $showSecondPage)
                .environment(navigationManager)
        }
    }
}

struct SecondPageView: View {
    @Binding var isPresented: Bool
    @Environment(ModernNavigationManager.self) private var navigationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: ModernSpacing.xl) {
                Text("第二頁")
                    .font(.appTitle2())
                
                Text("這是透過轉場動畫進入的頁面")
                    .font(.appBody())
                    .foregroundStyle(Color.modernTextSecondary)
                
                ModernButton("返回", icon: "arrow.left", style: .secondary) {
                    navigationManager.goBack()
                    isPresented = false
                }
            }
            .padding(ModernSpacing.xl)
            .navigationTitle("第二頁")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        isPresented = false
                    }
                }
            }
        }
        .pageTransition(style: .slide, direction: .forward)
    }
}

#Preview("導航系統") {
    NavigationSystemPreview()
}
#endif