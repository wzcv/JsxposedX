import 'dart:async';

import 'package:JsxposedX/features/memory_tool_overlay/presentation/enums/memory_search_range_preset_enum.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/enums/memory_search_range_section_enum.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/enums/memory_tool_pointer_alignment_option.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/providers/memory_pointer_action_provider.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/providers/memory_pointer_query_provider.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/states/memory_tool_pointer_form_state.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/states/memory_tool_pointer_state.dart';
import 'package:JsxposedX/generated/memory_tool.g.dart'
    show
        PointerScanRequest,
        PointerScanResult,
        PointerScanTaskState,
        PointerScanSessionState,
        SearchTaskStatus;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memory_tool_pointer_provider.g.dart';

const int memoryToolPointerPageSize = 100;

@riverpod
bool hasRunningPointerTask(Ref ref) {
  final taskStateAsync = ref.watch(getPointerScanTaskStateProvider);
  return taskStateAsync.maybeWhen(
    data: (state) => state.status == SearchTaskStatus.running,
    orElse: () => false,
  );
}

@riverpod
List<PointerScanResult> currentPointerResults(Ref ref) {
  return ref.watch(
    memoryToolPointerControllerProvider.select(
      (state) => state.currentLayer?.results ?? const <PointerScanResult>[],
    ),
  );
}

@Riverpod(keepAlive: true)
class MemoryToolPointerSearchForm extends _$MemoryToolPointerSearchForm {
  @override
  MemoryToolPointerFormState build() {
    return const MemoryToolPointerFormState();
  }

  void updatePointerWidth(int pointerWidth) {
    state = state.copyWith(
      pointerWidth: pointerWidth,
      clearValidationError: true,
    );
  }

  void updateMaxOffsetInput(String value) {
    state = state.copyWith(
      maxOffsetInput: value,
      clearValidationError: true,
    );
  }

  void updateMaxDepthInput(String value) {
    state = state.copyWith(
      maxDepthInput: value,
      clearValidationError: true,
    );
  }

  void updateHexOffset(bool value) {
    state = state.copyWith(isHexOffset: value, clearValidationError: true);
  }

  void updateAlignment(MemoryToolPointerAlignmentOption option) {
    state = state.copyWith(
      selectedAlignment: option,
      clearValidationError: true,
    );
  }

  void updateRangePreset(MemorySearchRangePresetEnum preset) {
    final shouldSeedCustomSections =
        preset == MemorySearchRangePresetEnum.custom &&
        state.customRangeSections.isEmpty;
    state = state.copyWith(
      selectedRangePreset: preset,
      customRangeSections: shouldSeedCustomSections
          ? const <MemorySearchRangeSectionEnum>[
              MemorySearchRangeSectionEnum.anonymous,
              MemorySearchRangeSectionEnum.cAlloc,
              MemorySearchRangeSectionEnum.other,
            ]
          : state.customRangeSections,
      clearValidationError: true,
    );
  }

  void toggleCustomRangeSection(MemorySearchRangeSectionEnum section) {
    final nextSections = List<MemorySearchRangeSectionEnum>.from(
      state.customRangeSections,
    );
    if (nextSections.contains(section)) {
      nextSections.remove(section);
    } else {
      nextSections.add(section);
      nextSections.sort((left, right) => left.index.compareTo(right.index));
    }
    state = state.copyWith(
      customRangeSections: nextSections,
      clearValidationError: true,
    );
  }

  int? tryParseMaxOffset() {
    final rawValue = state.maxOffsetInput.trim();
    if (rawValue.isEmpty) {
      state = state.copyWith(
        validationError: MemoryToolPointerFormValidationError.invalidMaxOffset,
      );
      return null;
    }

    final normalized = state.isHexOffset
        ? rawValue.replaceFirst(RegExp(r'^0x', caseSensitive: false), '')
        : rawValue;
    final parsed = int.tryParse(
      normalized,
      radix: state.isHexOffset ? 16 : 10,
    );
    if (parsed == null || parsed < 0) {
      state = state.copyWith(
        validationError: MemoryToolPointerFormValidationError.invalidMaxOffset,
      );
      return null;
    }
    state = state.copyWith(clearValidationError: true);
    return parsed;
  }

  int? tryParseMaxDepth() {
    final rawValue = state.maxDepthInput.trim();
    final parsed = int.tryParse(rawValue);
    if (parsed == null || parsed < 1 || parsed > 12) {
      state = state.copyWith(
        validationError: MemoryToolPointerFormValidationError.invalidMaxDepth,
      );
      return null;
    }
    state = state.copyWith(clearValidationError: true);
    return parsed;
  }
}

