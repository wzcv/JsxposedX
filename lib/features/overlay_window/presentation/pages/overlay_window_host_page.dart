import 'dart:async';

import 'package:JsxposedX/common/widgets/overlay_window/overlay_bubble.dart';
import 'package:JsxposedX/common/widgets/overlay_window/overlay_window.dart';
import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_payload.dart';
import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_presentation.dart';
import 'package:JsxposedX/features/overlay_window/presentation/models/overlay_scene_definition.dart';
import 'package:JsxposedX/features/overlay_window/presentation/providers/overlay_scene_registry_provider.dart';
import 'package:JsxposedX/features/overlay_window/presentation/providers/overlay_window_host_runtime_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OverlayWindowHostPage extends ConsumerStatefulWidget {
  const OverlayWindowHostPage({super.key});

  @override
  ConsumerState<OverlayWindowHostPage> createState() =>
      _OverlayWindowHostPageState();
}

class _OverlayWindowHostPageState extends ConsumerState<OverlayWindowHostPage>
    with WidgetsBindingObserver {
  static const double _panelMaxWidth = 560;
  static const double _panelMaxHeight = 720;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    unawaited(
      ref.read(overlayWindowHostRuntimeProvider.notifier).onMetricsChanged(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runtimeState = ref.watch(overlayWindowHostRuntimeProvider);
    final payload = runtimeState.payload;

    return Material(
      color: Colors.transparent,
      child: runtimeState.isTransitioningToPanel
          ? const SizedBox.expand()
          : payload.isPanel
          ? _buildPanelWindow(context, payload.sceneId)
          : _buildBubble(payload.sceneId),
    );
  }

  OverlaySceneDefinition? _scene(int sceneId) {
    return ref.read(overlaySceneRegistryProvider)[sceneId];
  }

  Widget _buildPanelWindow(BuildContext context, int sceneId) {
    final scene = _scene(sceneId);
    final controller = ref.read(overlayWindowHostRuntimeProvider.notifier);
    final title =
        scene?.title(context) ?? context.l10n.overlayWindowFallbackTitle;
    final subtitle =
        scene?.subtitle?.call(context) ??
        context.l10n.overlayFloatingToolWindow;

    return OverlayWindow(
      title: title,
      subtitle: subtitle,
      onBackdropTap: () =>
          controller.setDisplayMode(OverlayWindowDisplayMode.bubble),
      onMinimize: () =>
          controller.setDisplayMode(OverlayWindowDisplayMode.bubble),
      onClose: () {
        unawaited(controller.closeOverlay());
      },
      maxWidth: _panelMaxWidth,
      maxHeight: _panelMaxHeight,
      child: scene?.panelBuilder(context) ?? _buildUnknownScene(context),
    );
  }

  Widget _buildBubble(int sceneId) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: OverlayBubble(size: _bubbleSizeForScene(sceneId)),
      ),
    );
  }

  Widget _buildUnknownScene(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.overlayWindowUnknownSceneTitle,
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          context.l10n.overlayWindowUnknownSceneDescription,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        SizedBox(height: 16.h),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {
              unawaited(
                ref
                    .read(overlayWindowHostRuntimeProvider.notifier)
                    .closeOverlay(),
              );
            },
            child: Text(context.l10n.close),
          ),
        ),
      ],
    );
  }

  double _bubbleSizeForScene(int sceneId) {
    return _scene(sceneId)?.bubbleSize ??
        OverlayWindowPresentation.defaultBubbleSize;
  }
}
