import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// Launch as a menu-bar agent (no Dock icon). AppDelegate promotes this to
// .regular only when the user explicitly enables "Dock'ta Göster".
app.setActivationPolicy(.accessory)
app.run()
