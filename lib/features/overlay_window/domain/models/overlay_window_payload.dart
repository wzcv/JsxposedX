class OverlayWindowDisplayMode {
  static const String bubble = 'bubble';
  static const String panel = 'panel';
}

class OverlayWindowPayload {
  const OverlayWindowPayload({
    required this.sceneId,
    this.displayMode = OverlayWindowDisplayMode.bubble,
    this.localeLanguageCode = 'zh',
    this.localeCountryCode = 'CN',
    this.isDarkTheme = false,
    this.primaryColorValue = 0xFF98D2D5,
  });

  final int sceneId;
  final String displayMode;
  final String localeLanguageCode;
  final String localeCountryCode;
  final bool isDarkTheme;
  final int primaryColorValue;

  bool get isBubble => displayMode == OverlayWindowDisplayMode.bubble;
  bool get isPanel => displayMode == OverlayWindowDisplayMode.panel;

  OverlayWindowPayload copyWith({
    int? sceneId,
    String? displayMode,
    String? localeLanguageCode,
    String? localeCountryCode,
    bool? isDarkTheme,
    int? primaryColorValue,
  }) {
    return OverlayWindowPayload(
      sceneId: sceneId ?? this.sceneId,
      displayMode: displayMode ?? this.displayMode,
      localeLanguageCode: localeLanguageCode ?? this.localeLanguageCode,
      localeCountryCode: localeCountryCode ?? this.localeCountryCode,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
    );
  }
}
