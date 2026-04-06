import 'dart:async';

import 'package:JsxposedX/common/widgets/overlay_window/overlay_window.dart';
import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_scope.dart';
import 'package:flutter/material.dart';

class OverlayWindowRenderer extends StatelessWidget {
  const OverlayWindowRenderer({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlayWindow(
      onClose: () {
        unawaited(OverlayWindowScope.of(context).hide());
      },
      child: const SizedBox.shrink(),
    );
  }
}
