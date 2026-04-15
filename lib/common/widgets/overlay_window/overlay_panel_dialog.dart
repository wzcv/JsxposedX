import 'package:flutter/material.dart';

class OverlayPanelViewport {
  const OverlayPanelViewport(this.constraints);

  final BoxConstraints constraints;

  bool get isLandscape =>
      constraints.maxWidth > constraints.maxHeight * 1.1;

  double get availableWidth =>
      (constraints.maxWidth - 20.0).clamp(0.0, double.infinity).toDouble();

  double get availableHeight =>
      constraints.maxHeight.clamp(0.0, double.infinity).toDouble();
}

typedef OverlayPanelDialogBuilder = Widget Function(
  BuildContext context,
  OverlayPanelViewport viewport,
);

class OverlayPanelDialog extends StatelessWidget {
  const OverlayPanelDialog({
    super.key,
    required this.childBuilder,
    this.onClose,
    this.barrierDismissible = true,
    this.barrierOpacity = 0.35,
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0),
    this.alignment = Alignment.center,
  });

  final OverlayPanelDialogBuilder childBuilder;
  final VoidCallback? onClose;
  final bool barrierDismissible;
  final double barrierOpacity;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: barrierOpacity),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: barrierDismissible ? onClose : null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = OverlayPanelViewport(constraints);

            return Align(
              alignment: alignment,
              child: Padding(
                padding: padding,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {},
                  child: childBuilder(context, viewport),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
