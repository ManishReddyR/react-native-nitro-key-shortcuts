import UIKit

/// Ctrl + mouse wheel scroll on the key window, reported instead of scrolling. Main thread only.
@MainActor
final class ZoomScroll: NSObject, UIGestureRecognizerDelegate {
  static let shared = ZoomScroll()

  private var listener: ((Double, Double, Double) -> Void)?
  private var recognizer: UIPanGestureRecognizer?
  private var lastTranslationY: CGFloat = 0
  // A scroll's location moves with its translation, like a dragged finger; the pointer is where it began.
  private var pointer: CGPoint = .zero

  func setListener(_ newListener: ((Double, Double, Double) -> Void)?) {
    listener = newListener
    if newListener == nil {
      uninstall()
    } else {
      install()
    }
  }

  private func install() {
    if recognizer?.view != nil {
      return
    }
    guard let window = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .flatMap({ $0.windows })
      .first(where: { $0.isKeyWindow })
    else {
      return
    }
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handle(_:)))
    pan.allowedScrollTypesMask = .all
    // Scrolls count as indirect-pointer input; with no touch types allowed none arrive.
    pan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
    pan.cancelsTouchesInView = false
    pan.delaysTouchesBegan = false
    pan.delaysTouchesEnded = false
    pan.delegate = self
    window.addGestureRecognizer(pan)
    recognizer = pan
  }

  private func uninstall() {
    if let pan = recognizer {
      pan.view?.removeGestureRecognizer(pan)
    }
    recognizer = nil
  }

  @objc private func handle(_ pan: UIPanGestureRecognizer) {
    guard let view = pan.view else {
      return
    }
    switch pan.state {
    case .began, .changed:
      if pan.state == .began {
        lastTranslationY = 0
        pointer = pan.location(in: view)
      }
      let translationY = pan.translation(in: view).y
      let delta = translationY - lastTranslationY
      lastTranslationY = translationY
      if delta != 0 {
        listener?(Double(delta), Double(pointer.x), Double(pointer.y))
      }
    default:
      lastTranslationY = 0
    }
  }

  // Not the pointer's clicks and drags.
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
    return event.type == .scroll
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return listener != nil &&
      gestureRecognizer.modifierFlags.contains(.control) &&
      !isOverPresentedController(gestureRecognizer)
  }

  // Modals and alerts are presented in this same window, outside the root view.
  private func isOverPresentedController(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let window = gestureRecognizer.view as? UIWindow,
          let rootView = window.rootViewController?.view,
          let hit = window.hitTest(gestureRecognizer.location(in: window), with: nil)
    else {
      return false
    }
    return !hit.isDescendant(of: rootView)
  }

  // Other scroll-accepting pans wait, so a Ctrl-scroll doesn't also scroll.
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    guard let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer,
          otherPan !== gestureRecognizer
    else {
      return false
    }
    return !otherPan.allowedScrollTypesMask.isEmpty
  }
}
