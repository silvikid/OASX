import 'package:flutter/material.dart';

/// 皮肤的材质类型。
///
/// - [flat]：平面 + 描边，靠色阶分层（默认、吉卜力、纸墨都是这种）
/// - [soft]：新拟物，靠"左上高光 + 右下暗影"的双光源造出凸起/凹陷，
///   面板与按钮不再画描边，由 `SoftSurface` 负责绘制光影
enum AppSkinMaterial {
  /// 平面 + 描边，靠色阶分层。
  flat,

  /// 新拟物：左上高光 + 右下暗影的双光源，面板不画描边。
  soft,

  /// 玻璃拟态：半透明白表面 + 白色细边 + 顶边高光 + 底边暗缘（不做高斯模糊）。
  glass,
}

/// 一套皮肤在某个明暗档下的全部语义色。
///
/// 只放"语义槽"，不放具体用途的色值（比如不叫 `chipBg`），这样换皮肤时
/// 只需要保证这 18 个槽位的深浅关系，不用关心哪个控件用了它。
class AppSkinTone {
  const AppSkinTone({
    required this.bg,
    required this.panel,
    required this.card,
    required this.surface2,
    required this.surface3,
    required this.selectedBg,
    required this.selectedBorder,
    required this.border,
    required this.text,
    required this.text2,
    required this.text3,
    required this.accent,
    required this.accentSoft,
    required this.green,
    required this.yellow,
    required this.red,
    required this.blue,
    required this.onAccent,
    this.shadowDark = Colors.transparent,
    this.shadowLight = Colors.transparent,
    this.overlay,
  });

  /// 页面底色。
  final Color bg;

  /// 面板（列、弹窗）底色。
  final Color panel;

  /// 卡片底色，一般比 [panel] 再深/浅一档。
  final Color card;

  /// 次级填充（输入框、悬浮块）。
  final Color surface2;

  /// 三级填充（更弱的块）。
  final Color surface3;

  /// 选中项底色与描边。
  final Color selectedBg;
  final Color selectedBorder;

  /// 分隔线与描边。
  final Color border;

  /// 文字三档：主 / 次 / 弱。
  final Color text;
  final Color text2;
  final Color text3;

  /// 主强调色与它的浅底。
  final Color accent;
  final Color accentSoft;

  /// 状态色。
  final Color green;
  final Color yellow;
  final Color red;
  final Color blue;

  /// 压在 [accent] 实心按钮上的文字色。
  final Color onAccent;

  /// 新拟物专用：光源在左上，[shadowLight] 画在 -X/-Y，[shadowDark] 画在 +X/+Y。
  /// 平面皮肤这两项是透明色，不会被用到。
  final Color shadowDark;
  final Color shadowLight;

  /// 弹窗、菜单这类"必须压住背后内容"的表面。
  ///
  /// 玻璃皮肤的 [panel] 只有 10% 不透明度，直接拿来做弹窗底会透出背后的文字，
  /// 看起来发糊；这里给一个接近不透明的深色，保住可读性。
  /// 为空时退回 [panel]（其它皮肤行为不变）。
  final Color? overlay;
}

/// 背景上的一团柔和光晕（类似 CSS 的 radial-gradient 光斑）。
///
/// [align] 用 -1..1 表示相对位置，[radiusFactor] 是最短边的倍数——
/// 这样窗口变大时光斑同步放大，不会变成一个小圆点。
class AppBackdropWash {
  const AppBackdropWash({
    required this.align,
    required this.radiusFactor,
    required this.color,
    required this.alpha,
  });

  final Alignment align;
  final double radiusFactor;
  final Color color;
  final double alpha;
}

/// 一套皮肤 = 浅色 + 深色两档配色，外加少量形状参数。
///
/// 形状参数先只影响 [ThemeData] 里的圆角，组件内的字面量在后续版本收成 token。
class AppSkin {
  const AppSkin({
    required this.id,
    required this.nameZh,
    required this.nameEn,
    required this.hintZh,
    required this.hintEn,
    required this.light,
    required this.dark,
    this.radiusBump = 0,
    this.material = AppSkinMaterial.flat,
    this.softDepth = 6,
    this.darkOnly = false,
    this.lightOnly = false,
    this.backdropBase,
    this.sceneLight = const <AppBackdropWash>[],
    this.sceneDark = const <AppBackdropWash>[],
  });

