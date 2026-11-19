# react-native-nitro-key-shortcuts

Hardware-keyboard shortcuts for React Native on iOS (iPad, Mac Catalyst) and Android, built with [Nitro Modules](https://nitro.margelo.com).

- Register shortcuts like ⌘Z, Ctrl+Shift+S or arrow keys from JavaScript.
- On iOS, titled shortcuts appear in the hold-⌘ overlay and the menu bar.
- Receive Ctrl + scroll-wheel / trackpad events for pinch-free zooming.
- Works while a React Native `Modal` is open on Android.

Requires the New Architecture and `react-native-nitro-modules` 0.35 or newer.

## Installation

```sh
yarn add react-native-nitro-key-shortcuts react-native-nitro-modules
cd ios && pod install
```

The library can't see key events on its own — the app has to forward them. This is a one-time setup on each platform.

### iOS

**1.** Add this declaration to your bridging header (or any Objective-C header your app delegate imports). Declaring the class here means your app target doesn't need C++ interop.

```objc
#import <UIKit/UIKit.h>

@interface KeyShortcutCommands : NSObject
+ (NSArray<UIKeyCommand *> *)commands;
+ (void)performCommand:(UIKeyCommand *)command NS_SWIFT_NAME(handle(_:));
@end
```

**2.** Forward key commands from `AppDelegate.swift`. The method name must be exactly `handleKeyShortcut`.

```swift
override var keyCommands: [UIKeyCommand]? {
  KeyShortcutCommands.commands()
}

@objc func handleKeyShortcut(_ command: UIKeyCommand) {
  KeyShortcutCommands.handle(command)
}
```

<details>
<summary>Objective-C app delegate</summary>

```objc
- (NSArray<UIKeyCommand *> *)keyCommands {
  return [KeyShortcutCommands commands];
}

- (void)handleKeyShortcut:(UIKeyCommand *)command {
  [KeyShortcutCommands performCommand:command];
}
```

</details>

### Android

In `MainActivity.kt`:

```kotlin
import android.view.KeyEvent
import android.view.MotionEvent
import com.margelo.nitro.keyshortcuts.KeyShortcutsRegistry
import com.margelo.nitro.keyshortcuts.ModalKeyShortcuts

class MainActivity : ReactActivity() {
  override fun dispatchKeyEvent(event: KeyEvent): Boolean {
    if (KeyShortcutsRegistry.handle(this, event)) return true
    return super.dispatchKeyEvent(event)
  }

  // Optional: Ctrl + scroll events.
  override fun dispatchGenericMotionEvent(event: MotionEvent): Boolean {
    if (KeyShortcutsRegistry.handleZoomScroll(this, event)) return true
    return super.dispatchGenericMotionEvent(event)
  }

  // Optional: shortcuts while a React Native Modal is open.
  override fun onWindowFocusChanged(hasFocus: Boolean) {
    super.onWindowFocusChanged(hasFocus)
    if (!hasFocus) ModalKeyShortcuts.install(window.decorView)
  }
}
```

## Usage

```ts
import { getKeyShortcuts } from 'react-native-nitro-key-shortcuts'

const shortcuts = getKeyShortcuts()

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

shortcuts.setListener((id, isRepeat) => {
  if (id === 'undo') undo()
})
```

### In a component

There is one shortcut set and one listener for the whole app, and `setShortcuts` replaces the set each time. If several screens or components define shortcuts, merge their lists before registering:

```tsx
import { useEffect } from 'react'
import { getKeyShortcuts, type KeyShortcut } from 'react-native-nitro-key-shortcuts'

const shortcut = (id: string, key: string, mods: Partial<KeyShortcut> = {}): KeyShortcut => ({
  id, key, shift: false, ctrl: false, alt: false, meta: false,
  repeats: false, priority: false, ...mods,
})

export function useEditorShortcuts(handlers: Record<string, () => void>) {
  useEffect(() => {
    const ks = getKeyShortcuts()
    ks.setShortcuts([
      shortcut('undo', 'z', { meta: true, title: 'Undo' }),
      shortcut('redo', 'z', { meta: true, shift: true, title: 'Redo' }),
      shortcut('next', 'ArrowDown', { repeats: true }),
    ])
    ks.setListener((id) => handlers[id]?.())
    return () => {
      ks.setShortcuts([])
      ks.removeListener()
    }
  }, [handlers])
}
```

### Ctrl + scroll zoom

```ts
shortcuts.setZoomScrollListener((delta, x, y) => {
  // delta: points, positive when content would move down
  // x, y: pointer position in window points
  setScale((s) => Math.max(0.25, s * (1 - delta / 500)))
})
```

While a zoom listener is set, Ctrl + scroll events are consumed, so the view under the pointer won't scroll as well.

## API

### `getKeyShortcuts(): KeyShortcuts`

Returns the app-wide instance. Throws if the native module isn't linked.

| Method | Description |
| --- | --- |
| `setShortcuts(shortcuts)` | Replace every registered shortcut at once. |
| `setListener((id, isRepeat) => void)` | Called when a shortcut fires. |
| `removeListener()` | Remove the shortcut listener. |
| `setZoomScrollListener((delta, x, y) => void)` | Called for Ctrl + wheel or trackpad scrolls. |
| `removeZoomScrollListener()` | Remove the zoom listener. |

### `KeyShortcut`

| Field | Type | Description |
| --- | --- | --- |
| `id` | `string` | Passed to the listener when the shortcut fires. |
| `key` | `string` | A lowercase letter or digit, or `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`, `Backspace`, `Delete`, `Escape`, `Enter`. |
| `shift`, `ctrl`, `alt`, `meta` | `boolean` | Modifiers. `meta` is ⌘ on iOS and the Meta key on Android. |
| `title` | `string?` | iOS only. Shows the shortcut under this name in the hold-⌘ overlay and menu bar. Omit to keep it hidden. |
| `repeats` | `boolean` | Keep firing while the key is held. |
| `priority` | `boolean` | iOS only. Take precedence over system behaviour such as arrow-key scrolling. Keep `false` for keys a focused text field should receive. |

## Platform behaviour

| | iOS | Android |
| --- | --- | --- |
| **Focused text field** | Gets the key unless the shortcut has `priority: true`. | Gets any key without Ctrl or Meta, so typing still works. |
| **`isRepeat`** | Always `false` (iOS doesn't report it). | Reported. |
| **Modals** | Works. | Needs `ModalKeyShortcuts.install`. Escape/Back always go to the modal, as does every key while a field inside it is focused. |
| **Ctrl + scroll** | A trackpad Ctrl-scroll may arrive as a pinch and is not reported. Scrolls over a presented view controller are ignored. | Needs `dispatchGenericMotionEvent`. |

## Troubleshooting

- **Nothing fires on iOS** — check that `keyCommands` is overridden in the app delegate and the forwarding method is named exactly `handleKeyShortcut`.
- **Nothing fires on Android** — check that `dispatchKeyEvent` in `MainActivity` calls `KeyShortcutsRegistry.handle`.
- **A plain key (e.g. `ArrowDown`) doesn't fire while typing** — expected: text fields keep unmodified keys. Add Ctrl/Meta, or on iOS set `priority: true`.

## Testing with Jest

```js
jest.mock('react-native-nitro-key-shortcuts', () =>
  require('react-native-nitro-key-shortcuts/jest/mock')
)
```

`getKeyShortcuts()` then returns one shared object whose methods are `jest.fn()`s, so tests can inspect what was registered and call the listener to simulate a key press:

```ts
const ks = getKeyShortcuts()
const listener = (ks.setListener as jest.Mock).mock.calls.at(-1)[0]
listener('undo', false)
```

## Development

```sh
yarn install
yarn specs   # compile src/ to lib/ and regenerate nitrogen/generated
```

Commit `nitrogen/generated/` and `lib/` together with any spec change.
