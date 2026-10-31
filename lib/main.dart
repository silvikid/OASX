import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/config/app_colors.dart';
import 'package:oasx/config/app_skin.dart';
import 'package:oasx/config/theme.dart' show darkTheme, lightTheme, themeFor;
import 'package:oasx/modules/common/widgets/skin_backdrop.dart';
import 'package:oasx/modules/settings/controllers/settings_controller.dart';
import 'package:oasx/service/app_exit_service.dart';
import 'package:oasx/service/autostart_service.dart';
import 'package:oasx/service/app_update_service.dart';
import 'package:oasx/service/locale_service.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/system_tray_service.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/service/window_service.dart';
import 'package:oasx/translation/i18n.dart';
import 'package:oasx/utils/logger.dart';
import 'package:oasx/utils/platform_utils.dart';
import 'package:oasx/routes.dart';
import 'package:responsive_builder/responsive_builder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initService();

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && PlatformUtils.isWindows,
      builder: (context) => const OASXApp(),
    ),
  );
}

class OASXApp extends StatelessWidget {
  const OASXApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = Get.find<LocaleService>();

    return ResponsiveApp(
      builder: (context) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          scrollBehavior: GlobalBehavior(),
          translations: Messages(),
          locale: localeService.currentLocale,
          fallbackLocale: localeService.fallbackLocale,
          title: 'OASX',
          initialRoute: Routes.initial,
          getPages: Routes.routes,
          theme: lightTheme,
          darkTheme: darkTheme,
          // 界面里大量取色是 AppColors / Get.isDarkMode 这类静态值，切换时瞬间生效；
          // 而 MaterialApp 内部对 ThemeData 做 200ms 补间，两者不同步就会出现
          // 「先白后黑」的闪一下。这里在 builder 里显式给一份"最终"主题，
          // 让所有 Theme.of 的读取也立刻拿到新值，整屏一次性翻转。
          //
          // 包一层 Obx 是为了换皮肤：皮肤的色值不在 MaterialApp 的 theme 里，
          // 换皮肤只改静态取值器的来源，需要这里主动重建才能整屏刷新。
          builder: (context, child) {
            final themeService = Get.isRegistered<ThemeService>()
                ? Get.find<ThemeService>()
                : null;
            return DevicePreview.appBuilder(
              context,
              Obx(() {
                final resolved = themeFor(
                  (themeService?.isDarkMode ?? false)
                      ? Brightness.dark
                      : Brightness.light,
                );
                // 玻璃皮肤的页面底色是透明的（要让背后的光斑透上来），
                // 这里换成它真正的不透明底色，避免淡入层闪白。
                // 页面底色现在统一由 SkinBackdrop 画，Scaffold 是透明的，
                // 所以淡入层要自己取一个不透明底色。
                final background = AppColors.bg == Colors.transparent
                    ? (AppSkins.active.backdropBase ??
                          const Color(0xFF000000))
                    : AppColors.bg;
                return SkinBackdrop(
                  child: _ThemeFadeOverlay(
                    brightness: resolved.brightness,
                    background: background,
                    child: Theme(
                      data: resolved,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}

/// 主题切换时的柔和过渡：整屏先铺一层新主题的底色，再用 160ms 淡出，
/// 让"瞬间翻转"看起来像一次柔和的淡入。
///
/// 为什么不直接对页面做 cross-fade：新旧两帧都会用同一份新主题重建，
/// 交叉淡入淡出时看到的仍是新配色，白边反而会在两帧叠加时透出来。
class _ThemeFadeOverlay extends StatefulWidget {
  const _ThemeFadeOverlay({
    required this.brightness,
    required this.background,
    required this.child,
  });

  final Brightness brightness;
  final Color background;
  final Widget child;

  @override
  State<_ThemeFadeOverlay> createState() => _ThemeFadeOverlayState();
}

class _ThemeFadeOverlayState extends State<_ThemeFadeOverlay> {
  int _fadeToken = 0;

  @override
  void didUpdateWidget(covariant _ThemeFadeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.brightness != widget.brightness) {
      _fadeToken++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_fadeToken > 0)
          IgnorePointer(
            child: _FadeAway(
              key: ValueKey<int>(_fadeToken),
              color: widget.background,
            ),
          ),
      ],
    );
  }
}

class _FadeAway extends StatelessWidget {
  const _FadeAway({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      builder: (context, value, _) => ColoredBox(
        color: color.withValues(alpha: value),
      ),
    );
  }
}

class GlobalBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

Future<void> initService() async {
  await GetStorage.init();

  Get.put(SettingsController(), permanent: true);
  Get.put(AppExitService(), permanent: true);
  if (PlatformUtils.isDesktop) {
    Get.put(SystemTrayService(), permanent: true);
  }
  Get.lazyPut<WebSocketService>(() => WebSocketService(), fenix: true);
  final windowService = Get.put(WindowService());

  await Future.wait([
    initLogger(),
    Get.putAsync(() async => LocaleService()),
    Get.putAsync(() async => ThemeService()),
    Get.putAsync(() async => AutoStartService(), permanent: true),
    Get.putAsync(() async => AppUpdateService(), permanent: true),
    windowService.ready,
    Get.putAsync(() async => ScriptService(), permanent: true),
  ]);
}
