package com.margelo.nitro.keyshortcuts

import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.Window
import android.widget.EditText
import com.facebook.react.views.modal.ReactModalHostView

/**
 * Keyboard shortcuts while a React Native modal is up.
 * Each modal is a Dialog with its own window, so its key events go to that window and never reach
 * [MainActivity.dispatchKeyEvent]. This puts the same shortcut check in front of each modal's
 * window; keys that aren't shortcuts carry on to the modal as before.
 *
 * Two things stay with the modal whatever is registered: Escape and Back, which close it, and
 * every key while one of its text fields has focus, so ⌘/Ctrl+X/C/V there edit the text rather
 * than fire a shortcut behind the modal.
 */
object ModalKeyShortcuts {
  /**
   * Route every open modal under [activityRoot] through the shortcuts. A modal's host view hands
   * out the modal's content as its children, so modals opened from other modals are found too.
   */
  @JvmStatic
  fun install(activityRoot: View) {
    forEachModalHost(activityRoot) { host ->
      host.dialog?.window?.let { route(it, activityRoot) }
    }
  }

  private fun forEachModalHost(view: View, action: (ReactModalHostView) -> Unit) {
    if (view is ReactModalHostView) {
      action(view)
    }
    if (view is ViewGroup) {
      for (i in 0 until view.childCount) {
        view.getChildAt(i)?.let { forEachModalHost(it, action) }
      }
    }
  }

  private fun route(window: Window, activityRoot: View) {
    val callback = window.callback ?: return
    if (callback is ShortcutWindowCallback) {
      return
    }
    window.callback = ShortcutWindowCallback(window, callback, activityRoot)
  }

  private class ShortcutWindowCallback(
      private val window: Window,
      private val delegate: Window.Callback,
      private val activityRoot: View,
  ) : Window.Callback by delegate {
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
      val focused = window.currentFocus
      val keepForModal =
          focused is EditText ||
              event.keyCode == KeyEvent.KEYCODE_ESCAPE ||
              event.keyCode == KeyEvent.KEYCODE_BACK
      return (!keepForModal && KeyShortcutsRegistry.handle(focused, event)) ||
          delegate.dispatchKeyEvent(event)
    }

    // A modal opened from this one takes the focus from it, not from the
    // activity, so MainActivity never hears about it; route it from here.
    override fun onWindowFocusChanged(hasFocus: Boolean) {
      delegate.onWindowFocusChanged(hasFocus)
      if (!hasFocus) {
        install(activityRoot)
      }
    }

    // A modal can replace its window while showing; the new one may take the focus straight from
    // this one without the activity or this window hearing about it, so look again once it's gone.
    override fun onDetachedFromWindow() {
      delegate.onDetachedFromWindow()
      activityRoot.post { install(activityRoot) }
    }
  }
}
