import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_controller.dart';
import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_scope.dart';
import 'package:flutter/material.dart';

class OverlayWindow extends StatelessWidget {
  const OverlayWindow({
    super.key,
    required this.child,
    this.header,
    this.title,
    this.onClose,
    this.footer,
    this.margin = const EdgeInsets.all(12),
    this.contentPadding = const EdgeInsets.all(16),
    this.decoration,
  });

  final Widget child;
  final Widget? header;
  final String? title;
  final VoidCallback? onClose;
  final Widget? footer;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry contentPadding;
  final Decoration? decoration;

  static Future<OverlayWindowStatus> show(
    BuildContext context, {
    OverlayWindowPresentation presentation =
        const OverlayWindowPresentation(),
  }) {
    return OverlayWindowScope.of(
      context,
    ).show(
      context,
      presentation: presentation,
    );
  }

  static Future<OverlayWindowStatus> dismiss(BuildContext context) {
    return OverlayWindowScope.of(context).hide();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedDecoration =
        decoration ??
        BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        );
    final resolvedHeader = header ?? _buildHeader(context);
    final hasHeader = resolvedHeader != null;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: margin,
          child: DecoratedBox(
            decoration: resolvedDecoration,
            child: Padding(
              padding: contentPadding,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (hasHeader) resolvedHeader,
                    if (hasHeader)
                      const SizedBox(height: 12),
                    child,
                    if (footer != null) ...<Widget>[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildHeader(BuildContext context) {
    if (title == null && onClose == null) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        if (title != null)
          Expanded(
            child: Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          const Spacer(),
        if (onClose != null)
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