  /// 持久化用的稳定标识，改名不影响已存配置。
  final String id;

  final String nameZh;
  final String nameEn;
  final String hintZh;
  final String hintEn;

  final AppSkinTone light;
  final AppSkinTone dark;

  /// 圆角加量：吉卜力这类柔和皮肤给 2，默认皮肤给 0。
  final double radiusBump;

  /// 材质类型，决定面板 / 按钮是"平面 + 描边"还是"双光源光影"。
  final AppSkinMaterial material;

  /// 新拟物的光影偏移量（像素）。越大越厚重，深色皮肤用得上更小的一档。
  final double softDepth;

  bool get isSoft => material == AppSkinMaterial.soft;

  bool get isGlass => material == AppSkinMaterial.glass;

  /// 背景光晕。空表示纯色底。放在背景层由 `SkinBackdrop` 绘制，
  /// 面板本身仍然是不透明的，所以不影响正文可读性。
  final List<AppBackdropWash> sceneLight;
  final List<AppBackdropWash> sceneDark;

  List<AppBackdropWash> sceneFor(Brightness brightness) =>
      brightness == Brightness.dark ? sceneDark : sceneLight;

  /// 只在深色下成立的皮肤（例如玻璃：浅底上没有可折射的场景光）。
  /// 选中后会强制切到夜间，切白天时自动退回 [AppSkins.classic]。
  final bool darkOnly;

  /// 只在浅色下成立的皮肤（例如日系清新：它的规范明确禁止深色背景）。
  /// 与 [darkOnly] 互为镜像。
  final bool lightOnly;

  /// 页面底色不透明时的实际填充色。
  ///
  /// 玻璃皮肤的 `bg` 是透明的（要让背后的光斑透上来），所以背景由
  /// `SkinBackdrop` 画，这里给它一个真正的不透明底色。
  final Color? backdropBase;

  AppSkinTone toneFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// 弹窗里色卡用的预览色（取浅色档，深色档靠明暗开关单独看）。
  Color get previewBg => light.bg;
  Color get previewPanel => light.panel;
  Color get previewCard => light.card;
  Color get previewAccent => light.accent;

  String name(bool zh) => zh ? nameZh : nameEn;
  String hint(bool zh) => zh ? hintZh : hintEn;
}

/// 玻璃皮肤唯一的一套色板（浅色档与深色档相同，因为这套皮肤只在夜间成立）。
///
/// 表面色全是"白色低透明度"，真正的颜色来自 `SkinBackdrop` 画的光斑；
/// `bg` 故意是透明的，页面背景由 backdrop 负责。
const AppSkinTone _glassTone = AppSkinTone(
  bg: Color(0x00000000),
  panel: Color(0x1AFFFFFF),
  card: Color(0x12FFFFFF),
  surface2: Color(0x1FFFFFFF),
  surface3: Color(0x0FFFFFFF),
  selectedBg: Color(0x26E4B863),
  selectedBorder: Color(0x66E4B863),
  border: Color(0x26FFFFFF),
  text: Color(0xFFF2F6FC),
  text2: Color(0xFFC3CEDE),
  text3: Color(0xFFAEBCCE),
  accent: Color(0xFFE4B863),
  accentSoft: Color(0x26E4B863),
  green: Color(0xFF8FC7AE),
  yellow: Color(0xFFE3C27E),
  red: Color(0xFFE09A90),
  blue: Color(0xFFA6BEDC),
  onAccent: Color(0xFF1A1408),
  shadowDark: Color(0x73020610),
  shadowLight: Color(0x38FFFFFF),
  overlay: Color(0xFA0E1626),
);

