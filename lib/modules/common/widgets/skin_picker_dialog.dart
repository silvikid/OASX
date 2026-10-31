import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/app_colors.dart';
import 'package:oasx/config/app_skin.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 打开皮肤配置弹窗。
Future<void> showSkinPickerDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const SkinPickerDialog(),
  );
}

/// 皮肤配置弹窗：选皮肤 + 切明暗，选中立即生效。
///
/// 明暗开关放在这里，是因为顶栏原来那个「白天/夜间」按钮已经被皮肤按钮替换，
/// 这个能力不能丢。
class SkinPickerDialog extends StatelessWidget {
  const SkinPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    final zh = Localizations.localeOf(context).languageCode == 'zh';

    return Obx(() {
      final current = themeService.skin;
      final dark = themeService.isDarkMode;
      // 窄屏（手机 / 小窗）按可用宽度收缩，避免弹窗横向溢出。
      final width = (MediaQuery.sizeOf(context).width - 96).clamp(240.0, 420.0);
      return AlertDialog(
        clipBehavior: Clip.antiAlias,
        title: Row(
          children: [
            Expanded(child: Text(I18n.skin.tr)),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        content: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                I18n.skinHint.tr,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.5,
                  color: AppColors.text3,
                ),
              ),
              const SizedBox(height: 14),
              _ToneToggle(
                dark: dark,
                onChanged: (value) => themeService.switchTheme(value),
              ),
              const SizedBox(height: 14),
              // 皮肤多了之后列表会超过窗口高度，这里限高并允许滚动。
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (MediaQuery.sizeOf(context).height - 320).clamp(
                    160.0,
                    420.0,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final skin in AppSkins.all) ...[
                        _SkinCard(
                          skin: skin,
                          selected: skin.id == current.id,
                          dark: dark,
                          zh: zh,
                          onTap: () => themeService.switchSkin(skin),
                        ),
                        if (skin != AppSkins.all.last)
                          const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      );
    });
  }
}

/// 白天 / 夜间两档开关，用胶囊按钮而不是 Switch，和顶栏标签观感一致。
class _ToneToggle extends StatelessWidget {
  const _ToneToggle({required this.dark, required this.onChanged});

  final bool dark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(
            label: I18n.skinLight.tr,
            icon: Icons.light_mode_rounded,
            selected: !dark,
            onTap: () => onChanged(false),
          ),
          _segment(
            label: I18n.skinDark.tr,
            icon: Icons.dark_mode_rounded,
            selected: dark,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.panel : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.border : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? AppColors.teal : AppColors.text3,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.text : AppColors.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个皮肤项：左边色卡预览，右边名字与一句话说明。
class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.dark,
    required this.zh,
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final bool dark;
  final bool zh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 + AppSkins.active.radiusBump),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealDim : AppColors.card,
          borderRadius: BorderRadius.circular(10 + AppSkins.active.radiusBump),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
            width: selected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            _SkinSwatch(
              tone: skin.darkOnly
                  ? skin.dark
                  : (skin.lightOnly
                        ? skin.light
                        : skin.toneFor(
                            dark ? Brightness.dark : Brightness.light,
                          )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        skin.nameZh,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      if (skin.darkOnly || skin.lightOnly) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tealDim,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            skin.darkOnly ? '仅夜间' : '仅白天',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.teal,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    skin.hint(zh),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: AppColors.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 16,
              color: selected ? AppColors.teal : AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}

/// 色卡：用这套皮肤的实际配色画一个微缩界面，比一堆色块直观。
class _SkinSwatch extends StatelessWidget {
  const _SkinSwatch({required this.tone});

  final AppSkinTone tone;

  @override
  Widget build(BuildContext context) {
    Widget bar(Color color, double widthFactor) {
      return FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widthFactor,
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }

    return Container(
      width: 66,
      height: 42,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tone.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          bar(tone.text, 0.62),
          bar(tone.text2, 0.42),
          Row(
            children: [
              bar(tone.text3, 0.5),
              const SizedBox(width: 4),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: tone.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
