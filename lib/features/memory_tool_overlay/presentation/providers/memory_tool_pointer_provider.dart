import 'dart:async';

import 'package:JsxposedX/features/memory_tool_overlay/presentation/enums/memory_search_range_preset_enum.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/enums/memory_search_range_section_enum.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/enums/memory_tool_pointer_alignment_option.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/providers/memory_pointer_action_provider.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/providers/memory_pointer_query_provider.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/providers/memory_query_provider.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/states/memory_tool_pointer_form_state.dart';
import 'package:JsxposedX/features/memory_tool_overlay/presentation/states/memory_tool_pointer_state.dart';
import 'package:JsxposedX/generated/memory_tool.g.dart'
    show
        PointerScanRequest,
        PointerScanResult,
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
  bool _autoChaseLoopActive = false;
  int _autoChaseRunToken = 0;

  @override
  MemoryToolPointerState build() {
    return const MemoryToolPointerState();
  }

  Future<void> startRootScan({required PointerScanRequest request}) async {
    await _startFreshScan(
      request: request,
      isAutoChasing: false,
      autoChaseMaxDepth: 0,
    );
  }

  Future<void> startAutoChase({
    required PointerScanRequest request,
    required int maxDepth,
  }) async {
    _autoChaseRunToken += 1;
    final runToken = _autoChaseRunToken;
    _autoChaseLoopActive = true;
    state = MemoryToolPointerState(
      layers: <PointerChainLayerState>[
        PointerChainLayerState(
          request: request,
          isLoadingInitial: true,
          staticOnlyMode: true,
        ),
      ],
      currentLayerIndex: 0,
      isAutoChasing: true,
      autoChaseMaxDepth: maxDepth,
      autoChaseCurrentDepth: 1,
    );
    unawaited(_runAutoChase(request: request, maxDepth: maxDepth, runToken: runToken));
  }

  Future<void> continueScan({
    required PointerScanResult result,
    required PointerScanRequest baseRequest,
  }) async {
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
    );
    try {
      await ref.read(memoryPointerActionProvider.notifier).startPointerScan(
        request: request,
      );
    } catch (error) {
      _updateLayer(
        nextLayers.length - 1,
        PointerChainLayerState(
          request: request,
          sourceResult: result,
          isLoadingInitial: false,
          errorText: error.toString(),
        ),
      );
    }
  }

  Future<void> handleTaskCompleted() async {
    if (_autoChaseLoopActive) {
      return;
    }
    try {
      final sessionState = await ref.read(getPointerScanSessionStateProvider.future);
      final layerIndex = await _refreshLayerForSession(sessionState);
      if (layerIndex < 0 || !state.isAutoChasing) {
        return;
      }
    } catch (error) {
      final fallbackLayerIndex = _findActiveScanLayerIndex();
      final targetLayerIndex = fallbackLayerIndex >= 0
          ? fallbackLayerIndex
          : state.currentLayerIndex;
      if (targetLayerIndex >= 0 && targetLayerIndex < state.layers.length) {
        _updateLayer(
          targetLayerIndex,
          state.layers[targetLayerIndex].copyWith(
            isLoadingInitial: false,
            isLoadingMore: false,
            autoStopReasonKey: state.isAutoChasing ? 'failed' : null,
            clearAutoStopReasonKey: !state.isAutoChasing,
            errorText: error.toString(),
          ),
        );
      }
      _stopAutoChaseState();
    }
  }

  void handleTaskStopped({
    required SearchTaskStatus status,
    required String message,
  }) {
    if (_autoChaseLoopActive) {
      return;
    }
    final layerIndex = _findActiveScanLayerIndex();
    if (layerIndex < 0) {
      _stopAutoChaseState();
      return;
    }

    final targetLayer = state.layers[layerIndex];
    final isCancelled = status == SearchTaskStatus.cancelled;
    final nextStopReason = state.isAutoChasing
        ? isCancelled
              ? 'cancelled'
              : 'failed'
        : targetLayer.autoStopReasonKey;
    _updateLayer(
      layerIndex,
      targetLayer.copyWith(
        isLoadingInitial: false,
        isLoadingMore: false,
        errorText: isCancelled ? null : message,
        autoStopReasonKey: nextStopReason,
        clearErrorText: isCancelled,
      ),
    );
    _stopAutoChaseState();
  }

  Future<void> cancelAutoChase() async {
    _autoChaseRunToken += 1;
    _autoChaseLoopActive = false;
    final currentLayerIndex = state.currentLayerIndex;
    if (currentLayerIndex >= 0 && currentLayerIndex < state.layers.length) {
      _updateLayer(
        currentLayerIndex,
        state.layers[currentLayerIndex].copyWith(
          isLoadingInitial: false,
          isLoadingMore: false,
          autoStopReasonKey: 'cancelled',
          clearErrorText: true,
        ),
      );
    }
    _stopAutoChaseState();
    await ref.read(memoryPointerActionProvider.notifier).cancelPointerScan();
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

    try {
      final sessionState = await ref.read(getPointerScanSessionStateProvider.future);
      if (!_matchesSession(currentLayer.request, sessionState)) {
        return;
      }

      _updateLayer(
        layerIndex,
        currentLayer.copyWith(isLoadingMore: true, clearErrorText: true),
      );

      final nextPage = await ref.read(
        memoryPointerQueryRepositoryProvider,
      ).getPointerScanResults(
        offset: currentLayer.results.length,
        limit: memoryToolPointerPageSize,
      );
      final mergedResults = <PointerScanResult>[
        ...currentLayer.results,
        ...nextPage,
      ];
      _updateLayer(
        layerIndex,
        currentLayer.copyWith(
          results: mergedResults,
          totalResultCount: sessionState.resultCount,
          isLoadingMore: false,
          hasMore: mergedResults.length < sessionState.resultCount,
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

    final targetLayer = state.layers[index];
    state = state.copyWith(currentLayerIndex: index);

    PointerScanSessionState? sessionState;
    try {
      sessionState = await ref.read(getPointerScanSessionStateProvider.future);
    } catch (_) {
      sessionState = null;
    }

    if (sessionState != null &&
        _matchesSession(targetLayer.request, sessionState)) {
      if (targetLayer.totalResultCount == 0 && sessionState.resultCount > 0) {
        _updateLayer(
          index,
          targetLayer.copyWith(
            totalResultCount: sessionState.resultCount,
            hasMore: targetLayer.results.length < sessionState.resultCount,
          ),
        );
      }
      return;
    }
  }

  Future<void> clear() async {
    state = const MemoryToolPointerState();
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
    required int autoChaseMaxDepth,
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
      autoChaseMaxDepth: autoChaseMaxDepth,
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

  Future<int> _refreshLayerForSession(
    PointerScanSessionState sessionState,
  ) async {
    try {
      final layerIndex = _findLayerIndexBySession(sessionState);
      if (layerIndex < 0) {
        return -1;
      }

      final targetLayer = state.layers[layerIndex];
      final results = await ref.read(
        memoryPointerQueryRepositoryProvider,
      ).getPointerScanResults(offset: 0, limit: memoryToolPointerPageSize);
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
      return layerIndex;
    } catch (error) {
      handleTaskStopped(
        status: SearchTaskStatus.failed,
        message: error.toString(),
      );
      return -1;
    }
  }

  Future<void> _runAutoChase({
    required PointerScanRequest request,
    required int maxDepth,
    required int runToken,
  }) async {
    try {
      final resolvedPath = await _resolveAutoChasePath(
        rootRequest: request,
        maxDepth: maxDepth,
        runToken: runToken,
      );
      if (!_isAutoChaseRunActive(runToken)) {
        return;
      }
      state = state.copyWith(
        layers: _buildLayersFromResolvedPath(resolvedPath),
        currentLayerIndex: resolvedPath.layers.isEmpty
            ? -1
            : resolvedPath.layers.length - 1,
        autoChaseCurrentDepth: resolvedPath.layers.length,
      );
      _stopAutoChaseState();
    } on _AutoChaseCancelledException {
      if (!_isAutoChaseRunActive(runToken)) {
        return;
      }
      final currentLayerIndex = state.currentLayerIndex;
      if (currentLayerIndex >= 0 && currentLayerIndex < state.layers.length) {
        _updateLayer(
          currentLayerIndex,
          state.layers[currentLayerIndex].copyWith(
            isLoadingInitial: false,
            isLoadingMore: false,
            autoStopReasonKey: 'cancelled',
            clearErrorText: true,
          ),
        );
      }
      _stopAutoChaseState();
    } catch (error) {
      if (!_isAutoChaseRunActive(runToken)) {
        return;
      }
      final currentLayerIndex = state.currentLayerIndex;
      if (currentLayerIndex >= 0 && currentLayerIndex < state.layers.length) {
        _updateLayer(
          currentLayerIndex,
          state.layers[currentLayerIndex].copyWith(
            isLoadingInitial: false,
            isLoadingMore: false,
            autoStopReasonKey: 'failed',
            errorText: error.toString(),
          ),
        );
      }
      _stopAutoChaseState();
    } finally {
      if (_autoChaseRunToken == runToken) {
        _autoChaseLoopActive = false;
      }
    }
  }

  Future<_ResolvedAutoChasePath> _resolveAutoChasePath({
    required PointerScanRequest rootRequest,
    required int maxDepth,
    required int runToken,
  }) async {
    final snapshotCache = <String, _PointerScanSnapshot>{};
    final rootSnapshot = await _scanSnapshot(
      request: rootRequest,
      displayDepth: 1,
      runToken: runToken,
      snapshotCache: snapshotCache,
    );
    _publishAutoChasePath(
      layers: <_PointerScanSnapshot>[rootSnapshot],
      selections: const <PointerScanResult>[],
    );
    if (!_isAutoChaseRunActive(runToken)) {
      throw const _AutoChaseCancelledException();
    }

    return await _searchAutoChaseNode(
      node: _AutoChaseSearchNode(
        layers: <_PointerScanSnapshot>[rootSnapshot],
        selections: const <PointerScanResult>[],
        visitedTargets: <int>{rootRequest.targetAddress},
      ),
      maxDepth: maxDepth,
      runToken: runToken,
      snapshotCache: snapshotCache,
    );
  }

  Future<_ResolvedAutoChasePath> _searchAutoChaseNode({
    required _AutoChaseSearchNode node,
    required int maxDepth,
    required int runToken,
    required Map<String, _PointerScanSnapshot> snapshotCache,
  }) async {
    if (!_isAutoChaseRunActive(runToken)) {
      throw const _AutoChaseCancelledException();
    }

    final currentSnapshot = node.layers.last;
    if (currentSnapshot.results.isEmpty) {
      return _ResolvedAutoChasePath(
        layers: node.layers,
        selections: node.selections,
        stopReasonKey: 'noMorePointers',
      );
    }

    final orderedResults = List<PointerScanResult>.from(currentSnapshot.results)
      ..sort(_comparePointerResults);

    _ResolvedAutoChasePath? bestFallback;

    for (final result in orderedResults) {
      if (!_isAutoChaseRunActive(runToken)) {
        throw const _AutoChaseCancelledException();
      }

      final nextSelections = <PointerScanResult>[...node.selections, result];
      if (_isStaticRegionType(result.regionTypeKey)) {
        _publishAutoChasePath(
          layers: node.layers,
          selections: nextSelections,
        );
        return _ResolvedAutoChasePath(
          layers: node.layers,
          selections: nextSelections,
          stopReasonKey: 'staticReached',
        );
      }

      if (node.layers.length >= maxDepth) {
        bestFallback = _pickBetterFallback(
          bestFallback,
          _ResolvedAutoChasePath(
            layers: node.layers,
            selections: nextSelections,
            stopReasonKey: 'maxDepth',
          ),
        );
        continue;
      }

      if (node.visitedTargets.contains(result.pointerAddress)) {
        continue;
      }

      final nextRequest = _buildNextRequest(
        baseRequest: currentSnapshot.request,
        targetAddress: result.pointerAddress,
      );
      _publishAutoChasePath(
        layers: node.layers,
        selections: nextSelections,
        pendingRequest: nextRequest,
      );
      final childSnapshot = await _scanSnapshot(
        request: nextRequest,
        displayDepth: node.layers.length + 1,
        runToken: runToken,
        snapshotCache: snapshotCache,
      );
      _publishAutoChasePath(
        layers: <_PointerScanSnapshot>[...node.layers, childSnapshot],
        selections: nextSelections,
      );

      final resolvedChildPath = await _searchAutoChaseNode(
        node: _AutoChaseSearchNode(
          layers: <_PointerScanSnapshot>[...node.layers, childSnapshot],
          selections: nextSelections,
          visitedTargets: <int>{
            ...node.visitedTargets,
            result.pointerAddress,
          },
        ),
        maxDepth: maxDepth,
        runToken: runToken,
        snapshotCache: snapshotCache,
      );

      if (resolvedChildPath.stopReasonKey == 'staticReached') {
        return resolvedChildPath;
      }

      bestFallback = _pickBetterFallback(bestFallback, resolvedChildPath);
    }

    return bestFallback ??
        _ResolvedAutoChasePath(
          layers: node.layers,
          selections: node.selections,
          stopReasonKey: 'noMorePointers',
        );
  }

  Future<_PointerScanSnapshot> _scanSnapshot({
    required PointerScanRequest request,
    required int displayDepth,
    required int runToken,
    required Map<String, _PointerScanSnapshot> snapshotCache,
  }) async {
    final cacheKey = _buildSnapshotCacheKey(request);
    final cachedSnapshot = snapshotCache[cacheKey];
    if (cachedSnapshot != null) {
      _updateAutoChaseProgressDepth(displayDepth);
      return cachedSnapshot;
    }

    if (!_isAutoChaseRunActive(runToken)) {
      throw const _AutoChaseCancelledException();
    }

    _updateAutoChaseProgressDepth(displayDepth);

    await ref.read(memoryPointerActionProvider.notifier).startPointerScan(
      request: request,
    );

    while (true) {
      if (!_isAutoChaseRunActive(runToken)) {
        throw const _AutoChaseCancelledException();
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final taskState = await ref
          .read(memoryPointerQueryRepositoryProvider)
          .getPointerScanTaskState();
      switch (taskState.status) {
        case SearchTaskStatus.running:
        case SearchTaskStatus.idle:
          continue;
        case SearchTaskStatus.completed:
          final sessionState = await ref
              .read(memoryPointerQueryRepositoryProvider)
              .getPointerScanSessionState();
          if (!_matchesSession(request, sessionState)) {
            throw StateError('Pointer scan session changed unexpectedly.');
          }
          final allResults = <PointerScanResult>[];
          for (var offset = 0; offset < sessionState.resultCount; offset += memoryToolPointerPageSize) {
            if (!_isAutoChaseRunActive(runToken)) {
              throw const _AutoChaseCancelledException();
            }
            final page = await ref
                .read(memoryPointerQueryRepositoryProvider)
                .getPointerScanResults(
                  offset: offset,
                  limit: memoryToolPointerPageSize,
                );
            allResults.addAll(page);
          }
          final snapshot = _PointerScanSnapshot(
            request: request,
            results: allResults,
            totalResultCount: sessionState.resultCount,
          );
          snapshotCache[cacheKey] = snapshot;
          return snapshot;
        case SearchTaskStatus.cancelled:
          throw const _AutoChaseCancelledException();
        case SearchTaskStatus.failed:
          throw Exception(
            taskState.message.isEmpty
                ? 'Pointer scan failed.'
                : taskState.message,
          );
      }
    }
  }

  List<PointerChainLayerState> _buildLayersFromResolvedPath(
    _ResolvedAutoChasePath path,
  ) {
    if (path.layers.isEmpty) {
      return const <PointerChainLayerState>[];
    }

    return List<PointerChainLayerState>.generate(path.layers.length, (index) {
      final layer = path.layers[index];
      final selectedResult = index < path.selections.length
          ? path.selections[index]
          : null;
      return PointerChainLayerState(
        request: layer.request,
        results: layer.results,
        totalResultCount: layer.totalResultCount,
        sourceResult: index > 0 ? path.selections[index - 1] : null,
        isLoadingInitial: false,
        isLoadingMore: false,
        hasMore: false,
        selectedPointerAddress: selectedResult?.pointerAddress,
        isAutoSelectedLayer: selectedResult != null,
        isTerminalLayer:
            path.stopReasonKey == 'staticReached' && index == path.layers.length - 1,
        autoStopReasonKey:
            index == path.layers.length - 1 ? path.stopReasonKey : null,
        staticOnlyMode: true,
      );
    });
  }

  _ResolvedAutoChasePath? _pickBetterFallback(
    _ResolvedAutoChasePath? current,
    _ResolvedAutoChasePath candidate,
  ) {
    if (current == null) {
      return candidate;
    }
    if (candidate.selections.length != current.selections.length) {
      return candidate.selections.length > current.selections.length
          ? candidate
          : current;
    }
    final selectionComparison = _compareSelectionChains(
      candidate.selections,
      current.selections,
    );
    return selectionComparison < 0 ? candidate : current;
  }

  int _compareSelectionChains(
    List<PointerScanResult> left,
    List<PointerScanResult> right,
  ) {
    final sharedLength = left.length < right.length ? left.length : right.length;
    for (var index = 0; index < sharedLength; index += 1) {
      final comparison = _comparePointerResults(left[index], right[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return left.length.compareTo(right.length);
  }

  int _comparePointerResults(
    PointerScanResult left,
    PointerScanResult right,
  ) {
    final leftPriority = _resolveRegionPriority(left.regionTypeKey);
    final rightPriority = _resolveRegionPriority(right.regionTypeKey);
    if (leftPriority != rightPriority) {
      return leftPriority.compareTo(rightPriority);
    }
    if (left.offset != right.offset) {
      return left.offset.compareTo(right.offset);
    }
    return left.pointerAddress.compareTo(right.pointerAddress);
  }

  int _resolveRegionPriority(String regionTypeKey) {
    return switch (regionTypeKey) {
      'cData' => 0,
      'cBss' => 1,
      'codeApp' => 2,
      'codeSys' => 3,
      'other' => 4,
      'cAlloc' => 5,
      'cHeap' => 6,
      'anonymous' => 7,
      'javaHeap' => 8,
      'java' => 9,
      'ashmem' => 10,
      'stack' => 11,
      'bad' => 12,
      _ => 13,
    };
  }

  String _buildSnapshotCacheKey(PointerScanRequest request) {
    return [
      request.pid,
      request.targetAddress,
      request.pointerWidth,
      request.maxOffset,
      request.alignment,
      request.scanAllReadableRegions,
      ...request.rangeSectionKeys,
    ].join('|');
  }

  bool _isAutoChaseRunActive(int runToken) {
    return _autoChaseLoopActive &&
        _autoChaseRunToken == runToken &&
        state.isAutoChasing;
  }

  bool _isStaticRegionType(String regionTypeKey) {
    return _staticRegionTypeKeys.contains(regionTypeKey);
  }

  bool isStaticRegionType(String regionTypeKey) {
    return _staticRegionTypeKeys.contains(regionTypeKey);
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
      if (layer.isLoadingInitial || layer.isLoadingMore) {
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
      if (_matchesSession(state.layers[index].request, sessionState)) {
        return index;
      }
    }
    return -1;
  }

  void _stopAutoChaseState() {
    if (!state.isAutoChasing &&
        state.autoChaseMaxDepth == 0 &&
        state.autoChaseCurrentDepth == 0) {
      return;
    }
    state = state.copyWith(
      isAutoChasing: false,
      autoChaseMaxDepth: 0,
      autoChaseCurrentDepth: 0,
    );
  }

  void _updateLayer(int index, PointerChainLayerState nextLayer) {
    final nextLayers = List<PointerChainLayerState>.from(state.layers);
    if (index < 0 || index >= nextLayers.length) {
      return;
    }
    nextLayers[index] = nextLayer;
    state = state.copyWith(layers: nextLayers);
  }

  void _updateAutoChaseProgressDepth(int depth) {
    if (!state.isAutoChasing || depth <= 0) {
      return;
    }
    if (state.autoChaseCurrentDepth == depth) {
      return;
    }
    state = state.copyWith(autoChaseCurrentDepth: depth);
  }

  void _publishAutoChasePath({
    required List<_PointerScanSnapshot> layers,
    required List<PointerScanResult> selections,
    PointerScanRequest? pendingRequest,
  }) {
    if (!state.isAutoChasing) {
      return;
    }

    final nextLayers = List<PointerChainLayerState>.generate(layers.length, (
      index,
    ) {
      final snapshot = layers[index];
      final selectedResult = index < selections.length ? selections[index] : null;
      return PointerChainLayerState(
        request: snapshot.request,
        results: snapshot.results,
        totalResultCount: snapshot.totalResultCount,
        sourceResult: index > 0 ? selections[index - 1] : null,
        isLoadingInitial: false,
        isLoadingMore: false,
        hasMore: false,
        selectedPointerAddress: selectedResult?.pointerAddress,
        isAutoSelectedLayer: selectedResult != null,
        staticOnlyMode: true,
      );
    });

    if (pendingRequest != null) {
      nextLayers.add(
        PointerChainLayerState(
          request: pendingRequest,
          sourceResult: selections.isEmpty ? null : selections.last,
          isLoadingInitial: true,
          staticOnlyMode: true,
        ),
      );
    }

    state = state.copyWith(
      layers: nextLayers,
      currentLayerIndex: nextLayers.isEmpty ? -1 : nextLayers.length - 1,
    );
  }
}

class _PointerScanSnapshot {
  const _PointerScanSnapshot({
    required this.request,
    required this.results,
    required this.totalResultCount,
  });

  final PointerScanRequest request;
  final List<PointerScanResult> results;
  final int totalResultCount;
}

class _AutoChaseSearchNode {
  const _AutoChaseSearchNode({
    required this.layers,
    required this.selections,
    required this.visitedTargets,
  });

  final List<_PointerScanSnapshot> layers;
  final List<PointerScanResult> selections;
  final Set<int> visitedTargets;
}

class _ResolvedAutoChasePath {
  const _ResolvedAutoChasePath({
    required this.layers,
    required this.selections,
    required this.stopReasonKey,
  });

  final List<_PointerScanSnapshot> layers;
  final List<PointerScanResult> selections;
  final String stopReasonKey;
}

class _AutoChaseCancelledException implements Exception {
  const _AutoChaseCancelledException();
}
