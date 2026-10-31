import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:oasx/config/app_colors.dart';
import 'package:oasx/config/app_skin.dart';

/// 全应用最底层的背景：一层底色 + 若干柔和光晕。
///
/// 光晕由各套皮肤在 `AppSkin.sceneLight/sceneDark` 里声明，所以：
/// - 玻璃皮肤用的是深墨夜景 + 月光/钢蓝/香槟三团光；
/// - 其它皮肤各有一两团低饱和的暖光或冷光，让背景不再是一块死色；
/// - 面板本身仍然不透明，正文可读性不受影响（光晕只在留白和边缘上看得见）。
///
/// 光晕是静止的，不参与动画，只在尺寸或皮肤变化时重绘一次。
class SkinBackdrop extends StatelessWidget {
  const SkinBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkins.active;
    final brightness = AppColors.isDark ? Brightness.dark : Brightness.light;
    final base = AppColors.bg == Colors.transparent
        ? (skin.backdropBase ?? const Color(0xFF000000))
        : AppColors.bg;
    return CustomPaint(
      painter: _ScenePainter(base: base, washes: skin.sceneFor(brightness)),
      child: child,
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.base, required this.washes});

  final Color base;
  final List<AppBackdropWash> washes;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    if (size.isEmpty || washes.isEmpty) {
      return;
    }
    final unit = size.shortestSide;
    for (final wash in washes) {
      final center = Offset(
        (wash.align.x + 1) / 2 * size.width,
        (wash.align.y + 1) / 2 * size.height,
      );
      final shader = ui.Gradient.radial(
        center,
        unit * wash.radiusFactor,
        <Color>[
          wash.color.withValues(alpha: wash.alpha),
          wash.color.withValues(alpha: 0),
        ],
        <double>[0, 1],
      );
      canvas.drawRect(rect, Paint()..shader = shader);
    }
  }

  @override
  bool shouldRepaint(_ScenePainter oldDelegate) {
    return base != oldDelegate.base || washes != oldDelegate.washes;
  }
}
