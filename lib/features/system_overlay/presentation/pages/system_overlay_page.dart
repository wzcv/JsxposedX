import 'package:JsxposedX/common/pages/toast.dart';
import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_api.dart';
import 'package:JsxposedX/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SystemOverlayPage extends ConsumerWidget {
  const SystemOverlayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isZh = context.isZh;

    return Scaffold(
      appBar: AppBar(
        title: Text(isZh ? '系统悬浮窗' : 'System overlay'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FilledButton(
              onPressed: () => _showOverlay(context),
              child: Text(isZh ? '显示悬浮窗' : 'Show overlay'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _closeOverlay(context),
              child: Text(isZh ? '关闭悬浮窗' : 'Close overlay'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showOverlay(BuildContext context) async {
    final grantOverlayPermissionText = context.isZh
        ? '请先完成悬浮窗授权'
        : 'Grant overlay permission first';
    final status = await OverlayWindow.show(context);
    if (!context.mounted) {
      return;
    }

    if (!status.canShow) {
      ToastMessage.show(grantOverlayPermissionText);
    }
  }

  Future<void> _closeOverlay(BuildContext context) async {
    await OverlayWindow.dismiss(context);
  }
}
