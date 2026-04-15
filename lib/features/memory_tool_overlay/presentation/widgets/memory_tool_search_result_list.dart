import 'package:JsxposedX/features/memory_tool_overlay/presentation/providers/memory_tool_search_provider.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/states/memory_tool_result_selection_state.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/utils/memory_tool_search_result_presenter.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/widgets/memory_tool_search_result_tile.dart';
import 'package:JsxposedX/generated/memory_tool.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MemoryToolSearchResultList extends StatelessWidget {
  const MemoryToolSearchResultList({
    super.key,
    required this.listStorageKey,
    required this.results,
    required this.selectionState,
    required this.selectionNotifier,
    required this.livePreviewsAsync,
  });

  final PageStorageKey<String> listStorageKey;
  final List<SearchResult> results;
  final MemoryToolResultSelectionState selectionState;
  final MemoryToolResultSelectionController selectionNotifier;
  final AsyncValue<Map<int, MemoryValuePreview>> livePreviewsAsync;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: listStorageKey,
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, index) =>
          SizedBox(height: index == results.length - 1 ? 6.r : 4.r),
      itemBuilder: (BuildContext context, int index) {
        final result = results[index];
        return MemoryToolSearchResultTile(
          result: result,
          displayValue: resolveMemoryToolSearchResultDisplayValue(
            result: result,
            livePreviewsAsync: livePreviewsAsync,
          ),
          isSelected: selectionState.contains(result.address),
          onToggleSelection: () {
            selectionNotifier.toggle(result);
          },
        );
      },
    );
  }
}
