package com.margelo.nitro.keyshortcuts

/**
 * The JS side of the app-wide keyboard shortcuts. It only forwards to
 * [KeyShortcutsRegistry], which `MainActivity` consults for key events.
 */
class HybridKeyShortcuts : HybridKeyShortcutsSpec() {
  // One per JS runtime: drop what a reloaded runtime left behind.
  init {
    KeyShortcutsRegistry.replace(emptyList())
    KeyShortcutsRegistry.setListener(null)
    KeyShortcutsRegistry.setZoomScrollListener(null)
  }

  override fun setShortcuts(shortcuts: Array<KeyShortcut>) {
    KeyShortcutsRegistry.replace(shortcuts.toList())
  }

  override fun setListener(listener: (id: String, isRepeat: Boolean) -> Unit) {
    KeyShortcutsRegistry.setListener(listener)
  }

  override fun removeListener() {
    KeyShortcutsRegistry.setListener(null)
  }

  override fun setZoomScrollListener(listener: (delta: Double, x: Double, y: Double) -> Unit) {
    KeyShortcutsRegistry.setZoomScrollListener(listener)
  }

  override fun removeZoomScrollListener() {
    KeyShortcutsRegistry.setZoomScrollListener(null)
  }
}
