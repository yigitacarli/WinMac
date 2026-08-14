import Cocoa
import Combine

@MainActor
public final class ClipboardManager: ObservableObject {
    public static let shared = ClipboardManager()
    
    @Published public var items: [ClipboardItem] = []
    @Published public var searchText: String = ""
    
    private var lastChangeCount: Int = 0
    private var pasteboardTimer: AnyCancellable?
    
    private init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        startMonitoring()
    }
    
    public var filteredItems: [ClipboardItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return items
        }
        let q = searchText.lowercased()
        return items.filter { $0.content.lowercased().contains(q) }
    }
    
    private func startMonitoring() {
        pasteboardTimer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkPasteboard()
            }
    }
    
    private func checkPasteboard() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount
        
        guard AppSettings.shared.clipboardHistoryEnabled else { return }
        
        if let string = NSPasteboard.general.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            
            items.removeAll { $0.content == string }
            
            let newItem = ClipboardItem(content: string)
            items.insert(newItem, at: 0)
            
            let maxLimit = AppSettings.shared.maxClipboardItems
            if items.count > maxLimit {
                items = Array(items.prefix(maxLimit))
            }
        }
    }
    
    public func pasteItem(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.content, forType: .string)
        self.lastChangeCount = pb.changeCount
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            SystemUtils.sendKeystroke(keyCode: 9, flags: .maskCommand) // 9 is V
        }
    }
    
    public func removeItem(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }
    
    public func clearAll() {
        items.removeAll()
    }
}
