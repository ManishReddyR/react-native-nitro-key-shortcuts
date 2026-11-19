import UIKit

/// The registered shortcuts as UIKit key commands, plus the listener they
/// report to. `HybridKeyShortcuts` writes both from JS; the app's
/// AppDelegate hands `commands()` to UIKit and forwards each firing to
/// `perform(_:)`.
///
/// The AppDelegate reaches this class through an Objective-C declaration in its
/// bridging header (see the README), so it doesn't
/// have to import this Swift module. Keep the `@objc` names in step with it.
///
/// Main thread only: UIKit reads the commands there, and every write is hopped
/// there by `HybridKeyShortcuts`.
@MainActor
@objc(KeyShortcutCommands)
public final class KeyShortcutCommands: NSObject {
  /// A shortcut copied out of the generated Nitro struct, so it can cross to
  /// the main thread.
  struct Entry {
    let id: String
    let input: String
    let modifierFlags: UIKeyModifierFlags
    let title: String?
    let priority: Bool
  }

  private static var keyCommands: [UIKeyCommand] = []
  private static var listener: ((String, Bool) -> Void)?

  /// What the AppDelegate's `keyCommands` returns.
  @objc public static func commands() -> [UIKeyCommand] {
    return keyCommands
  }

  /// Called from the AppDelegate's `handleKeyShortcut:`. UIKit doesn't say
  /// whether a firing is a held-key repeat, so iOS always reports `false`.
  @objc(performCommand:)
  public static func perform(_ command: UIKeyCommand) {
    guard let id = command.propertyList as? String else {
      return
    }
    listener?(id, false)
  }

  static func replace(with entries: [Entry]) {
    keyCommands = entries.map { entry in
      let command = UIKeyCommand(
        title: entry.title ?? "",
        image: nil,
        action: NSSelectorFromString("handleKeyShortcut:"),
        input: entry.input,
        modifierFlags: entry.modifierFlags,
        propertyList: entry.id,
        alternates: [],
        discoverabilityTitle: entry.title,
        attributes: [],
        state: .off
      )
      command.wantsPriorityOverSystemBehavior = entry.priority
      return command
    }
  }

  static func setListener(_ newListener: ((String, Bool) -> Void)?) {
    listener = newListener
  }

  /// The UIKit input strings for a spec `key`, or none for a key it can't express.
  nonisolated static func inputs(for key: String) -> [String] {
    switch key {
    case "ArrowUp": return [UIKeyCommand.inputUpArrow]
    case "ArrowDown": return [UIKeyCommand.inputDownArrow]
    case "ArrowLeft": return [UIKeyCommand.inputLeftArrow]
    case "ArrowRight": return [UIKeyCommand.inputRightArrow]
    case "Escape": return [UIKeyCommand.inputEscape]
    case "Backspace": return ["\u{8}"]
    // Forward delete has no UIKit constant (`inputDelete` is "\u{8}", Backspace): DEL and NSDeleteFunctionKey.
    case "Delete": return ["\u{7F}", "\u{F728}"]
    case "Enter": return ["\r"]
    default: return key.count == 1 ? [key.lowercased()] : []
    }
  }
}
