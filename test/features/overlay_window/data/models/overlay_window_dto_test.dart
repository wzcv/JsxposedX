import 'dart:ui';

import 'package:JsxposedX/features/overlay_window/data/models/overlay_window_event_dto.dart';
import 'package:JsxposedX/features/overlay_window/data/models/overlay_window_payload_dto.dart';
import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_event.dart';
import 'package:JsxposedX/features/overlay_window/domain/models/overlay_window_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverlayWindowPayloadDto', () {
    test('parses payload map and serializes back', () {
      final dto = OverlayWindowPayloadDto.fromRaw(
        <String, dynamic>{
          'sceneId': 7,
          'displayMode': OverlayWindowDisplayMode.panel,
        },
      );

      expect(dto.sceneId, 7);
      expect(dto.displayMode, OverlayWindowDisplayMode.panel);
      expect(dto.toModel().sceneId, 7);
      expect(dto.toRaw(), <String, dynamic>{
        'sceneId': 7,
        'displayMode': OverlayWindowDisplayMode.panel,
        'localeLanguageCode': 'zh',
        'localeCountryCode': 'CN',
        'isDarkTheme': false,
        'primaryColorValue': 0xFF98D2D5,
      });
    });

    test('supports legacy scene field', () {
      final dto = OverlayWindowPayloadDto.fromRaw(
        <String, dynamic>{'scene': '5'},
      );

      expect(dto.sceneId, 5);
      expect(dto.displayMode, OverlayWindowDisplayMode.bubble);
    });

    test('parses theme and locale snapshot fields', () {
      final dto = OverlayWindowPayloadDto.fromRaw(
        <String, dynamic>{
          'sceneId': 3,
          'displayMode': OverlayWindowDisplayMode.bubble,
          'localeLanguageCode': 'en',
          'localeCountryCode': 'US',
          'isDarkTheme': true,
          'primaryColorValue': 0xFF123456,
        },
      );

      expect(dto.localeLanguageCode, 'en');
      expect(dto.localeCountryCode, 'US');
      expect(dto.isDarkTheme, isTrue);
      expect(dto.primaryColorValue, 0xFF123456);
      expect(dto.toModel().isDarkTheme, isTrue);
    });
  });

  group('OverlayWindowEventDto', () {
    test('parses bubble tap event', () {
      final event = OverlayWindowEventDto.maybeFromRaw(
        <String, dynamic>{'event': OverlayWindowEventType.bubbleTap},
      );

      expect(event, isNotNull);
      expect(event!.isBubbleTap, isTrue);
      expect(event.hostPosition, isNull);
    });

    test('parses drag end event with host position', () {
      final event = OverlayWindowEventDto.maybeFromRaw(
        <String, dynamic>{
          'event': OverlayWindowEventType.bubbleDragEnd,
          'x': '12.5',
          'y': 30,
        },
      );

      expect(event, isNotNull);
      expect(event!.isBubbleDragEnd, isTrue);
      expect(event.hostPosition, const Offset(12.5, 30));
    });
  });
}
