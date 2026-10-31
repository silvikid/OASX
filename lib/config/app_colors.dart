import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/app_skin.dart';

/// Single source of truth for OASX colours.
///
/// The dashboard, the dialogs and the global [ThemeData] all read from here so
/// the whole app switches between day and night with one palette.
///
/// 具体色值不写在这里：所有语义槽都转发给当前皮肤（[AppSkins.active]）的
/// 浅色 / 深色档，换皮肤等于换一份 [AppSkinTone]。成员名保持不变，
/// 调用方两百多处一行都不用改。
///
/// `xxxFor(brightness)` variants exist because [ThemeData] is built for an
/// explicit brightness, while widgets use the context-free getters.
class AppColors {
  const AppColors._();

  static Brightness get _brightness =>
      Get.isDarkMode ? Brightness.dark : Brightness.light;

  static AppSkinTone get _tone => AppSkins.active.toneFor(_brightness);

  static AppSkinTone _toneFor(Brightness b) => AppSkins.active.toneFor(b);

  // Surfaces
  static Color bgFor(Brightness b) => _toneFor(b).bg;
  static Color panelFor(Brightness b) => _toneFor(b).panel;
  static Color cardFor(Brightness b) => _toneFor(b).card;
  static Color surface2For(Brightness b) => _toneFor(b).surface2;
  static Color surface3For(Brightness b) => _toneFor(b).surface3;
  static Color selectedBgFor(Brightness b) => _toneFor(b).selectedBg;
  static Color selectedBorderFor(Brightness b) => _toneFor(b).selectedBorder;
  static Color borderFor(Brightness b) => _toneFor(b).border;
  static Color overlayFor(Brightness b) =>
      _toneFor(b).overlay ?? _toneFor(b).panel;

  // Text
  static Color textFor(Brightness b) => _toneFor(b).text;
  static Color text2For(Brightness b) => _toneFor(b).text2;
  static Color text3For(Brightness b) => _toneFor(b).text3;

  // Accents
  static Color tealFor(Brightness b) => _toneFor(b).accent;
  static Color tealDimFor(Brightness b) => _toneFor(b).accentSoft;
  static Color greenFor(Brightness b) => _toneFor(b).green;
  static Color yellowFor(Brightness b) => _toneFor(b).yellow;
  static Color redFor(Brightness b) => _toneFor(b).red;
  static Color blueFor(Brightness b) => _toneFor(b).blue;

  /// Text colour on top of a filled accent button.
  static Color onAccentFor(Brightness b) => _toneFor(b).onAccent;

  static bool get isDark => Get.isDarkMode;

  static Color get bg => _tone.bg;
  static Color get panel => _tone.panel;
  static Color get card => _tone.card;
  static Color get surface2 => _tone.surface2;
  static Color get surface3 => _tone.surface3;
  static Color get selectedBg => _tone.selectedBg;
  static Color get selectedBorder => _tone.selectedBorder;
  static Color get border => _tone.border;
  static Color get overlay => _tone.overlay ?? _tone.panel;

  static Color get text => _tone.text;
  static Color get text2 => _tone.text2;
  static Color get text3 => _tone.text3;

  static Color get teal => _tone.accent;
  static Color get tealDim => _tone.accentSoft;
  static Color get green => _tone.green;
  static Color get yellow => _tone.yellow;
  static Color get red => _tone.red;
  static Color get blue => _tone.blue;
  static Color get onAccent => _tone.onAccent;

  // 新拟物材质：光影色与偏移量，平面皮肤下不会被读到。
  static Color get shadowDark => _tone.shadowDark;
  static Color get shadowLight => _tone.shadowLight;
  static bool get isSoftMaterial => AppSkins.active.isSoft;
  static bool get isGlassMaterial => AppSkins.active.isGlass;
  static double get softDepth => AppSkins.active.softDepth;

  /// 平面皮肤下面板的"受光渐变"：上沿本色、下沿朝强调色偏 5%。
  ///
  /// 这是给密排面板加一点材质的做法——不靠背景透出来，而是面板自己有一点
  /// 从上到下的明暗过渡，整窗看起来才不是一块死色。
  /// 新拟物 / 玻璃有自己的材质，返回 null。
  static LinearGradient? sheenFor(Color base) {
    if (isSoftMaterial || isGlassMaterial) {
      return null;
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[base, Color.lerp(base, _tone.accent, 0.05)!],
    );
  }

  /// Seed used to derive Material component colours.
  static Color get seed => AppSkins.active.light.accent;
}
