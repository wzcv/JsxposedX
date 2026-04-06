import 'package:JsxposedX/app/app_bootstrap.dart';
import 'package:JsxposedX/core/routes/app_router.dart';
import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_api.dart';
import 'package:JsxposedX/common/widgets/overlay_window/overlay_window_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ProviderScope(child: OverlayWindowScope(child: const MainApp())));
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(child: OverlayWindowScope(child: const OverlayApp())),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return AppBootstrap(
      builder: (context, locale, lightTheme, darkTheme, themeMode) {
        return MaterialApp.router(
          title: 'JsxposedX',
          locale: locale,
          localizationsDelegates: AppBootstrap.localizationsDelegates,
          supportedLocales: AppBootstrap.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return locale;
          },
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          builder: FlutterSmartDialog.init(),
        );
      },
    );
  }
}

class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBootstrap(
      builder: (context, locale, lightTheme, darkTheme, themeMode) {
        return MaterialApp(
          title: 'JsxposedX',
          locale: locale,
          localizationsDelegates: AppBootstrap.localizationsDelegates,
          supportedLocales: AppBootstrap.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return locale;
          },
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeMode,
          debugShowCheckedModeBanner: false,
          home: const OverlayWindowRenderer(),
          builder: FlutterSmartDialog.init(),
        );
      },
    );
  }
}
