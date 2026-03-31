import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a child widget to trigger [onSubmit] on Ctrl+Enter (or Cmd+Enter on macOS).
///
/// Use this around Form widgets so pressing Ctrl+Enter from any field submits the form.
class CtrlEnterSubmit extends StatelessWidget {
  final Widget child;
  final VoidCallback onSubmit;

  const CtrlEnterSubmit({
    super.key,
    required this.child,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): onSubmit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): onSubmit,
      },
      child: child,
    );
  }

  /// Creates a [FocusNode] that intercepts Ctrl+Enter (or Cmd+Enter) and calls [onSubmit].
  ///
  /// Use this on multiline [TextField]s where the Shortcuts approach may not
  /// intercept before the field consumes the Enter key.
  static FocusNode createFocusNode(VoidCallback onSubmit) {
    return FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            (HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed)) {
          onSubmit();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }
}
