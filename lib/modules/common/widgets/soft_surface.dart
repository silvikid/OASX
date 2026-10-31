import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:oasx/config/app_colors.dart';

/// 一块"有材质"的表面。
///
/// - 平面皮肤（默认 / 吉卜力 / 纸墨）：等价于原来的「圆角 + 底色 + 1px 描边」，
///   换皮肤时不会带来任何像素级变化；
/// - 新拟物皮肤：不画描边，改用双光源光影——左上高光、右下暗影。
///   光源方向固定锁死，凸起（[inset] = false）与凹陷（[inset] = true）只换绘制方式，
///   不换方向，符合新拟物的物理约定。
class SoftSurface extends StatelessWidget {
  const SoftSurface({
    super.key,
    required this.child,
    this.radius = 14,
    this.color,
    this.inset = false,
    this.depth,
    this.border,
    this.gradient,
  });

  final Widget child;
  final double radius;

  /// 表面底色，默认取面板色。
  final Color? color;

  /// true 表示"嵌进背景里"（输入框、按下的按钮）。
  final bool inset;

  /// 光影偏移量。放在面板内部的块用浅一档（`AppColors.softDepth * 0.6`），
  /// 否则面板阴影 + 卡片阴影叠在一起会糊成一片。
  final double? depth;

  /// 描边。只对平面皮肤生效——新拟物靠光影分层，画描边会破坏材质感。
  final BorderSide? border;

  /// 平面皮肤下的填充渐变（受光质感）。给了它就不再使用纯色 [color]。
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final surface = color ?? AppColors.panel;
    if (!AppColors.isSoftMaterial) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? surface : null,
          borderRadius: BorderRadius.circular(radius),
          border: Border.fromBorderSide(
            border ?? BorderSide(color: AppColors.border),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    }
    if (AppColors.isGlassMaterial) {
      return CustomPaint(
        painter: _GlassPainter(
          radius: radius,
          depth: AppColors.softDepth,
          surface: surface,
          border: AppColors.border,
          highlight: AppColors.shadowLight,
          shade: AppColors.shadowDark,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: child,
        ),
      );
    }
    return CustomPaint(
      painter: _SoftShadowPainter(
        radius: radius,
        depth: depth ?? AppColors.softDepth,
        inset: inset,
        surface: surface,
        dark: AppColors.shadowDark,
        light: AppColors.shadowLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

/// 双光源阴影绘制。
///
/// Flutter 没有 CSS 的 `inset` 阴影，这里用两条路径实现：
/// - 凸起：先画两份带高斯模糊的圆角矩形（一份右下偏移、一份左上偏移），再把本体填在最上面；
/// - 凹陷：裁剪到圆角矩形内，画一圈"外框减本体"的环形阴影，看起来就像从左上方被压进去。
class _SoftShadowPainter extends CustomPainter {
  const _SoftShadowPainter({
    required this.radius,
    required this.depth,
    required this.inset,
    required this.surface,
    required this.dark,
    required this.light,
  });

  final double radius;
  final double depth;
  final bool inset;
  final Color surface;
  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final sigma = depth * 1.1;

    if (inset) {
      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRRect(rrect, Paint()..color = surface);
      final outer = Path()..addRRect(rrect.inflate(sigma * 3));
      final inner = Path()..addRRect(rrect);
      final ring = Path.combine(PathOperation.difference, outer, inner);
      canvas.drawPath(
        ring.shift(Offset(depth, depth)),
        Paint()
          ..color = dark
          ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, sigma),
      );
      canvas.drawPath(
        ring.shift(Offset(-depth, -depth)),
        Paint()
          ..color = light
          ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, sigma),
      );
      canvas.restore();
      return;
    }

    canvas.drawRRect(
      rrect.shift(Offset(depth, depth)),
      Paint()
        ..color = dark
        ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, sigma),
    );
    canvas.drawRRect(
      rrect.shift(Offset(-depth, -depth)),
      Paint()
        ..color = light
        ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, sigma),
    );
    canvas.drawRRect(rrect, Paint()..color = surface);
  }

  @override
  bool shouldRepaint(_SoftShadowPainter oldDelegate) {
    return radius != oldDelegate.radius ||
        depth != oldDelegate.depth ||
        inset != oldDelegate.inset ||
        surface != oldDelegate.surface ||
        dark != oldDelegate.dark ||
        light != oldDelegate.light;
  }
}

/// 玻璃拟态的绘制：外层深阴影 + 半透明表面 + 顶边高光 + 底边暗缘 + 白色细边。
///
/// 和 CSS 的 `backdrop-filter` 不同，这里不做高斯模糊——模糊要把背后整层重绘一遍，
/// 面板一多就掉帧；而玻璃的"真实感"主要来自有方向的光，不是模糊本身。
class _GlassPainter extends CustomPainter {
  const _GlassPainter({
    required this.radius,
    required this.depth,
    required this.surface,
    required this.border,
    required this.highlight,
    required this.shade,
  });

  final double radius;
  final double depth;
  final Color surface;
  final Color border;
  final Color highlight;
  final Color shade;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1) 外层投影：光从上往下打，所以向下偏移。
    canvas.drawRRect(
      rrect.shift(Offset(0, depth * 1.2)),
      Paint()
        ..color = shade
        ..maskFilter = MaskFilter.blur(ui.BlurStyle.normal, depth * 1.6),
    );

    // 2) 半透明表面：颜色来自背后的场景光斑。
    canvas.drawRRect(rrect, Paint()..color = surface);

    // 3) 顶边受光 / 底边背光：这两条是"玻璃"与"半透明色块"的分界线。
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1.2),
      Paint()..color = highlight,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 1.2, size.width, 1.2),
      Paint()..color = shade,
    );
    canvas.restore();

    // 4) 白色细边。
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter oldDelegate) {
    return radius != oldDelegate.radius ||
        depth != oldDelegate.depth ||
        surface != oldDelegate.surface ||
        border != oldDelegate.border ||
        highlight != oldDelegate.highlight ||
        shade != oldDelegate.shade;
  }
}
