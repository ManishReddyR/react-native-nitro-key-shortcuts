import UIKit
import NitroModules

/// The JS side of the app-wide keyboard shortcuts. It only forwards to
/// `KeyShortcutCommands`, which UIKit reads through the AppDelegate.
final class HybridKeyShortcuts: HybridKeyShortcutsSpec_base, HybridKeyShortcutsSpec_protocol {
  // One per JS runtime: drop what a reloaded runtime left behind.
  override init() {
    super.init()
    DispatchQueue.main.async {
      KeyShortcutCommands.replace(with: [])
      KeyShortcutCommands.setListener(nil)
      ZoomScroll.shared.setListener(nil)
    }
  }

  func setShortcuts(shortcuts: [KeyShortcut]) throws {
    // Copied out on the JS thread; only the copies travel to the main thread.
    let entries = shortcuts.flatMap { shortcut -> [KeyShortcutCommands.Entry] in
      var flags: UIKeyModifierFlags = []
      if shortcut.shift { flags.insert(.shift) }
      if shortcut.ctrl { flags.insert(.control) }
      if shortcut.alt { flags.insert(.alternate) }
      if shortcut.meta { flags.insert(.command) }
      return KeyShortcutCommands.inputs(for: shortcut.key).enumerated().map { index, input in
        KeyShortcutCommands.Entry(
          id: shortcut.id,
          input: input,
          modifierFlags: flags,
          // Listed once in the shortcut overlay, however many inputs it has.
          title: index == 0 ? shortcut.title : nil,
          priority: shortcut.priority
        )
      }
    }
    DispatchQueue.main.async {
      KeyShortcutCommands.replace(with: entries)
    }
  }

  func setListener(listener: @escaping (_ id: String, _ isRepeat: Bool) -> Void) throws {
    DispatchQueue.main.async {
      KeyShortcutCommands.setListener(listener)
    }
  }

  func removeListener() throws {
    DispatchQueue.main.async {
      KeyShortcutCommands.setListener(nil)
    }
  }

  func setZoomScrollListener(listener: @escaping (_ delta: Double, _ x: Double, _ y: Double) -> Void) throws {
    DispatchQueue.main.async {
      ZoomScroll.shared.setListener(listener)
    }
  }

  func removeZoomScrollListener() throws {
    DispatchQueue.main.async {
      ZoomScroll.shared.setListener(nil)
    }
  }
}