@Riverpod(keepAlive: true)
class MemoryToolPointerController extends _$MemoryToolPointerController {
  static const Set<String> _staticRegionTypeKeys = <String>{'cData', 'cBss'};
  int _autoChaseRunToken = 0;

  @override
  MemoryToolPointerState build() {
    return const MemoryToolPointerState();
  }

  Future<void> startRootScan({required PointerScanRequest request}) async {
    await _interruptAutoChaseIfNeeded();
    await _startFreshScan(request: request, isAutoChasing: false);
  }

  Future<void> startAutoChase({
    required PointerScanRequest request,
    required int maxDepth,
  }) async {
    _autoChaseRunToken += 1;
    final runToken = _autoChaseRunToken;
    state = MemoryToolPointerState(
      layers: <PointerChainLayerState>[
        PointerChainLayerState(
          request: request,
          autoChaseLayerIndex: 0,
          isLoadingInitial: true,
          staticOnlyMode: true,
        ),
      ],
      currentLayerIndex: 0,
      isAutoChasing: true,
      autoChaseMaxDepth: maxDepth,
      autoChaseCurrentDepth: 1,
    );
    unawaited(
      _runAutoChase(
        runToken: runToken,
        initialRequest: request,
        maxDepth: maxDepth,
      ),
    );
  }

  Future<void> continueScan({
    required PointerScanResult result,
    required PointerScanRequest baseRequest,
  }) async {
    await _interruptAutoChaseIfNeeded();
    final request = _buildNextRequest(
      baseRequest: baseRequest,
      targetAddress: result.pointerAddress,
    );
    final nextLayers = <PointerChainLayerState>[
      ...state.layers,
      PointerChainLayerState(
        request: request,
        sourceResult: result,
        isLoadingInitial: true,
        staticOnlyMode: false,
      ),
    ];
    state = state.copyWith(
      layers: nextLayers,
      currentLayerIndex: nextLayers.length - 1,
      isAutoChasing: false,
      autoChaseMaxDepth: 0,
      autoChaseCurrentDepth: 0,
      clearAutoChaseMessage: true,
    );
    try {
      await ref.read(memoryPointerActionProvider.notifier).startPointerScan(
        request: request,
      );
    } catch (error) {
      _updateLayer(
        nextLayers.length - 1,
        nextLayers.last.copyWith(
          isLoadingInitial: false,
          errorText: error.toString(),
        ),
      );
    }
  }

  Future<void> handleTaskCompleted() async {
    try {
      final sessionState = await ref.read(getPointerScanSessionStateProvider.future);
      await _refreshLayerForSession(sessionState);
    } catch (error) {
      final targetLayerIndex = _findActiveScanLayerIndex();
      if (targetLayerIndex >= 0 && targetLayerIndex < state.layers.length) {
        _updateLayer(
          targetLayerIndex,
          state.layers[targetLayerIndex].copyWith(
            isLoadingInitial: false,
            isLoadingMore: false,
            errorText: error.toString(),
          ),
        );
      }
    }
  }

  void handleTaskStopped({
    required SearchTaskStatus status,
    required String message,
  }) {
    final layerIndex = _findActiveScanLayerIndex();
    if (layerIndex < 0) {
      return;
    }

    final isCancelled = status == SearchTaskStatus.cancelled;
    _updateLayer(
      layerIndex,
      state.layers[layerIndex].copyWith(
        isLoadingInitial: false,
        isLoadingMore: false,
        errorText: isCancelled ? null : message,
        autoStopReasonKey: isCancelled ? 'cancelled' : null,
        clearErrorText: isCancelled,
      ),
    );
  }

  Future<void> cancelAutoChase() async {
    _autoChaseRunToken += 1;
    final layerIndex = state.currentLayerIndex;
    if (layerIndex >= 0 && layerIndex < state.layers.length) {
      _updateLayer(
        layerIndex,
        state.layers[layerIndex].copyWith(
          isLoadingInitial: false,
          isLoadingMore: false,
          autoStopReasonKey: 'cancelled',
          clearErrorText: true,
        ),
      );
    }
    state = state.copyWith(
      isAutoChasing: false,
      autoChaseCurrentDepth: 0,
      autoChaseMaxDepth: 0,
      autoChaseMessage: 'cancelled',
    );
    try {
      await ref.read(memoryPointerActionProvider.notifier).cancelPointerScan();
    } catch (_) {}
  }

