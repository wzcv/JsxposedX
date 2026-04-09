class OverlaySceneEnum {
  static const int memoryTool = 0;
}

class OverlayWindowDisplayMode {
  static const String bubble = 'bubble';
  static const String panel = 'panel';
}

class OverlayWindowPayload {
  const OverlayWindowPayload({
    required this.scene,
    this.displayMode = OverlayWindowDisplayMode.bubble,
  });

  final int scene;
  final String displayMode;

  bool get isBubble => displayMode == OverlayWindowDisplayMode.bubble;
  bool get isPanel => displayMode == OverlayWindowDisplayMode.panel;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'scene': scene, 'displayMode': displayMode};
  }

  OverlayWindowPayload copyWith({int? scene, String? displayMode}) {
    return OverlayWindowPayload(
      scene: scene ?? this.scene,
      displayMode: displayMode ?? this.displayMode,
    );
  }

  factory OverlayWindowPayload.fromRaw(dynamic raw) {
    if (raw is OverlayWindowPayload) {
      return raw;
    }

    if (raw is int) {
      return OverlayWindowPayload(
        scene: raw,
        displayMode: OverlayWindowDisplayMode.bubble,
      );
    }

    if (raw is String) {
      final parsedScene = int.tryParse(raw);
      if (parsedScene != null) {
        return OverlayWindowPayload(
          scene: parsedScene,
          displayMode: OverlayWindowDisplayMode.bubble,
        );
      }
    }

    if (raw is Map) {
      final normalized = raw.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final sceneValue = normalized['scene'];
      final parsedScene = switch (sceneValue) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      };
      if (parsedScene != null) {
        final rawDisplayMode = normalized['displayMode']?.toString();
        return OverlayWindowPayload(
          scene: parsedScene,
          displayMode: rawDisplayMode == OverlayWindowDisplayMode.panel
              ? OverlayWindowDisplayMode.panel
              : OverlayWindowDisplayMode.bubble,
        );
      }
    }

    return const OverlayWindowPayload(
      scene: OverlaySceneEnum.memoryTool,
      displayMode: OverlayWindowDisplayMode.bubble,
    );
  }
}

class OverlayWindowEventType {
  static const String bubbleTap = 'bubbleTap';
  static const String bubbleDragEnd = 'bubbleDragEnd';
}

class OverlayWindowEvent {
  const OverlayWindowEvent._({required this.type, this.hostPosition});

  final String type;
  final OverlayHostPosition? hostPosition;

  bool get isBubbleTap => type == OverlayWindowEventType.bubbleTap;
  bool get isBubbleDragEnd => type == OverlayWindowEventType.bubbleDragEnd;

  static OverlayWindowEvent? maybeFromRaw(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final normalized = raw.map((key, value) => MapEntry(key.toString(), value));
    final eventType = normalized['event']?.toString();
    if (eventType == null) {
      return null;
    }

    switch (eventType) {
      case OverlayWindowEventType.bubbleTap:
        return const OverlayWindowEvent._(
          type: OverlayWindowEventType.bubbleTap,
        );
      case OverlayWindowEventType.bubbleDragEnd:
        final x = _parseDouble(normalized['x']);
        final y = _parseDouble(normalized['y']);
        if (x == null || y == null) {
          return null;
        }
        return OverlayWindowEvent._(
          type: OverlayWindowEventType.bubbleDragEnd,
          hostPosition: OverlayHostPosition(x: x, y: y),
        );
      default:
        return null;
    }
  }

  static double? _parseDouble(Object? value) {
    return switch (value) {
      int number => number.toDouble(),
      double number => number,
      String text => double.tryParse(text),
      _ => null,
    };
  }
}

class OverlayHostPosition {
  const OverlayHostPosition({required this.x, required this.y});

  final double x;
  final double y;
}
