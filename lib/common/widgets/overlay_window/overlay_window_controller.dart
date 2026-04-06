import 'dart:io';

import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OverlayWindowController extends ChangeNotifier {
  OverlayWindowController._();

  static final OverlayWindowController instance = OverlayWindowController._();

  OverlayWindowStatus _status = const OverlayWindowStatus(
    isSupported: true,
    hasPermission: false,
    isActive: false,
  );

  OverlayWindowStatus get status => _status;

  Future<OverlayWindowStatus> refresh() async {
    if (!_isSupportedPlatform) {
      _status = const OverlayWindowStatus(
        isSupported: false,
        hasPermission: false,
        isActive: false,
      );
      notifyListeners();
      return _status;
    }

    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    final isActive = await FlutterOverlayWindow.isActive();
    _status = OverlayWindowStatus(
      isSupported: true,
      hasPermission: hasPermission,
      isActive: isActive,
    );
    notifyListeners();
    return _status;
  }

  Future<bool> ensurePermission() async {
    if (!_isSupportedPlatform) {
      return false;
    }

    final current = await refresh();
    if (current.hasPermission) {
      return true;
    }

    final granted = await FlutterOverlayWindow.requestPermission() ?? false;
    await refresh();
    return granted;
  }

  Future<OverlayWindowStatus> show(
    BuildContext context, {
    required int scene,
    OverlayWindowPresentation presentation =
        const OverlayWindowPresentation(),
  }) async {
    if (!_isSupportedPlatform) {
      return refresh();
    }

    final overlayWidth = _resolveOverlayDimension(
      context,
      presentation.width ?? 320.w,
    );
    final overlayHeight = _resolveOverlayDimension(
      context,
      presentation.height ?? 220.h,
    );
    final notificationTitle =
        presentation.notificationTitle ?? context.l10n.appName;
    final notificationContent =
        presentation.notificationContent ?? context.l10n.loading;
    final granted = await ensurePermission();
    if (!granted) {
      return status;
    }

    await FlutterOverlayWindow.showOverlay(
      width: overlayWidth,
      height: overlayHeight,
      alignment: OverlayAlignment.centerRight,
      positionGravity: PositionGravity.auto,
      enableDrag: presentation.enableDrag,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      overlayTitle: notificationTitle,
      overlayContent: notificationContent,
    );
    await FlutterOverlayWindow.shareData(scene);
    return refresh();
  }

  Future<OverlayWindowStatus> hide() async {
    if (_isSupportedPlatform) {
      await FlutterOverlayWindow.closeOverlay();
    }
    return refresh();
  }

  int _resolveOverlayDimension(BuildContext context, double logicalSize) {
    if (logicalSize <= 0) {
      return logicalSize.round();
    }

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return (logicalSize * devicePixelRatio).round();
  }

  bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}

class OverlayWindowPresentation {
  const OverlayWindowPresentation({
    this.width,
    this.height,
    this.enableDrag = true,
    this.notificationTitle,
    this.notificationContent,
  });

  final double? width;
  final double? height;
  final bool enableDrag;
  final String? notificationTitle;
  final String? notificationContent;
}

class OverlayWindowStatus {
  const OverlayWindowStatus({
    required this.isSupported,
    required this.hasPermission,
    required this.isActive,
  });

  final bool isSupported;
  final bool hasPermission;
  final bool isActive;

  bool get canShow => isSupported && hasPermission;
}
