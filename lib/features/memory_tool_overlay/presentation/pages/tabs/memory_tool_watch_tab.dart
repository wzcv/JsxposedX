import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/widgets/memory_tool_watch_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MemoryToolWatchTab extends StatelessWidget {
  const MemoryToolWatchTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(12.r),
      children: <Widget>[
        MemoryToolWatchPreviewCard(
          title: context.l10n.memoryToolWatchTabTitle,
          subtitle: context.l10n.memoryToolWatchTabSubtitle,
          rows: const <MemoryToolWatchPreviewRowData>[
            MemoryToolWatchPreviewRowData(
              label: 'HP',
              value: '100.0',
              type: 'Float',
            ),
            MemoryToolWatchPreviewRowData(
              label: 'Coins',
              value: '289',
              type: 'Dword',
            ),
            MemoryToolWatchPreviewRowData(
              label: 'Speed',
              value: '1.000',
              type: 'Double',
            ),
          ],
        ),
      ],
    );
  }
}
