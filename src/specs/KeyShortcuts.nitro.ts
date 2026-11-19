import type { HybridObject } from 'react-native-nitro-modules'

/**
 * One hardware-keyboard shortcut.
 *
 * `key` is a lowercase letter or digit, or one of the named keys `ArrowUp`,
 * `ArrowDown`, `ArrowLeft`, `ArrowRight`, `Backspace`, `Delete`, `Escape`,
 * `Enter`. `meta` is ⌘ on iOS and the Meta key on Android.
 */
export interface KeyShortcut {
  /** Reported back to the listener when the shortcut fires. */
  id: string
  key: string
  shift: boolean
  ctrl: boolean
  alt: boolean
  meta: boolean
  /**
   * iOS only: listed under this name in the hold-⌘ shortcut overlay, the
   * iPadOS menu bar and, when the app runs on a Mac, the Mac menu bar. Omit to
   * keep the shortcut hidden.
   */
  title?: string
  /** Fire again while the key is held. Without it, held repeats are swallowed. */
  repeats: boolean
  /**
   * iOS only: `wantsPriorityOverSystemBehavior`, so the shortcut wins over
   * system handling such as arrow-key scrolling. Leave it off for keys a
   * focused text field should keep.
   */
  priority: boolean
}

/**
 * App-wide hardware-keyboard shortcuts.
 *
 * The whole set is replaced in one call, so there is never a moment with some
 * shortcuts unregistered. Key events reach it through two hooks in the app: the
 * AppDelegate's `keyCommands` on iOS and `MainActivity.dispatchKeyEvent` on
 * Android. On Android a key goes to a focused text field instead, unless the
 * shortcut uses Ctrl or Meta.
 */
export interface KeyShortcuts
  extends HybridObject<{ ios: 'swift'; android: 'kotlin' }> {
  setShortcuts(shortcuts: KeyShortcut[]): void
  setListener(listener: (id: string, isRepeat: boolean) => void): void
  removeListener(): void
  /**
   * Scrolls of a mouse wheel or trackpad made while Ctrl is held, the usual
   * zoom gesture. `delta` is the distance in points, positive when the content
   * would move down (a wheel rolled away from the user); `x` and `y` are the
   * pointer, in window points. While a listener is set those scrolls are
   * consumed, so nothing under the pointer scrolls as well. Other scrolls are
   * left alone, and a modal's window is never seen.
   *
   * iOS may deliver a trackpad Ctrl-scroll as a pinch instead, which never
   * reaches this listener.
   */
  setZoomScrollListener(
    listener: (delta: number, x: number, y: number) => void
  ): void
  removeZoomScrollListener(): void
}