/// 日系清新唯一的一套色板（浅色档与深色档相同，因为这套皮肤只在白天成立）。
const AppSkinTone _japaneseTone = AppSkinTone(
  bg: Color(0xFFFAFAF8),
  panel: Color(0xFFFFFFFF),
  card: Color(0xFFFDFDFC),
  surface2: Color(0xFFF2F4F3),
  surface3: Color(0xFFF7F8F7),
  selectedBg: Color(0xFFEDF7F4),
  selectedBorder: Color(0xFFC6E3DC),
  border: Color(0xFFE4E7E5),
  text: Color(0xFF414B5A),
  text2: Color(0xFF566270),
  text3: Color(0xFF62707F),
  accent: Color(0xFF2C6B92),
  accentSoft: Color(0xFFE3F1FB),
  green: Color(0xFF327260),
  yellow: Color(0xFF865F12),
  red: Color(0xFFA04558),
  blue: Color(0xFF2C6B92),
  onAccent: Color(0xFFFFFFFF),
);

/// 皮肤注册表。加皮肤只需要在 [all] 里加一项，设置入口与弹窗自动跟着变。
class AppSkins {
  const AppSkins._();

  /// 默认皮肤：数值与 0.3.25 完全一致，保证不选皮肤时界面一个像素都不变。
  static const AppSkin classic = AppSkin(
    id: 'classic',
    nameZh: '极简',
    nameEn: 'Minimal',
    hintZh: '冷调灰白，长时间盯日志最省眼',
    hintEn: 'Cool grey, easiest for long log sessions',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFF7FA8D8),
        alpha: 0.3,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFF9FC4C0),
        alpha: 0.24,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFF24506B),
        alpha: 0.55,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFF1B3B36),
        alpha: 0.42,
      ),
    ],
    light: AppSkinTone(
      bg: Color(0xFFF3F4F7),
      panel: Color(0xFFFFFFFF),
      card: Color(0xFFF7F8FA),
      surface2: Color(0xFFEDEFF3),
      surface3: Color(0xFFF0F2F5),
      selectedBg: Color(0xFFEAF6F2),
      selectedBorder: Color(0xFFBEE8DC),
      border: Color(0xFFE1E5EB),
      text: Color(0xFF1B1F24),
      text2: Color(0xFF3F4653),
      text3: Color(0xFF626B79),
      accent: Color(0xFF0E9E7A),
      accentSoft: Color(0xFFDFF5EE),
      green: Color(0xFF16A34A),
      yellow: Color(0xFFD97706),
      red: Color(0xFFDC2626),
      blue: Color(0xFF2563EB),
      onAccent: Color(0xFFFFFFFF),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF0A0C0F),
      panel: Color(0xFF12151A),
      card: Color(0xFF1A1F26),
      surface2: Color(0xFF1B2129),
      surface3: Color(0xFF141820),
      selectedBg: Color(0xFF1C232C),
      selectedBorder: Color(0xFF2B3540),
      border: Color(0xFF232932),
      text: Color(0xFFE8EAED),
      text2: Color(0xFFB6BEC9),
      text3: Color(0xFF9AA3B0),
      accent: Color(0xFF2FD6A5),
      accentSoft: Color(0xFF123B34),
      green: Color(0xFF4ADE80),
      yellow: Color(0xFFF0B429),
      red: Color(0xFFE5484D),
      blue: Color(0xFF5B8DEF),
      onAccent: Color(0xFF04140F),
    ),
  );


  /// 北欧极简：米白底 + 灰绿强调，低饱和、少装饰，适合长时间盯着看。
  ///
  /// 参考稿里只有 `#5a7a6b` 一个强调色，它当文字压米白底是 4.19:1（差一点），
  /// 所以压深到 `#4E6F5F`；木色 `#a89279`（2.63）和灰蓝 `#7ba0b8`（2.45）
  /// 只保留为观感参考，没有进入文字色。
  static const AppSkin scandinavian = AppSkin(
    id: 'scandinavian',
    nameZh: '北欧极简',
    nameEn: 'Scandinavian',
    hintZh: '米白与灰绿，安静、留白多',
    hintEn: 'Warm off-white with muted sage',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(-0.8, -0.9),
        radiusFactor: 1.0,
        color: Color(0xFFE9C9A4),
        alpha: 0.4,
      ),
      AppBackdropWash(
        align: Alignment(0.9, 0.9),
        radiusFactor: 1.1,
        color: Color(0xFFA9BFAC),
        alpha: 0.3,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(-0.8, -0.9),
        radiusFactor: 1.0,
        color: Color(0xFF6B4F3A),
        alpha: 0.5,
      ),
      AppBackdropWash(
        align: Alignment(0.9, 0.9),
        radiusFactor: 1.1,
        color: Color(0xFF33473C),
        alpha: 0.4,
      ),
    ],
    light: AppSkinTone(
      bg: Color(0xFFF5F0EB),
      panel: Color(0xFFFCFAF7),
      card: Color(0xFFFAF6F1),
      surface2: Color(0xFFEBE5DE),
      surface3: Color(0xFFF0EAE3),
      selectedBg: Color(0xFFE4EDE7),
      selectedBorder: Color(0xFFC3D6CA),
      border: Color(0xFFE2DBD2),
      text: Color(0xFF33322F),
      text2: Color(0xFF554F48),
      text3: Color(0xFF6B655D),
      accent: Color(0xFF4E6F5F),
      accentSoft: Color(0xFFE3EDE6),
      green: Color(0xFF456B52),
      yellow: Color(0xFF846226),
      red: Color(0xFF96433D),
      blue: Color(0xFF456578),
      onAccent: Color(0xFFFBF8F4),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF1E1C1A),
      panel: Color(0xFF26231F),
      card: Color(0xFF2B2823),
      surface2: Color(0xFF322E29),
      surface3: Color(0xFF221F1C),
      selectedBg: Color(0xFF2C3A33),
      selectedBorder: Color(0xFF46604F),
      border: Color(0xFF3A3630),
      text: Color(0xFFEDE7DF),
      text2: Color(0xFFC4BBB0),
      text3: Color(0xFFB0A69A),
      accent: Color(0xFF8FB39E),
      accentSoft: Color(0xFF2C3A33),
      green: Color(0xFF86BF95),
      yellow: Color(0xFFD6B069),
      red: Color(0xFFD9968E),
      blue: Color(0xFF93B4CB),
      onAccent: Color(0xFF16201A),
    ),
  );

  /// 流利设计：Windows 原生质感——蓝色强调、克制的灰阶、小圆角。
  ///
  /// 参考稿的 `#8a8886`（三级灰 3.16:1）和 `#a19f9d`（2.36:1）当文字不够看，
  /// 文字三档整体压深/提亮；强调色 `#0078d4` 压到 `#0F6CBD` 才够当正文用。
  static const AppSkin fluent = AppSkin(
    id: 'fluent',
    nameZh: '流利设计',
    nameEn: 'Fluent',
    hintZh: 'Windows 原生质感，蓝色强调、圆角克制',
    hintEn: 'Windows-native greys with an accent blue',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.2,
        color: Color(0xFFBBD7EE),
        alpha: 0.36,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFFD7E4DA),
        alpha: 0.26,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.2,
        color: Color(0xFF1B3A52),
        alpha: 0.62,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFF24303A),
        alpha: 0.44,
      ),
    ],
    radiusBump: -4,
    light: AppSkinTone(
      bg: Color(0xFFF3F2F1),
      panel: Color(0xFFFFFFFF),
      card: Color(0xFFFAFAF9),
      surface2: Color(0xFFF0EFEE),
      surface3: Color(0xFFF7F6F5),
      selectedBg: Color(0xFFE5F1FB),
      selectedBorder: Color(0xFFA9D3F0),
      border: Color(0xFFE1DFDD),
      text: Color(0xFF1F1F1F),
      text2: Color(0xFF4D4A47),
      text3: Color(0xFF6A6662),
      accent: Color(0xFF0F6CBD),
      accentSoft: Color(0xFFDEECF9),
      green: Color(0xFF107C10),
      yellow: Color(0xFF836800),
      red: Color(0xFFC42B1C),
      blue: Color(0xFF0F6CBD),
      onAccent: Color(0xFFFFFFFF),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF1F1F1F),
      panel: Color(0xFF2B2B2B),
      card: Color(0xFF323232),
      surface2: Color(0xFF383838),
      surface3: Color(0xFF262626),
      selectedBg: Color(0xFF1F3A4D),
      selectedBorder: Color(0xFF2E5A78),
      border: Color(0xFF3D3D3D),
      text: Color(0xFFF3F3F3),
      text2: Color(0xFFC8C6C4),
      text3: Color(0xFFABA9A7),
      accent: Color(0xFF4CC2FF),
      accentSoft: Color(0xFF14384D),
      green: Color(0xFF6CCB5F),
      yellow: Color(0xFFE8C34A),
      red: Color(0xFFFF99A4),
      blue: Color(0xFF4CC2FF),
      onAccent: Color(0xFF06202E),
    ),
  );

  /// 吉卜力：奶油底 + 鼠尾草绿。
  ///
  /// 强调色比参考稿的 `#7cb9a8` 压深到 `#376F62`，因为参考稿里
  /// 「鼠尾草底 + 白字」只有 2.24:1，在 12px 的密排界面里根本看不清；
  /// 压深后作为文字压在奶油底上是 4.77:1，做按钮底配白字是 5.56:1。
  static const AppSkin ghibli = AppSkin(
    id: 'ghibli',
    nameZh: '吉卜力',
    nameEn: 'Ghibli',
    hintZh: '奶油色调、鼠尾草绿，柔和治愈',
    hintEn: 'Cream tones and sage green, soft and warm',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.85, -0.9),
        radiusFactor: 1.0,
        color: Color(0xFFF2C97B),
        alpha: 0.44,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.1,
        color: Color(0xFFA9C6A0),
        alpha: 0.34,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.85, -0.9),
        radiusFactor: 1.0,
        color: Color(0xFF2B4A3E),
        alpha: 0.55,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.1,
        color: Color(0xFF5A4626),
        alpha: 0.4,
      ),
    ],
    radiusBump: 2,
    light: AppSkinTone(
      bg: Color(0xFFF3E8CE),
      panel: Color(0xFFFAF4E6),
      card: Color(0xFFF7EEDC),
      surface2: Color(0xFFEADFC6),
      surface3: Color(0xFFF0E6D2),
      selectedBg: Color(0xFFE2EEE4),
      selectedBorder: Color(0xFFC6DCCB),
      border: Color(0xFFDFCFAF),
      text: Color(0xFF3A3226),
      text2: Color(0xFF544A3C),
      text3: Color(0xFF6B5D49),
      accent: Color(0xFF376F62),
      accentSoft: Color(0xFFD9E8DD),
      green: Color(0xFF3F7340),
      yellow: Color(0xFF8A5A16),
      red: Color(0xFF9E4030),
      blue: Color(0xFF3F6A96),
      onAccent: Color(0xFFFBFAF3),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF131A19),
      panel: Color(0xFF1A2321),
      card: Color(0xFF1F2A27),
      surface2: Color(0xFF243029),
      surface3: Color(0xFF17201E),
      selectedBg: Color(0xFF1D2E29),
      selectedBorder: Color(0xFF2C4A40),
      border: Color(0xFF2E3B36),
      text: Color(0xFFEFE6D2),
      text2: Color(0xFFC9BFA9),
      text3: Color(0xFFA0947E),
      accent: Color(0xFF6FC2A6),
      accentSoft: Color(0xFF1E332C),
      green: Color(0xFF7FCB8A),
      yellow: Color(0xFFE3B563),
      red: Color(0xFFE3796A),
      blue: Color(0xFF86B0DA),
      onAccent: Color(0xFF0C1714),
    ),
  );

  /// 纸墨：宣纸底 + 朱红，比吉卜力更中性一些。
  static const AppSkin ink = AppSkin(
    id: 'ink',
    nameZh: '纸墨',
    nameEn: 'Paper & Ink',
    hintZh: '宣纸底色，朱红点缀',
    hintEn: 'Rice paper with vermilion accents',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.2, -0.3),
        radiusFactor: 1.2,
        color: Color(0xFFD9C9B2),
        alpha: 0.3,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFFB9A78E),
        alpha: 0.24,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.2, -0.3),
        radiusFactor: 1.2,
        color: Color(0xFF3A2C22),
        alpha: 0.52,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFF241C16),
        alpha: 0.42,
      ),
    ],
    radiusBump: 1,
    light: AppSkinTone(
      bg: Color(0xFFF6F2E8),
      panel: Color(0xFFFDFBF5),
      card: Color(0xFFF9F5EB),
      surface2: Color(0xFFEDE7D9),
      surface3: Color(0xFFF3EEE2),
      selectedBg: Color(0xFFF2E8E2),
      selectedBorder: Color(0xFFDCC7BE),
      border: Color(0xFFDED7C6),
      text: Color(0xFF2B2B28),
      text2: Color(0xFF4A4A44),
      text3: Color(0xFF68645A),
      accent: Color(0xFF8A3C2E),
      accentSoft: Color(0xFFF3E2DC),
      green: Color(0xFF3F6B4A),
      yellow: Color(0xFF8A5F1C),
      red: Color(0xFF9C3A2C),
      blue: Color(0xFF38587E),
      onAccent: Color(0xFFFDFBF5),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF1A1714),
      panel: Color(0xFF221E1A),
      card: Color(0xFF28231E),
      surface2: Color(0xFF2E2823),
      surface3: Color(0xFF1E1A16),
      selectedBg: Color(0xFF31251F),
      selectedBorder: Color(0xFF4A3A31),
      border: Color(0xFF3A332C),
      text: Color(0xFFEDE6DA),
      text2: Color(0xFFC6BCAC),
      text3: Color(0xFF9C9282),
      accent: Color(0xFFD98A6E),
      accentSoft: Color(0xFF3A241D),
      green: Color(0xFF8FC79A),
      yellow: Color(0xFFDDB268),
      red: Color(0xFFE0836F),
      blue: Color(0xFF8FB0D8),
      onAccent: Color(0xFF1A1714),
    ),
  );

  /// 新拟物：浅灰同色系 + 双光源光影，紫色只出现在交互元素上。
  ///
  /// 两处跟参考稿不同，都是因为本项目正文是 11–13px 小字：
  /// - 次要文字 `#6b7280`（3.82:1）压深到 `#47566B`（5.90:1）
  /// - 弱化文字 `gray-400`（2.01:1）压深到 `#566175`（4.93:1）
  /// - 强调色 `#6d5dfc` 当文字只有 3.59:1，压深到 `#4A3AC7`（5.55:1）；
  ///   白字压在它上面 7.72:1，实心按钮依然清晰
  static const AppSkin neumorph = AppSkin(
    id: 'neumorph',
    nameZh: '新拟物',
    nameEn: 'Neumorphism',
    hintZh: '浅灰同色系 + 双光源光影，凸起即按钮',
    hintEn: 'Soft grey surfaces lit from the top left',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(-0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFFFFFFFF),
        alpha: 0.46,
      ),
      AppBackdropWash(
        align: Alignment(0.9, 0.9),
        radiusFactor: 1.1,
        color: Color(0xFFB8C2D0),
        alpha: 0.34,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(-0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFF3E4653),
        alpha: 0.52,
      ),
      AppBackdropWash(
        align: Alignment(0.9, 0.9),
        radiusFactor: 1.1,
        color: Color(0xFF14161A),
        alpha: 0.52,
      ),
    ],
    radiusBump: 4,
    material: AppSkinMaterial.soft,
    softDepth: 6,
    light: AppSkinTone(
      bg: Color(0xFFE0E5EC),
      panel: Color(0xFFE4E9F0),
      card: Color(0xFFE6EBF2),
      surface2: Color(0xFFD7DDE7),
      surface3: Color(0xFFDFE4EB),
      selectedBg: Color(0xFFE3E0FB),
      selectedBorder: Color(0xFFCFC8F6),
      border: Color(0xFFD9DFE9),
      text: Color(0xFF2F3540),
      text2: Color(0xFF47566B),
      text3: Color(0xFF566175),
      accent: Color(0xFF4A3AC7),
      accentSoft: Color(0xFFE4E1FB),
      green: Color(0xFF2B6E4E),
      yellow: Color(0xFF83601A),
      red: Color(0xFFA63A3A),
      blue: Color(0xFF3A5CA8),
      onAccent: Color(0xFFFFFFFF),
      shadowDark: Color(0xFFB8BCC2),
      shadowLight: Color(0xFFFFFFFF),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF2A2D33),
      panel: Color(0xFF2E3239),
      card: Color(0xFF31353D),
      surface2: Color(0xFF24272C),
      surface3: Color(0xFF2C3037),
      selectedBg: Color(0xFF3A3459),
      selectedBorder: Color(0xFF4A4173),
      border: Color(0xFF383C44),
      text: Color(0xFFE7EAF0),
      text2: Color(0xFFB9C1CD),
      text3: Color(0xFFA0A9B6),
      accent: Color(0xFFA99CFF),
      accentSoft: Color(0xFF35304F),
      green: Color(0xFF7FCCA0),
      yellow: Color(0xFFE3B85F),
      red: Color(0xFFE58989),
      blue: Color(0xFF94B6E8),
      onAccent: Color(0xFF1B1830),
      shadowDark: Color(0xFF17191C),
      shadowLight: Color(0xFF3E444D),
    ),
  );

  /// 夜航玻璃：深墨夜景 + 两处柔和光源，玻璃自身无色、只借光。
  ///
  /// 这是"无模糊版"：Flutter 的 `BackdropFilter` 在每块面板上都用会明显掉帧，
  /// 而玻璃的观感主要来自"半透明白 + 白色细边 + 顶边高光 + 底边暗缘"，
  /// 这四样都不需要真的高斯模糊，所以在深底上做"假玻璃"性价比最高。
  ///
  /// 两处按本项目小字重算过（否则光斑处会掉到 3:1 以下）：
  /// - 光斑强度压到 0.16/0.22（参考稿 0.28/0.35），保证文字底色不至于太亮
  /// - 状态色提亮降饱和：绿 #8FC7AE / 黄 #E3C27E / 红 #E09A90 / 蓝 #A6BEDC
  ///   光斑处实测 5.60 / 6.28 / 4.70 / 5.64，均过 AA
  static const AppSkin glass = AppSkin(
    id: 'glass',
    nameZh: '夜航玻璃',
    nameEn: 'Nocturne Glass',
    hintZh: '深墨夜景配香槟金，玻璃只借光（仅夜间）',
    hintEn: 'Deep night glass with champagne light (dark only)',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.88, -0.9),
        radiusFactor: 0.95,
        color: Color(0xFF7C9CC4),
        alpha: 0.16,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.95),
        radiusFactor: 0.9,
        color: Color(0xFF33517A),
        alpha: 0.22,
      ),
      AppBackdropWash(
        align: Alignment(0.05, -0.1),
        radiusFactor: 0.62,
        color: Color(0xFFE4B863),
        alpha: 0.05,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.88, -0.9),
        radiusFactor: 0.95,
        color: Color(0xFF7C9CC4),
        alpha: 0.16,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.95),
        radiusFactor: 0.9,
        color: Color(0xFF33517A),
        alpha: 0.22,
      ),
      AppBackdropWash(
        align: Alignment(0.05, -0.1),
        radiusFactor: 0.62,
        color: Color(0xFFE4B863),
        alpha: 0.05,
      ),
    ],
    radiusBump: 4,
    material: AppSkinMaterial.glass,
    darkOnly: true,
    backdropBase: Color(0xFF0B1322),
    light: _glassTone,
    dark: _glassTone,
  );


  /// 日系清新：冷白底 + 蓝灰文字 + 一点点樱花与薄荷，只有白天形态。
  ///
  /// 参考稿明确禁止深色背景，所以这套标记为 `lightOnly`。
  /// 它的浅色系（天蓝 `#64b5f6` 2.12、薄荷 `#98d8c8` 1.55、樱花粉）
  /// 全部只做底色/装饰；文字与强调色重算过：强调由天蓝压深到 `#2C6B92`。
  static const AppSkin japanese = AppSkin(
    id: 'japanese',
    nameZh: '日系清新',
    nameEn: 'Japanese Fresh',
    hintZh: '冷白与蓝灰，樱花与薄荷点缀（仅白天）',
    hintEn: 'Cool white with blue-grey text (light only)',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFFCDE7F5),
        alpha: 0.42,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFFF7D3DC),
        alpha: 0.34,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFFCDE7F5),
        alpha: 0.42,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFFF7D3DC),
        alpha: 0.34,
      ),
    ],
    lightOnly: true,
    light: _japaneseTone,
    dark: _japaneseTone,
  );

  /// 鲜活市集：米底 + 深绿 + 赭橙，暖、有市集气。
  ///
  /// 参考稿的橙 `#e8722a` 当文字只有 2.91:1，压深到 `#A64B1B`；
  /// 深棕 `#8b4513` 与褐 `#8b7355` 不进文字色，只在底色里做层次。
  static const AppSkin market = AppSkin(
    id: 'market',
    nameZh: '鲜活市集',
    nameEn: 'Fresh Market',
    hintZh: '米底配深绿与赭橙，暖而热闹',
    hintEn: 'Cream with deep green and burnt orange',
    sceneLight: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFFF5D9A8),
        alpha: 0.42,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFFC9DCB0),
        alpha: 0.34,
      ),
    ],
    sceneDark: <AppBackdropWash>[
      AppBackdropWash(
        align: Alignment(0.9, -0.9),
        radiusFactor: 1.1,
        color: Color(0xFF4A2E1C),
        alpha: 0.5,
      ),
      AppBackdropWash(
        align: Alignment(-0.9, 0.9),
        radiusFactor: 1.0,
        color: Color(0xFF2A3A1E),
        alpha: 0.4,
      ),
    ],
    light: AppSkinTone(
      bg: Color(0xFFFEF9F0),
      panel: Color(0xFFFFFDF7),
      card: Color(0xFFFDF7EC),
      surface2: Color(0xFFF3EADB),
      surface3: Color(0xFFF8F1E4),
      selectedBg: Color(0xFFE7F0DA),
      selectedBorder: Color(0xFFC6DCAC),
      border: Color(0xFFE8DCC6),
      text: Color(0xFF33301E),
      text2: Color(0xFF5A5340),
      text3: Color(0xFF6B6150),
      accent: Color(0xFFA64B1B),
      accentSoft: Color(0xFFFBE8D8),
      green: Color(0xFF3F6B2A),
      yellow: Color(0xFF8A6414),
      red: Color(0xFFA63B2B),
      blue: Color(0xFF3F6B7A),
      onAccent: Color(0xFFFFF9EC),
    ),
    dark: AppSkinTone(
      bg: Color(0xFF201B14),
      panel: Color(0xFF272119),
      card: Color(0xFF2C251B),
      surface2: Color(0xFF332B20),
      surface3: Color(0xFF221D16),
      selectedBg: Color(0xFF2B3324),
      selectedBorder: Color(0xFF44543A),
      border: Color(0xFF3A3225),
      text: Color(0xFFF0E9DC),
      text2: Color(0xFFCDBFA8),
      text3: Color(0xFFA8997F),
      accent: Color(0xFFF0925A),
      accentSoft: Color(0xFF3A2A1C),
      green: Color(0xFF8FC07A),
      yellow: Color(0xFFE0B75C),
      red: Color(0xFFE08A78),
      blue: Color(0xFF8FB6C9),
      onAccent: Color(0xFF2A1608),
    ),
  );

  static const List<AppSkin> all = [
    classic,
    scandinavian,
    fluent,
    ghibli,
    ink,
    neumorph,
    glass,
    japanese,
    market,
  ];

  /// 当前生效的皮肤。由 `ThemeService` 在启动与切换时写入。
  ///
  /// 这里用静态可变字段而不是 Rx，是因为 `AppColors` 是纯静态取值器，
  /// 被两百多个文件直接引用；皮肤切换由 `ThemeService` 主动触发整树重建，
  /// 保证重建时读到的就是新值。
  static AppSkin active = classic;

  static AppSkin byId(String? id) {
    for (final skin in all) {
      if (skin.id == id) {
        return skin;
      }
    }
    return classic;
  }
}
