package com.margelo.nitro.keyshortcuts

import android.app.Activity
import android.os.Build
import android.view.InputDevice
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.widget.EditText

/**
 * The registered shortcuts and the listener they report to, shared by
 * [HybridKeyShortcuts] (written from the JS thread) and the app's key
 * dispatch (read on the UI thread): `MainActivity.dispatchKeyEvent`, and the
 * windows of any modals it routes here while they are up. Both fields are
 * replaced whole, never mutated, so a reader always sees a complete set.
 */
object KeyShortcutsRegistry {
  @Volatile private var shortcuts: List<KeyShortcut> = emptyList()
  @Volatile private var listener: ((id: String, isRepeat: Boolean) -> Unit)? = null
  @Volatile private var zoomScrollListener: ((delta: Double, x: Double, y: Double) -> Unit)? = null

  // Android's own fallback for a wheel notch before API 26 exposed it.
  private const val DEFAULT_SCROLL_FACTOR_DP = 64f

  internal fun replace(newShortcuts: List<KeyShortcut>) {
    shortcuts = newShortcuts
  }

  internal fun setListener(newListener: ((id: String, isRepeat: Boolean) -> Unit)?) {
    listener = newListener
  }

  internal fun setZoomScrollListener(newListener: ((delta: Double, x: Double, y: Double) -> Unit)?) {
    zoomScrollListener = newListener
  }

  /**
   * Call first thing in `Activity.dispatchGenericMotionEvent`. A mouse wheel or trackpad scroll
   * made while Ctrl is held goes to the zoom-scroll listener, in points, and is consumed. Returns
   * false for every other event, and for all of them while no listener is set.
   */
  @JvmStatic
  fun handleZoomScroll(activity: Activity, event: MotionEvent): Boolean {
    val zoomListener = zoomScrollListener ?: return false
    if (event.actionMasked != MotionEvent.ACTION_SCROLL ||
      !event.isFromSource(InputDevice.SOURCE_CLASS_POINTER) ||
      (event.metaState and KeyEvent.META_CTRL_ON) == 0
    ) {
      return false
    }
    val scroll = event.getAxisValue(MotionEvent.AXIS_VSCROLL)
    if (scroll != 0f) {
      val density = activity.resources.displayMetrics.density
      val pixelsPerUnit = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        ViewConfiguration.get(activity).scaledVerticalScrollFactor
      } else {
        DEFAULT_SCROLL_FACTOR_DP * density
      }
      zoomListener(
        (scroll * pixelsPerUnit / density).toDouble(),
        (event.x / density).toDouble(),
        (event.y / density).toDouble()
      )
    }
    return true
  }

  /**
   * Call first thing in `Activity.dispatchKeyEvent`, so shortcuts are seen
   * before the focused view. Returns true when the event belongs to a shortcut
   * and has been consumed - its key down, held repeats and key up alike.
   *
   * A focused text field keeps keys without Ctrl or Meta, so letters, arrows
   * and Backspace still type and edit there.
   */
  @JvmStatic
  fun handle(activity: Activity, event: KeyEvent): Boolean =
    handle(activity.currentFocus, event)

  /**
   * [handle] for a key event that reached some other window, such as a
   * dialog's, where `focused` is that window's focused view.
   */
  @JvmStatic
  fun handle(focused: View?, event: KeyEvent): Boolean {
    val key = keyName(event.keyCode) ?: return false
    val match = shortcuts.lastOrNull {
      it.key == key &&
        it.shift == event.isShiftPressed &&
        it.ctrl == event.isCtrlPressed &&
        it.alt == event.isAltPressed &&
        it.meta == event.isMetaPressed
    } ?: return false

    if (!match.ctrl && !match.meta && focused is EditText) {
      return false
    }

    if (event.action == KeyEvent.ACTION_DOWN) {
      val isRepeat = event.repeatCount > 0
      if (!isRepeat || match.repeats) {
        listener?.invoke(match.id, isRepeat)
      }
    }
    return true
  }

  private fun keyName(keyCode: Int): String? = when (keyCode) {
    in KeyEvent.KEYCODE_A..KeyEvent.KEYCODE_Z -> ('a' + (keyCode - KeyEvent.KEYCODE_A)).toString()
    in KeyEvent.KEYCODE_0..KeyEvent.KEYCODE_9 -> ('0' + (keyCode - KeyEvent.KEYCODE_0)).toString()
    KeyEvent.KEYCODE_DPAD_UP -> "ArrowUp"
    KeyEvent.KEYCODE_DPAD_DOWN -> "ArrowDown"
    KeyEvent.KEYCODE_DPAD_LEFT -> "ArrowLeft"
    KeyEvent.KEYCODE_DPAD_RIGHT -> "ArrowRight"
    KeyEvent.KEYCODE_DEL -> "Backspace"
    KeyEvent.KEYCODE_FORWARD_DEL -> "Delete"
    KeyEvent.KEYCODE_ESCAPE -> "Escape"
    KeyEvent.KEYCODE_ENTER, KeyEvent.KEYCODE_NUMPAD_ENTER -> "Enter"
    else -> null
  }
}
