import 'dart:ui';

import 'package:JsxposedX/features/overlay_window/domain/models/overlay_viewport_metrics.dart';
import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_payload.dart';

class OverlayWindowHostRuntimeState {
  const OverlayWindowHostRuntimeState({
    required this.payload,
    this.viewportMetrics,
    this.bubbleVisualOffset,
    this.isTransitioningToPanel = false,
  });

  final OverlayWindowPayload payload;
  final OverlayViewportMetrics? viewportMetrics;
  final Offset? bubbleVisualOffset;
  final bool isTransitioningToPanel;

  OverlayWindowHostRuntimeState copyWith({
    OverlayWindowPayload? payload,
    OverlayViewportMetrics? viewportMetrics,
    Offset? bubbleVisualOffset,
    bool preserveBubbleVisualOffset = true,
    bool? isTransitioningToPanel,
  }) {
    return OverlayWindowHostRuntimeState(
      payload: payload ?? this.payload,
      viewportMetrics: viewportMetrics ?? this.viewportMetrics,
      bubbleVisualOffset: preserveBubbleVisualOffset
          ? bubbleVisualOffset ?? this.bubbleVisualOffset
          : bubbleVisualOffset,
      isTransitioningToPanel:
          isTransitioningToPanel ?? this.isTransitioningToPanel,
    );
  }
}