  Future<void> loadMore() async {
    final layerIndex = state.currentLayerIndex;
    final currentLayer = state.currentLayer;
    if (currentLayer == null ||
        currentLayer.isLoadingInitial ||
        currentLayer.isLoadingMore ||
        !currentLayer.hasMore) {
      return;
    }

    _updateLayer(
      layerIndex,
      currentLayer.copyWith(isLoadingMore: true, clearErrorText: true),
    );

    try {
      final nextPage = await _loadManualPointerPage(currentLayer);
      final mergedResults = <PointerScanResult>[
        ...currentLayer.results,
        ...nextPage,
      ];
      _updateLayer(
        layerIndex,
        currentLayer.copyWith(
          results: mergedResults,
          isLoadingMore: false,
          hasMore: mergedResults.length < currentLayer.totalResultCount,
          clearErrorText: true,
        ),
      );
    } catch (error) {
      _updateLayer(
        layerIndex,
        currentLayer.copyWith(
          isLoadingMore: false,
          errorText: error.toString(),
        ),
      );
    }
  }

  Future<void> selectLayer(int index) async {
    if (index < 0 || index >= state.layers.length || index == state.currentLayerIndex) {
      return;
    }
    state = state.copyWith(currentLayerIndex: index);
  }

  Future<void> clear() async {
    _autoChaseRunToken += 1;
    state = const MemoryToolPointerState();
  }

  bool isStaticRegionType(String regionTypeKey) {
    return _staticRegionTypeKeys.contains(regionTypeKey);
  }

  Future<void> _interruptAutoChaseIfNeeded() async {
    if (!state.isAutoChasing) {
      return;
    }
    _autoChaseRunToken += 1;
    state = state.copyWith(
      isAutoChasing: false,
      autoChaseCurrentDepth: 0,
      autoChaseMaxDepth: 0,
    );
    try {
      await ref.read(memoryPointerActionProvider.notifier).cancelPointerScan();
    } catch (_) {}
  }

  Future<List<PointerScanResult>> _loadManualPointerPage(
    PointerChainLayerState currentLayer,
  ) async {
    final sessionState = await ref.read(getPointerScanSessionStateProvider.future);
    if (!_matchesSession(currentLayer.request, sessionState)) {
      throw StateError('Pointer scan session changed unexpectedly.');
    }
    return await ref.read(memoryPointerQueryRepositoryProvider).getPointerScanResults(
      offset: currentLayer.results.length,
      limit: memoryToolPointerPageSize,
    );
  }

