import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_payload.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final overlayAppPayloadProvider =
    NotifierProvider<OverlayAppPayloadNotifier, OverlayWindowPayload>(
      OverlayAppPayloadNotifier.new,
    );

class OverlayAppPayloadNotifier extends Notifier<OverlayWindowPayload> {
  @override
  OverlayWindowPayload build() {
    return const OverlayWindowPayload(sceneId: 0);
  }

  void setPayload(OverlayWindowPayload payload) {
    state = payload;
  }
}
