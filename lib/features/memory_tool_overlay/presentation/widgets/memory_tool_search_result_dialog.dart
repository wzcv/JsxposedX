import 'package:JsxposedX/common/widgets/overlay_window/overlay_panel_dialog.dart';
import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/utils/memory_tool_search_result_presenter.dart';
import 'package:JsxposedX/generated/memory_tool.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemoryToolSearchResultDialog extends StatelessWidget {
  const MemoryToolSearchResultDialog({
    super.key,
    required this.result,
    required this.displayValue,
    required this.onClose,
  });

  final SearchResult result;
  final String displayValue;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverlayPanelDialog.card(
      onClose: onClose,
      maxWidthPortrait: 360.r,
      maxWidthLandscape: 420.r,
      maxHeightPortrait: 320.r,
      maxHeightLandscape: 300.r,
      cardBorderRadius: 18.r,
      childBuilder: (context, viewport, layout) {
        return Padding(
          padding: EdgeInsets.all(14.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                displayValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: context.colorScheme.primary,
                ),
              ),
              SizedBox(height: 12.r),
              _MemoryToolSearchResultDialogLine(
                label: 'Address',
                value: formatMemoryToolSearchResultAddress(result.address),
              ),
              SizedBox(height: 8.r),
              _MemoryToolSearchResultDialogLine(
                label: 'Type',
                value: mapMemoryToolSearchResultTypeLabel(
                  type: result.type,
                  displayValue: displayValue,
                ),
              ),
              SizedBox(height: 8.r),
              _MemoryToolSearchResultDialogLine(
                label: 'Region',
                value: mapMemoryToolSearchResultRegionTypeLabel(
                  context,
                  result.regionTypeKey,
                ),
              ),
              SizedBox(height: 12.r),
              Text(
                'TODO',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.64),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 14.r),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onClose,
                  child: Text(context.l10n.close),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemoryToolSearchResultDialogLine extends StatelessWidget {
  const _MemoryToolSearchResultDialogLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 58.r,
          child: Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 8.r),
        Expanded(
          child: Text(
            value,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