  Future<void> _runAutoChase({
    required int runToken,
    required PointerScanRequest initialRequest,
    required int maxDepth,
  }) async {
    final builtLayers = <PointerChainLayerState>[];
    PointerScanRequest currentRequest = initialRequest;
    PointerScanResult? previousResult;

    try {
      for (var layerIndex = 0; layerIndex < maxDepth; layerIndex += 1) {
        if (!_isAutoChaseRunActive(runToken)) {
          return;
        }

        final placeholderLayer = PointerChainLayerState(
          request: currentRequest,
          autoChaseLayerIndex: layerIndex,
          sourceResult: previousResult,
          isLoadingInitial: true,
          staticOnlyMode: true,
        );
        if (builtLayers.length == layerIndex) {
          builtLayers.add(placeholderLayer);
        } else {
          builtLayers[layerIndex] = placeholderLayer;
        }
        state = state.copyWith(
          layers: List<PointerChainLayerState>.from(builtLayers),
          currentLayerIndex: layerIndex,
          isAutoChasing: true,
          autoChaseMaxDepth: maxDepth,
          autoChaseCurrentDepth: layerIndex + 1,
          clearAutoChaseMessage: true,
        );

        await ref
            .read(memoryPointerActionProvider.notifier)
            .startPointerScan(request: currentRequest);
        final taskState = await _waitForPointerTask(runToken: runToken);
        if (!_isAutoChaseRunActive(runToken)) {
          return;
        }
        if (taskState.status == SearchTaskStatus.cancelled) {
          _finishAutoChaseCancelled(layerIndex: layerIndex, builtLayers: builtLayers);
          return;
        }
        if (taskState.status == SearchTaskStatus.failed) {
          throw StateError(taskState.message.isEmpty ? 'Pointer scan failed.' : taskState.message);
        }

        final sessionState = await ref
            .read(memoryPointerQueryRepositoryProvider)
            .getPointerScanSessionState();
        if (!_matchesSession(currentRequest, sessionState)) {
          throw StateError('Pointer scan session changed unexpectedly.');
        }

        final results = await _loadAllPointerResults(
          totalResultCount: sessionState.resultCount,
        );
        final bestResult = results.isEmpty ? null : results.first;
        final stopReasonKey = _resolveAutoChaseStopReason(
          layerIndex: layerIndex,
          maxDepth: maxDepth,
          bestResult: bestResult,
        );
        final updatedLayer = placeholderLayer.copyWith(
          results: results,
          totalResultCount: sessionState.resultCount,
          isLoadingInitial: false,
          hasMore: false,
          selectedPointerAddress: bestResult?.pointerAddress,
          isAutoSelectedLayer: bestResult != null,
          isTerminalLayer: stopReasonKey == 'staticReached',
          autoStopReasonKey: stopReasonKey,
          clearErrorText: true,
        );
        builtLayers[layerIndex] = updatedLayer;

        final isFinished = stopReasonKey != null;
        state = state.copyWith(
          layers: List<PointerChainLayerState>.from(builtLayers),
          currentLayerIndex: layerIndex,
          isAutoChasing: !isFinished,
          autoChaseMaxDepth: maxDepth,
          autoChaseCurrentDepth: layerIndex + 1,
          autoChaseMessage: isFinished ? stopReasonKey : null,
          clearAutoChaseMessage: !isFinished,
        );

        if (isFinished) {
          return;
        }

        previousResult = bestResult;
        currentRequest = _buildNextRequest(
          baseRequest: initialRequest,
          targetAddress: bestResult!.pointerAddress,
        );
      }
    } catch (error) {
      if (!_isAutoChaseRunActive(runToken)) {
        return;
      }
      final targetLayerIndex = builtLayers.isEmpty ? 0 : builtLayers.length - 1;
      if (targetLayerIndex >= 0 && targetLayerIndex < builtLayers.length) {
        builtLayers[targetLayerIndex] = builtLayers[targetLayerIndex].copyWith(
          isLoadingInitial: false,
          isLoadingMore: false,
          autoStopReasonKey: 'failed',
          errorText: error.toString(),
        );
      } else {
        builtLayers.add(
          PointerChainLayerState(
            request: currentRequest,
            autoChaseLayerIndex: 0,
            isLoadingInitial: false,
            errorText: error.toString(),
            autoStopReasonKey: 'failed',
            staticOnlyMode: true,
          ),
        );
      }
      state = state.copyWith(
        layers: List<PointerChainLayerState>.from(builtLayers),
        currentLayerIndex: builtLayers.isEmpty ? -1 : builtLayers.length - 1,
        isAutoChasing: false,
        autoChaseCurrentDepth: 0,
        autoChaseMaxDepth: 0,
        autoChaseMessage: error.toString(),
      );
    }
  }

