# react-native-nitro-key-shortcuts

Hardware-keyboard shortcuts for React Native on iOS and Android, built with [Nitro Modules](https://nitro.margelo.com).

- Register shortcuts such as ⌘Z, Ctrl+C, arrow keys or Escape from JavaScript and get a callback when one fires.
- On iOS, titled shortcuts appear in the hold-⌘ overlay and the iPadOS / Mac menu bar.
- Shortcuts keep working while a React Native `Modal` is open on Android.
- Optional Ctrl + mouse wheel (or trackpad) events, the usual "zoom" gesture.

Requires the New Architecture and `react-native-nitro-modules` 0.35 or newer.

## Installation

```sh
yarn add react-native-nitro-key-shortcuts react-native-nitro-modules
cd ios && pod install
```

The library cannot see key events by itself. The app has to forward them, which takes a few lines on each platform.

### iOS

UIKit asks the responder chain for key commands, and the app delegate is its last responder.

1. Declare the library's class in your bridging header (or any Objective-C header the app delegate imports). Declaring it, instead of importing the Swift module, means the app target doesn't need C++ interop.

   ```objc
   #import <UIKit/UIKit.h>

   @interface KeyShortcutCommands : NSObject
   + (NSArray<UIKeyCommand *> *)commands;
   + (void)performCommand:(UIKeyCommand *)command NS_SWIFT_NAME(handle(_:));
   @end
   ```

2. Hand the commands to UIKit from `AppDelegate.swift`. The method must be named `handleKeyShortcut`.

   ```swift
   override var keyCommands: [UIKeyCommand]? {
     KeyShortcutCommands.commands()
   }

   @objc func handleKeyShortcut(_ command: UIKeyCommand) {
     KeyShortcutCommands.handle(command)
   }
   ```

   In an Objective-C app delegate:

   ```objc
   - (NSArray<UIKeyCommand *> *)keyCommands {
     return [KeyShortcutCommands commands];
   }

   - (void)handleKeyShortcut:(UIKeyCommand *)command {
     [KeyShortcutCommands performCommand:command];
   }
   ```

### Android

In `MainActivity.kt`:

```kotlin
import android.view.KeyEvent
import android.view.MotionEvent
import com.margelo.nitro.keyshortcuts.KeyShortcutsRegistry
import com.margelo.nitro.keyshortcuts.ModalKeyShortcuts

class MainActivity : ReactActivity() {
  override fun dispatchKeyEvent(event: KeyEvent): Boolean {
    if (KeyShortcutsRegistry.handle(this, event)) {
      return true
    }
    return super.dispatchKeyEvent(event)
  }

  // Only needed for Ctrl + scroll events.
  override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
    if (KeyShortcutsRegistry.handleZoomScroll(this, event)) {
      return true
    }
    return super.dispatchGenericMotionEvent(event)
  }

  // Only needed for shortcuts while a React Native Modal is open.
  override fun onWindowFocusChanged(hasFocus: Boolean) {
    super.onWindowFocusChanged(hasFocus)
    if (!hasFocus) {
      ModalKeyShortcuts.install(window.decorView)
    }
  }
}
```

## Usage

```ts
import { getKeyShortcuts } from 'react-native-nitro-key-shortcuts'

const shortcuts = getKeyShortcuts()

shortcuts.setListener((id, isRepeat) => {
  if (id === 'undo') {
    undo()
  }
})

shortcuts.setShortcuts([
  {
    id: 'undo',
    key: 'z',
    meta: true,
    shift: false,
    ctrl: false,
    alt: false,
    title: 'Undo',
    repeats: false,
    priority: false,
  },
])
```

`setShortcuts` replaces the whole set in one call, and there is one listener for the app. If several components own shortcuts, merge their lists in JavaScript before calling it.

### `KeyShortcut`

| Field | Meaning |
| --- | --- |
| `id` | Passed to the listener when the shortcut fires. |
| `key` | A lowercase letter or digit, or `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `Backspace`, `Delete`, `Escape`, `Enter`. |
| `shift`, `ctrl`, `alt`, `meta` | Modifiers. `meta` is ⌘ on iOS and the Meta key on Android. |
| `title` | Optional, iOS only. Lists the shortcut under this name in the hold-⌘ overlay and the menu bar. |
| `repeats` | Fire again while the key is held. |
| `priority` | iOS only. The shortcut wins over system handling such as arrow-key scrolling. Leave it off for keys a focused text field should keep. |

### Methods

| Method | Meaning |
| --- | --- |
| `setShortcuts(shortcuts)` | Replace every registered shortcut. |
| `setListener((id, isRepeat) => void)` | Set the callback for fired shortcuts. |
| `removeListener()` | Remove it. |
| `setZoomScrollListener((delta, x, y) => void)` | Receive Ctrl + wheel or trackpad scrolls. `delta` is in points, positive when the content would move down; `x` and `y` are the pointer in window points. While set, those scrolls are consumed. |
| `removeZoomScrollListener()` | Remove it. |

## Platform notes

- **Text fields.** On Android a focused `EditText` keeps any key without Ctrl or Meta, so typing and editing still work. On iOS, use `priority: false` for such keys.
- **Held keys.** iOS does not report whether a firing is a repeat, so `isRepeat` is always `false` there.
- **Modals on Android.** Escape and Back always stay with the modal, and so does every key while one of its text fields has focus.
- **Ctrl + scroll on iOS.** iOS may deliver a trackpad Ctrl-scroll as a pinch, which is not reported. Scrolls over a presented view controller are ignored.

## Jest

```js
jest.mock('react-native-nitro-key-shortcuts', () =>
  require('react-native-nitro-key-shortcuts/jest/mock')
)
```

`getKeyShortcuts()` then returns one shared object of `jest.fn()` methods.

## Development

```sh
yarn install
yarn specs   # compile src/ to lib/ and regenerate nitrogen/generated
```

Commit `nitrogen/generated/` and `lib/` together with spec changes.
