import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
let showInDock = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true
app.setActivationPolicy(showInDock ? .regular : .accessory)
app.run()
