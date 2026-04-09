import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_payload.dart';

class OverlayWindowPayloadDto {
  const OverlayWindowPayloadDto({
    required this.sceneId,
    required this.displayMode,
    required this.localeLanguageCode,
    required this.localeCountryCode,
    required this.isDarkTheme,
    required this.primaryColorValue,
  });

  final int sceneId;
  final String displayMode;
  final String localeLanguageCode;
  final String localeCountryCode;
  final bool isDarkTheme;
  final int primaryColorValue;

  OverlayWindowPayload toModel() {
    return OverlayWindowPayload(
      sceneId: sceneId,
      displayMode: displayMode,
      localeLanguageCode: localeLanguageCode,
      localeCountryCode: localeCountryCode,
      isDarkTheme: isDarkTheme,
      primaryColorValue: primaryColorValue,
    );
  }

  Map<String, dynamic> toRaw() {
    return <String, dynamic>{
      'sceneId': sceneId,
      'displayMode': displayMode,
      'localeLanguageCode': localeLanguageCode,
      'localeCountryCode': localeCountryCode,
      'isDarkTheme': isDarkTheme,
      'primaryColorValue': primaryColorValue,
    };
  }

  factory OverlayWindowPayloadDto.fromModel(OverlayWindowPayload payload) {
    return OverlayWindowPayloadDto(
      sceneId: payload.sceneId,
      displayMode: payload.displayMode,
      localeLanguageCode: payload.localeLanguageCode,
      localeCountryCode: payload.localeCountryCode,
      isDarkTheme: payload.isDarkTheme,
      primaryColorValue: payload.primaryColorValue,
    );
  }

  factory OverlayWindowPayloadDto.fromRaw(dynamic raw) {
    if (raw is OverlayWindowPayload) {
      return OverlayWindowPayloadDto.fromModel(raw);
    }

    if (raw is int) {
      return OverlayWindowPayloadDto(
        sceneId: raw,
        displayMode: OverlayWindowDisplayMode.bubble,
        localeLanguageCode: 'zh',
        localeCountryCode: 'CN',
        isDarkTheme: false,
        primaryColorValue: 0xFF98D2D5,
      );
    }

    if (raw is String) {
      final parsedScene = int.tryParse(raw);
      if (parsedScene != null) {
        return OverlayWindowPayloadDto(
          sceneId: parsedScene,
          displayMode: OverlayWindowDisplayMode.bubble,
          localeLanguageCode: 'zh',
          localeCountryCode: 'CN',
          isDarkTheme: false,
          primaryColorValue: 0xFF98D2D5,
        );
      }
    }

    if (raw is Map) {
      final normalized = raw.map(
        (Object? key, Object? value) => MapEntry(key.toString(), value),
      );
      final sceneValue = normalized['sceneId'] ?? normalized['scene'];
      final parsedScene = switch (sceneValue) {
        int value => value,
        String value => int.tryParse(value),
        _ => null,
      };
      if (parsedScene != null) {
        final rawDisplayMode = normalized['displayMode']?.toString();
        final rawLanguageCode =
            normalized['localeLanguageCode']?.toString() ?? 'zh';
        final rawCountryCode =
            normalized['localeCountryCode']?.toString() ?? 'CN';
        final rawIsDarkTheme = switch (normalized['isDarkTheme']) {
          bool value => value,
          String value => value.toLowerCase() == 'true',
          int value => value != 0,
          _ => false,
        };
        final rawPrimaryColorValue = switch (normalized['primaryColorValue']) {
          int value => value,
          String value => int.tryParse(value) ?? 0xFF98D2D5,
          _ => 0xFF98D2D5,
        };
        return OverlayWindowPayloadDto(
          sceneId: parsedScene,
          displayMode: rawDisplayMode == OverlayWindowDisplayMode.panel
              ? OverlayWindowDisplayMode.panel
              : OverlayWindowDisplayMode.bubble,
          localeLanguageCode: rawLanguageCode,
          localeCountryCode: rawCountryCode,
          isDarkTheme: rawIsDarkTheme,
          primaryColorValue: rawPrimaryColorValue,
        );
      }
    }

    return const OverlayWindowPayloadDto(
      sceneId: 0,
      displayMode: OverlayWindowDisplayMode.bubble,
      localeLanguageCode: 'zh',
      localeCountryCode: 'CN',
      isDarkTheme: false,
      primaryColorValue: 0xFF98D2D5,
    );
  }
}
