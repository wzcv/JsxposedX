import 'package:JsxposedX/common/widgets/overlay_window/overlay_panel_dialog.dart';
import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemoryToolProcessTerminatedDialog extends StatelessWidget {
  const MemoryToolProcessTerminatedDialog({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return OverlayPanelDialog(
      barrierDismissible: false,
      childBuilder: (context, viewport) {
        final isLandscapeDialog = viewport.isLandscape;
        final availableWidth = viewport.availableWidth;
        final availableHeight = viewport.availableHeight;
        final dialogWidthCap = isLandscapeDialog ? 520.0 : 372.0;
        final dialogHeightCap = isLandscapeDialog ? 248.0 : 280.0;
        final dialogWidth = availableWidth < dialogWidthCap
            ? availableWidth
            : dialogWidthCap;
        final dialogMaxHeight = isLandscapeDialog
            ? availableHeight * 0.9
            : (availableHeight < dialogHeightCap
                  ? availableHeight
                  : dialogHeightCap);

        if (dialogWidth <= 0 || dialogMaxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return Material(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(18.r),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: dialogMaxHeight,
            ),
            child: SizedBox(
              width: dialogWidth,
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.l10n.memoryToolProcessTerminatedTitle,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10.r),
                    Text(
                      context.l10n.memoryToolProcessTerminatedDescription,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: 0.74,
                        ),
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 16.r),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: onConfirm,
                        child: Text(
                          context.l10n.memoryToolProcessTerminatedAction,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
