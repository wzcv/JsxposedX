import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_controller.dart';
import 'package:flutter/widgets.dart';

class OverlayWindowScope extends InheritedNotifier<OverlayWindowController> {
  OverlayWindowScope({
    super.key,
    OverlayWindowController? controller,
    required super.child,
  }) : super(notifier: controller ?? OverlayWindowController.instance);

  static OverlayWindowController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OverlayWindowScope>();
    return scope?.notifier;
  }

  static OverlayWindowController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null);
    return controller!;
  }
}
