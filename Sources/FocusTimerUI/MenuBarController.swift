import AppKit
import Combine
import SwiftUI
import FocusTimerCore

/// 메뉴바 아이콘과 타이머 창을 관리합니다.
///
/// SwiftUI `MenuBarExtra`는 바깥을 클릭하면 창을 강제로 닫아서, 열려 있는 창을 그대로 고정하는
/// "항상 켜두기"를 만들 수 없습니다. 그래서 상태 아이템과 패널을 직접 띄웁니다.
@MainActor
public final class MenuBarController: NSObject, ObservableObject {
    /// "항상 켜두기": 켜져 있으면 바깥을 클릭해도 같은 창이 닫히지 않고 다른 창 위에 머물며, 끌어서 옮길 수 있습니다.
    @Published var isPinned = false {
        didSet {
            panel.level = isPinned ? .floating : .popUpMenu
            panel.isMovable = isPinned
            applyOpacity()
        }
    }

    /// 항상 켜두기 중에만 적용되는 창 전체 불투명도(0.3~1). 앱을 다시 실행해도 유지됩니다.
    @Published var pinnedOpacity = UserDefaults.standard.object(forKey: MenuBarController.pinnedOpacityKey) as? Double ?? 1 {
        didSet {
            UserDefaults.standard.set(pinnedOpacity, forKey: Self.pinnedOpacityKey)
            applyOpacity()
        }
    }

    private static let pinnedOpacityKey = "pinnedOpacity"

    private let timerStore: PomodoroStore
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let panel = MenuBarPanel()
    private var titleUpdates: AnyCancellable?

    public init(timerStore: PomodoroStore, profileStore: ProfileStore) {
        self.timerStore = timerStore
        super.init()

        let hostingController = NSHostingController(
            rootView: PanelContent(controller: self, timerStore: timerStore, profileStore: profileStore)
        )
        // 설정/프로필 화면으로 바뀔 때 창 크기도 내용에 맞춰 바뀝니다.
        hostingController.sizingOptions = .preferredContentSize
        panel.contentViewController = hostingController

        if let button = statusItem.button {
            button.font = .monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)
            button.target = self
            button.action = #selector(togglePanel)
        }
        updateTitle()
        titleUpdates = timerStore.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.updateTitle() } }

        // 다른 앱을 클릭하면 닫습니다. 단, 항상 켜두기 중에는 그대로 둡니다.
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.isPinned else { return }
                self.hidePanel()
            }
        }
    }

    private func applyOpacity() {
        panel.alphaValue = isPinned ? pinnedOpacity : 1
    }

    private func updateTitle() {
        statusItem.button?.title = timerStore.menuBarText
    }

    @objc private func togglePanel() {
        panel.isVisible ? hidePanel() : showPanel()
    }

    private func showPanel() {
        // 고정 중에 사용자가 옮겨 둔 위치는 유지하고, 그 외에는 메뉴바 아이콘 바로 아래에 엽니다.
        if !isPinned, let button = statusItem.button, let buttonWindow = button.window {
            let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            let screenMaxX = buttonWindow.screen?.visibleFrame.maxX ?? anchor.maxX
            let x = min(anchor.minX, screenMaxX - panel.frame.width)
            panel.setFrameTopLeftPoint(NSPoint(x: x, y: anchor.minY - 2))
        }
        panel.makeKeyAndOrderFront(nil)
        // 키 윈도우가 되면 AppKit이 첫 컨트롤(시작 버튼)에 자동 포커스를 줘 외곽선이 생기므로 해제합니다. Tab 이동은 그대로 됩니다.
        panel.makeFirstResponder(nil)
        statusItem.button?.highlight(true)
    }

    private func hidePanel() {
        panel.orderOut(nil)
        statusItem.button?.highlight(false)
    }
}

/// 체크박스와 투명도 조절 바가 컨트롤러 변경을 바로 반영하도록 관찰합니다.
private struct PanelContent: View {
    @ObservedObject var controller: MenuBarController
    let timerStore: PomodoroStore
    let profileStore: ProfileStore

    var body: some View {
        TimerPopoverView(
            timerStore: timerStore,
            profileStore: profileStore,
            isPinned: $controller.isPinned,
            pinnedOpacity: $controller.pinnedOpacity
        )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private final class MenuBarPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        level = .popUpMenu
        isMovable = false
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        appearance = NSAppearance(named: .darkAqua)
    }

    /// 테두리 없는 패널도 설정/프로필의 입력란에 타이핑할 수 있도록 키 윈도우가 되게 합니다.
    override var canBecomeKey: Bool { true }

    /// 설정/프로필 화면으로 바뀌어 높이가 달라져도 위쪽(메뉴바 쪽) 가장자리를 고정합니다.
    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        var frameRect = frameRect
        if isVisible, frameRect.height != frame.height {
            frameRect.origin.y = frame.maxY - frameRect.height
        }
        super.setFrame(frameRect, display: flag)
    }
}
