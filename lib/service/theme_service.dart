import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:oasx/config/app_skin.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/service/system_tray_service.dart';

class ThemeService extends GetxService {
  final _storage = GetStorage();
  final _dark = false.obs;
  final _skin = AppSkins.classic.obs;
  final _color = ColorSeed.baseColor.color.obs;

  bool get isDarkMode => _dark.value;
  Color get color => _color.value;

  /// 当前皮肤。`Obx` 里读它可以在换皮肤时刷新。
  AppSkin get skin => _skin.value;

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    _dark.value = _storage.read(StorageKey.dark.name) ?? false;
    _skin.value = AppSkins.byId(_storage.read(StorageKey.skin.name));
    // 界面里大量取色走 AppColors 静态取值器，必须先落位再建树。
    AppSkins.active = _skin.value;
    switchTheme(_dark.value);
    super.onInit();
  }

  void switchTheme([bool? dark]) {
    final next = dark ?? !_dark.value;
    // 只在夜间成立的皮肤（玻璃）切到白天时，先退回默认皮肤，
    // 否则浅底上会只剩半透明白块，什么都看不清。
    if (!next && _skin.value.darkOnly) {
      switchSkin(AppSkins.classic);
    }
    // 只在白天成立的皮肤（日系清新）同理，切夜间时退回默认。
    if (next && _skin.value.lightOnly) {
      switchSkin(AppSkins.classic);
    }
    _dark.value = next;
    _storage.write(StorageKey.dark.name, _dark.value);
    Get.changeThemeMode(themeMode);
    if (Get.isRegistered<SystemTrayService>()) {
      Get.find<SystemTrayService>().syncTrayTheme(_dark.value);
    }
  }

  /// 换皮肤：落盘 + 让整棵树按新配色重建。
  ///
  /// 用 [Get.changeThemeMode] 而不是单纯改 Rx，是因为 `AppColors` 是静态取值，
  /// 只有整树重建才能让所有缓存过颜色的 State 重新读到新值。
  void switchSkin(AppSkin next) {
    if (next.id == _skin.value.id) {
      return;
    }
    _skin.value = next;
    AppSkins.active = next;
    // 锁深色 / 锁浅色的皮肤强制切到它成立的那一档。
    if (next.darkOnly && !_dark.value) {
      _dark.value = true;
      _storage.write(StorageKey.dark.name, true);
    }
    if (next.lightOnly && _dark.value) {
      _dark.value = false;
      _storage.write(StorageKey.dark.name, false);
    }
    _storage.write(StorageKey.skin.name, next.id);
    Get.changeThemeMode(themeMode);
    if (Get.isRegistered<SystemTrayService>()) {
      Get.find<SystemTrayService>().syncTrayTheme(_dark.value);
    }
  }
}