  Future<PointerScanTaskState> _waitForPointerTask({required int runToken}) async {
    while (true) {
      if (!_isAutoChaseRunActive(runToken)) {
        return PointerScanTaskState(
          status: SearchTaskStatus.cancelled,
          pid: 0,
          processedRegions: 0,
          totalRegions: 0,
          processedEntries: 0,
          totalEntries: 0,
          processedBytes: 0,
          totalBytes: 0,
          resultCount: 0,
          elapsedMilliseconds: 0,
          canCancel: false,
          message: 'Cancelled.',
        );
      }
      final taskState = await ref
          .read(memoryPointerQueryRepositoryProvider)
          .getPointerScanTaskState();
      if (taskState.status == SearchTaskStatus.running ||
          taskState.status == SearchTaskStatus.idle) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        continue;
      }
      return taskState;
    }
  }

  Future<List<PointerScanResult>> _loadAllPointerResults({
    required int totalResultCount,
  }) async {
    if (totalResultCount <= 0) {
      return const <PointerScanResult>[];
    }

    final results = <PointerScanResult>[];
    while (results.length < totalResultCount) {
      final page = await ref
          .read(memoryPointerQueryRepositoryProvider)
          .getPointerScanResults(
            offset: results.length,
            limit: memoryToolPointerPageSize,
          );
      if (page.isEmpty) {
        break;
      }
      results.addAll(page);
      if (page.length < memoryToolPointerPageSize) {
        break;
      }
    }
    return results;
  }

  String? _resolveAutoChaseStopReason({
    required int layerIndex,
    required int maxDepth,
    required PointerScanResult? bestResult,
  }) {
    if (bestResult == null) {
      return 'noMorePointers';
    }
    if (isStaticRegionType(bestResult.regionTypeKey)) {
      return 'staticReached';
    }
    if (layerIndex + 1 >= maxDepth) {
      return 'maxDepth';
    }
    return null;
  }

  void _finishAutoChaseCancelled({
    required int layerIndex,
    required List<PointerChainLayerState> builtLayers,
  }) {
    if (layerIndex >= 0 && layerIndex < builtLayers.length) {
      builtLayers[layerIndex] = builtLayers[layerIndex].copyWith(
        isLoadingInitial: false,
        isLoadingMore: false,
        autoStopReasonKey: 'cancelled',
        clearErrorText: true,
      );
    }
    state = state.copyWith(
      layers: List<PointerChainLayerState>.from(builtLayers),
      currentLayerIndex: builtLayers.isEmpty ? -1 : builtLayers.length - 1,
      isAutoChasing: false,
      autoChaseCurrentDepth: 0,
      autoChaseMaxDepth: 0,
      autoChaseMessage: 'cancelled',
    );
  }

  PointerScanRequest _buildNextRequest({
    required PointerScanRequest baseRequest,
    required int targetAddress,
  }) {
    return PointerScanRequest(
      pid: baseRequest.pid,
      targetAddress: targetAddress,
      pointerWidth: baseRequest.pointerWidth,
      maxOffset: baseRequest.maxOffset,
      alignment: baseRequest.alignment,
      rangeSectionKeys: baseRequest.rangeSectionKeys,
      scanAllReadableRegions: baseRequest.scanAllReadableRegions,
    );
  }

  Future<void> _startFreshScan({
    required PointerScanRequest request,
    required bool isAutoChasing,
  }) async {
    state = MemoryToolPointerState(
      layers: <PointerChainLayerState>[
        PointerChainLayerState(
          request: request,
          isLoadingInitial: true,
          staticOnlyMode: isAutoChasing,
        ),
      ],
      currentLayerIndex: 0,
      isAutoChasing: isAutoChasing,
    );
    try {
      await ref.read(memoryPointerActionProvider.notifier).startPointerScan(
        request: request,
      );
    } catch (error) {
      state = MemoryToolPointerState(
        layers: <PointerChainLayerState>[
          PointerChainLayerState(
            request: request,
            isLoadingInitial: false,
            errorText: error.toString(),
            autoStopReasonKey: isAutoChasing ? 'failed' : null,
            staticOnlyMode: isAutoChasing,
          ),
        ],
        currentLayerIndex: 0,
      );
    }
  }

  Future<void> _refreshLayerForSession(
    PointerScanSessionState sessionState,
  ) async {
    final layerIndex = _findLayerIndexBySession(sessionState);
    if (layerIndex < 0) {
      return;
    }

    final targetLayer = state.layers[layerIndex];
    final results = await ref
        .read(memoryPointerQueryRepositoryProvider)
        .getPointerScanResults(offset: 0, limit: memoryToolPointerPageSize);
    _updateLayer(
      layerIndex,
      targetLayer.copyWith(
        results: results,
        totalResultCount: sessionState.resultCount,
        isLoadingInitial: false,
        hasMore: results.length < sessionState.resultCount,
        clearErrorText: true,
      ),
    );
  }

  bool _isAutoChaseRunActive(int runToken) {
    return _autoChaseRunToken == runToken;
  }

  bool _matchesSession(
    PointerScanRequest request,
    PointerScanSessionState sessionState,
  ) {
    return sessionState.hasActiveSession &&
        request.pid == sessionState.pid &&
        request.targetAddress == sessionState.targetAddress &&
        request.pointerWidth == sessionState.pointerWidth &&
        request.maxOffset == sessionState.maxOffset &&
        request.alignment == sessionState.alignment;
  }

  int _findActiveScanLayerIndex() {
    for (var index = state.layers.length - 1; index >= 0; index -= 1) {
      final layer = state.layers[index];
      if (layer.autoChaseLayerIndex == null &&
          (layer.isLoadingInitial || layer.isLoadingMore)) {
        return index;
      }
    }
    return -1;
  }

  int _findLayerIndexBySession(PointerScanSessionState sessionState) {
    if (!sessionState.hasActiveSession) {
      return -1;
    }
    for (var index = state.layers.length - 1; index >= 0; index -= 1) {
      final layer = state.layers[index];
      if (layer.autoChaseLayerIndex == null &&
          _matchesSession(layer.request, sessionState)) {
        return index;
      }
    }
    return -1;
  }

  void _updateLayer(int index, PointerChainLayerState nextLayer) {
    final nextLayers = List<PointerChainLayerState>.from(state.layers);
    if (index < 0 || index >= nextLayers.length) {
      return;
    }
    nextLayers[index] = nextLayer;
    state = state.copyWith(layers: nextLayers);
  }
}
