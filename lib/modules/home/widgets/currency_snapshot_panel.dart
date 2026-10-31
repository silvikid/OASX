import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/app_colors.dart';
import 'package:oasx/config/app_skin.dart';
import 'package:oasx/modules/common/widgets/soft_surface.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/modules/home/models/currency_snapshot_models.dart';

const _kCurrencyPadding = 12.0;
const _kCurrencyCardSpacing = 8.0;

/// Every card reserves the same icon slot so labels and amounts stay in one
/// column; all icons are drawn at one uniform size.
const _kIconSlot = 34.0;
const _kIconBase = 32.0;

/// 默认显示顺序；不在这张表里的资产默认隐藏。
const List<String> _kDefaultOrder = [
  'jade',
  'ap',
  'coin',
  'mystery_amulet',
  'daruma',
  'daruma_frag',
  's_jade',
  'ar_amulet',
  'reverse_scale',
  'demon_soul',
  'medal',
  'contrib',
  'honor',
  'totem_key',
  'hyakki_ticket',
  'skin_token',
];

/// Asset icons shipped under `assets/images/currency/`, keyed by the stable
/// field name that OAS reports (not by the localized label, which can change).
const Map<String, String> _kCurrencyIconAssets = {
  'jade': 'assets/images/currency/jade.png',
  'ap': 'assets/images/currency/ap.png',
  'coin': 'assets/images/currency/coin.png',
  's_jade': 'assets/images/currency/s_jade.png',
  'mystery_amulet': 'assets/images/currency/mystery_amulet.png',
  'broken_amulet': 'assets/images/currency/broken_amulet.png',
  'ar_amulet': 'assets/images/currency/ar_amulet.png',
  'reverse_scale': 'assets/images/currency/reverse_scale.png',
  'scale': 'assets/images/currency/scale.png',
  'ofuda': 'assets/images/currency/ofuda.png',
  'gold_ofuda': 'assets/images/currency/gold_ofuda.png',
  'honor': 'assets/images/currency/honor.png',
  'medal': 'assets/images/currency/medal.png',
  'skin_token': 'assets/images/currency/skin_token.png',
  'sp_skin_token': 'assets/images/currency/sp_skin_token.png',
  'demon_soul': 'assets/images/currency/demon_soul.png',
  // 御行达摩本体与碎片共用同一张图
  'daruma_frag': 'assets/images/currency/daruma.png',
  'totem_key': 'assets/images/currency/totem_key.png',
  'hyakki_ticket': 'assets/images/currency/hyakki_ticket.png',
  'contrib': 'assets/images/currency/contrib.png',
  'sakura': 'assets/images/currency/sakura.png',
  'daruma': 'assets/images/currency/daruma.png',
};

/// Asset snapshot panel: in-game resources with a start/end date comparison.
///
/// Data comes from `GET /currency/history`, which reads the CSV written by the
/// OAS `CurrencySnapshot` task. Visible assets and their order are remembered
/// locally.
class CurrencySnapshotPanel extends StatefulWidget {
  const CurrencySnapshotPanel({super.key});

  @override
  State<CurrencySnapshotPanel> createState() => _CurrencySnapshotPanelState();
}

class _CurrencySnapshotPanelState extends State<CurrencySnapshotPanel> {
  static final NumberFormat _amountFormat = NumberFormat('#,###');
  static final DateFormat _dateFormat = DateFormat('MM-dd HH:mm');

  final GetStorage _storage = GetStorage();

  CurrencyHistory? _history;
  bool _loading = true;
  String? _error;
  int _startIndex = 0;
  int _endIndex = 0;

  /// Null means "show everything"; an empty set means the user hid them all.
  Set<String>? _visibleKeys;

  /// User-defined display order; null means "use the backend order".
  List<String>? _order;

  /// 这套 OAS 根本没有资源快照功能（404/503），属于正常情况而非故障。
  bool _unsupported = false;

  @override
  void initState() {
    super.initState();
    final storedVisible = _storage.read(StorageKey.currencyVisibleKeys.name);
    if (storedVisible is List) {
      _visibleKeys = storedVisible.map((item) => item.toString()).toSet();
    } else {
      _visibleKeys = _kDefaultOrder.toSet();
    }
    final storedOrder = _storage.read(StorageKey.currencyOrder.name);
    if (storedOrder is List && storedOrder.isNotEmpty) {
      _order = storedOrder.map((item) => item.toString()).toList();
    } else {
      _order = [..._kDefaultOrder];
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ApiClient().getCurrencyHistory();
    if (!mounted) {
      return;
    }
    final history = result.data;
    setState(() {
      _loading = false;
      if (result.isSuccess && history != null && history.records.isNotEmpty) {
        _history = history;
        _endIndex = 0;
        _startIndex = history.records.length > 1 ? 1 : 0;
        _error = null;
      } else {
        _unsupported =
            !result.isSuccess && (result.code == 404 || result.code == 503);
        _error = _describeError(result, history);
      }
    });
  }

  String _describeError(
    ApiResult<CurrencyHistory> result,
    CurrencyHistory? history,
  ) {
    if (_unsupported) {
      return '该 OAS 未启用资源快照';
    }
    final error = result.error;
    if (error != null && error.isNotEmpty) {
      return '读取资产失败\n$error';
    }
    if (history == null || history.records.isEmpty) {
      return '还没有资产记录\n先跑一次「资源快照」任务';
    }
    return '读取资产失败';
  }

  /// Backend order merged with the user order: saved positions win, and fields
  /// the backend added later are appended instead of disappearing.
  List<String> _mergedOrder(CurrencyHistory history) {
    final saved = _order;
    if (saved == null || saved.isEmpty) {
      return history.order;
    }
    final known = history.order.toSet();
    final merged = <String>[
      for (final key in saved)
        if (known.contains(key)) key,
    ];
    for (final key in history.order) {
      if (!merged.contains(key)) {
        merged.add(key);
      }
    }
    return merged;
  }

  Future<void> _openVisibilitySettings(CurrencyHistory history) async {
    final order = _mergedOrder(history);
    final result = await showDialog<_VisibilityResult>(
      context: context,
      builder: (context) => _VisibilityDialog(
        order: order,
        labels: history.labels,
        selected: _visibleKeys ?? order.toSet(),
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _visibleKeys = result.visible;
      _order = result.order;
    });
    await _storage.write(
      StorageKey.currencyVisibleKeys.name,
      result.visible.toList(growable: false),
    );
    await _storage.write(StorageKey.currencyOrder.name, result.order);
  }

  String _labelFor(CurrencyRecord record) {
    final time = record.collectedAt;
    return time == null
        ? (record.collectedAtText ?? '--')
        : _dateFormat.format(time);
  }

  /// 打开起止日期弹层：快捷区间 + 迷你日历两步选择。
  Future<void> _openDateRangePicker(List<CurrencyRecord> records) async {
    final result = await showGeneralDialog<_RangeSelection>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '选择起止日期',
      barrierColor: Colors.black38,
      pageBuilder: (context, _, __) => _DateRangePopover(
        records: records,
        startIndex: _startIndex,
        endIndex: _endIndex,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _startIndex = result.startIndex;
      _endIndex = result.endIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;

    if (_loading && history == null) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (history == null || history.records.isEmpty) {
      return _EmptyView(
        message: _error ?? '还没有资产记录\n先跑一次「资源快照」任务',
        onRetry: _load,
        canRetry: !_unsupported,
      );
    }

    final records = history.records;
    final endIndex = _endIndex.clamp(0, records.length - 1);
    final startIndex = _startIndex.clamp(0, records.length - 1);
    final current = records[endIndex];
    final baseline = records[startIndex];
    final canCompare = startIndex != endIndex;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _kCurrencyPadding,
            _kCurrencyPadding,
            _kCurrencyPadding,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: _DatePill(
                  caption: '起',
                  label: _labelFor(records[startIndex]),
                  onTap: () => _openDateRangePicker(records),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: AppColors.text3,
                ),
              ),
              Expanded(
                child: _DatePill(
                  caption: '止',
                  label: _labelFor(records[endIndex]),
                  onTap: () => _openDateRangePicker(records),
                ),
              ),
              const SizedBox(width: 6),
              _HeaderIconButton(
                icon: Icons.tune_rounded,
                tooltip: '显示与排序',
                onTap: () => _openVisibilitySettings(history),
              ),
              const SizedBox(width: 4),
              _HeaderIconButton(
                icon: Icons.refresh_rounded,
                tooltip: '刷新',
                loading: _loading,
                onTap: _load,
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth =
                  ((constraints.maxWidth -
                              _kCurrencyPadding * 2 -
                              _kCurrencyCardSpacing) /
                          2)
                      .clamp(120.0, 260.0);
              final visible = _visibleKeys;
              final rows = <_AssetRow>[
                for (final key in _mergedOrder(history))
                  if (current.values.containsKey(key))
                    if (visible == null || visible.contains(key))
                      _AssetRow(
                        key: key,
                        label: history.labels[key] ?? key,
                        amount: current.amountOf(key),
                        delta: canCompare
                            ? current.amountOf(key) - baseline.amountOf(key)
                            : null,
                      ),
              ];
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    '没有可显示的资产\n点右上角漏斗图标选择',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.text3),
                  ),
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  _kCurrencyPadding,
                  10,
                  _kCurrencyPadding,
                  _kCurrencyPadding,
                ),
                child: Wrap(
                  spacing: _kCurrencyCardSpacing,
                  runSpacing: _kCurrencyCardSpacing,
                  children: [
                    for (final row in rows)
                      SizedBox(
                        width: cardWidth,
                        child: _AssetCard(row: row, format: _amountFormat),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One row of the grid: field key, label, amount and optional delta.
class _AssetRow {
  const _AssetRow({
    required this.key,
    required this.label,
    required this.amount,
    this.delta,
  });

  final String key;
  final String label;
  final int amount;

  /// Change between the selected start and end snapshots; null when equal.
  final int? delta;
}

class _RangeSelection {
  const _RangeSelection(this.startIndex, this.endIndex);

  final int startIndex;
  final int endIndex;
}

/// 起止日期胶囊：点击打开选择弹层。
class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.caption,
    required this.label,
    required this.onTap,
  });

  final String caption;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: 8 + AppSkins.active.radiusBump,
      color: AppColors.surface2,
      depth: AppColors.softDepth * 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(8 + AppSkins.active.radiusBump),
        onTap: onTap,
        child: SizedBox(
          height: 30,
          child: Row(
            children: [
              const SizedBox(width: 8),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: AppColors.text3,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: AppColors.text3,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// 起止日期弹层：上排快捷区间，下面迷你日历两步选择。
///
/// 点第一天定起点、点第二天定终点后自动应用并关闭；无采集记录的日子灰掉
/// 不可选——起止必须是"有快照的两天"，这条规则在日历上是看得见的。
class _DateRangePopover extends StatefulWidget {
  const _DateRangePopover({
    required this.records,
    required this.startIndex,
    required this.endIndex,
  });

  final List<CurrencyRecord> records;
  final int startIndex;
  final int endIndex;

  @override
  State<_DateRangePopover> createState() => _DateRangePopoverState();
}

class _DateRangePopoverState extends State<_DateRangePopover> {
  late DateTime _month;
  DateTime? _first;
  DateTime? _second;
  late final Set<String> _availableDays;

  /// true 时显示"年 + 12 个月"的跳转面板，点月份直接翻过去。
  bool _pickingMonth = false;

  /// 月份跳转面板正在浏览的年份。
  int _yearNav = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    final endDate = _dateOf(widget.records[widget.endIndex.clamp(
      0,
      widget.records.length - 1,
    )]);
    _month = DateTime(endDate.year, endDate.month, 1);
    _first = _dateOf(widget.records[widget.startIndex.clamp(
      0,
      widget.records.length - 1,
    )]);
    _second = _dateOf(widget.records[widget.endIndex.clamp(
      0,
      widget.records.length - 1,
    )]);
    _availableDays = <String>{
      for (final record in widget.records)
        if (record.collectedAt != null) _dayKey(record.collectedAt!),
    };
  }

  static DateTime _dateOf(CurrencyRecord record) {
    final time = record.collectedAt;
    if (time != null) {
      return DateTime(time.year, time.month, time.day);
    }
    final parsed = DateTime.tryParse(record.collectedAtText ?? '');
    return parsed == null ? DateTime.now() : DateTime(parsed.year, parsed.month, parsed.day);
  }

  static String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  String _label(DateTime day) =>
      '${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  /// 当天有多次采集时：起点取最早一次，终点取最晚一次。
  int _indexFor(DateTime day, {required bool oldest}) {
    var found = -1;
    for (var index = 0; index < widget.records.length; index++) {
      final time = widget.records[index].collectedAt;
      if (time == null) {
        continue;
      }
      if (time.year == day.year && time.month == day.month && time.day == day.day) {
        found = index;
        if (!oldest) {
          break;
        }
      }
    }
    return found < 0 ? 0 : found;
  }

  void _apply(int startIndex, int endIndex) {
    Navigator.of(context).pop(_RangeSelection(startIndex, endIndex));
  }

  void _tapDay(DateTime day) {
    if (_first == null || (_first != null && _second != null)) {
      setState(() {
        _first = day;
        _second = null;
      });
      return;
    }
    var a = _first!;
    var b = day;
    if (b.isBefore(a)) {
      final tmp = a;
      a = b;
      b = tmp;
    }
    _apply(_indexFor(a, oldest: true), _indexFor(b, oldest: false));
  }

  void _applyQuick(int days) {
    final endDate = _dateOf(widget.records[0]);
    final cutoff = DateTime(endDate.year, endDate.month, endDate.day - days + 1);
    var start = -1;
    for (var index = widget.records.length - 1; index >= 0; index--) {
      final time = widget.records[index].collectedAt;
      if (time != null &&
          !DateTime(time.year, time.month, time.day).isBefore(cutoff)) {
        start = index;
        break;
      }
    }
    _apply(start < 0 ? widget.records.length - 1 : start, 0);
  }

  void _applyAll() => _apply(widget.records.length - 1, 0);

  @override
  Widget build(BuildContext context) {
    final radius = 12 + AppSkins.active.radiusBump;
    // 内容里有一排 Expanded 的星期格，会把弹层撑到整屏宽；
    // 这里给它一个固定宽度，日历格自动均分。
    final width = (MediaQuery.sizeOf(context).width - 48).clamp(280.0, 340.0);
    final content = SizedBox(width: width, child: _buildContent());
    if (!AppColors.isGlassMaterial) {
      return Dialog(
        backgroundColor: AppColors.overlay,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: AppColors.border),
        ),
        child: content,
      );
    }
    // 玻璃：这里面积大、位置固定，是少数值得上真 BackdropFilter 的地方。
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: AppColors.border),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  /// 有记录的月份集合（"yyyy-MM"），用于月份跳转面板里的点点标记。
  Set<String> get _monthsWithRecords => <String>{
    for (final key in _availableDays) key.substring(0, 7),
  };

  Widget _buildContent() {
    final monthLabel =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final first = DateTime(_month.year, _month.month, 1);
    final lead = (first.weekday + 6) % 7; // 周一打头
    final dayCount = DateTime(_month.year, _month.month + 1, 0).day;
    const weekdays = <String>['一', '二', '三', '四', '五', '六', '日'];

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '选择起止日期',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Row(
            children: [
              for (final (label, days) in <(String, int)>[
                ('最近 7 天', 7),
                ('最近 30 天', 30),
                ('全部', 0),
              ]) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(label, style: const TextStyle(fontSize: 11.5)),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: AppColors.border),
                    backgroundColor: AppColors.surface2,
                    onPressed: () =>
                        days == 0 ? _applyAll() : _applyQuick(days),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (_pickingMonth) ...[
            _buildMonthPicker(),
          ] else ...[
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => setState(() {
                    _yearNav = _month.year;
                    _pickingMonth = true;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          monthLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: AppColors.text3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
                icon: const Icon(Icons.chevron_right_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final weekday in weekdays)
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.text3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          for (var week = 0; week < 6; week++)
            Row(
              children: [
                for (var cell = 0; cell < 7; cell++)
                  Expanded(child: _buildDayCell(lead, dayCount, week, cell)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _hint(),
            style: TextStyle(fontSize: 11, color: AppColors.text3),
          ),
        ],
      ),
    );
  }

  /// "年 + 12 个月"跳转面板：点年月标签进入，点某个月直接翻过去。
  Widget _buildMonthPicker() {
    final withRecords = _monthsWithRecords;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() => _yearNav = _yearNav - 1),
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '$_yearNav 年',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _yearNav = _yearNav + 1),
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < 3; row++)
          Row(
            children: [
              for (var col = 0; col < 4; col++)
                Expanded(child: _buildMonthCell(row * 4 + col + 1, withRecords)),
            ],
          ),
      ],
    );
  }

  Widget _buildMonthCell(int month, Set<String> withRecords) {
    final monthKey =
        '$_yearNav-${month.toString().padLeft(2, '0')}';
    final hasRecords = withRecords.contains(monthKey);
    final isCurrent =
        _month.year == _yearNav && _month.month == month;
    return Padding(
      padding: const EdgeInsets.all(2),
      child: SizedBox(
        height: 34,
        child: Material(
          color: isCurrent ? AppColors.tealDim : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() {
              _month = DateTime(_yearNav, month, 1);
              _pickingMonth = false;
            }),
            child: Center(
              child: Text(
                '$month 月',
                style: TextStyle(
                  fontSize: 12,
                  color: hasRecords ? AppColors.text : AppColors.text3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(int lead, int dayCount, int week, int cell) {
    final dayNumber = week * 7 + cell - lead + 1;
    if (dayNumber < 1 || dayNumber > dayCount) {
      return const SizedBox(height: 30);
    }
    final day = DateTime(_month.year, _month.month, dayNumber);
    final key = _dayKey(day);
    final available = _availableDays.contains(key);
    var background = Colors.transparent;
    var foreground = available ? AppColors.text : AppColors.text3;
    if (!available) {
      background = AppColors.surface3.withValues(alpha: 0.4);
    } else {
      background = AppColors.tealDim;
      if (_first != null && _dayKey(_first!) == key) {
        background = AppColors.teal;
        foreground = AppColors.onAccent;
      }
      if (_second != null && _dayKey(_second!) == key) {
        background = AppColors.teal;
        foreground = AppColors.onAccent;
      }
    }
    return Padding(
      padding: const EdgeInsets.all(1),
      child: SizedBox(
        height: 30,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: available ? () => _tapDay(day) : null,
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 12,
                  color: foreground,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _hint() {
    if (_pickingMonth) {
      return '点月份直接跳转 · 再点年月标签返回日历';
    }
    if (_first == null) {
      return '点第一天作为起点';
    }
    if (_second == null) {
      return '起点 ${_label(_first!)} · 再点一天作为终点';
    }
    return '${_label(_first!)} → ${_label(_second!)}';
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: loading ? null : onTap,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(7),
          ),
          child: loading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.8),
                )
              : Icon(icon, size: 15, color: AppColors.text3),
        ),
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.row, required this.format});

  final _AssetRow row;
  final NumberFormat format;

  @override
  Widget build(BuildContext context) {
    final iconAsset = _kCurrencyIconAssets[row.key];
    final delta = row.delta;
    final hasDelta = delta != null && delta != 0;
    final exact = format.format(row.amount);
    final deltaText = hasDelta ? formatCurrencyDelta(delta, format) : '';
    final tooltip = hasDelta
        ? '${row.label}：$exact（$deltaText）'
        : '${row.label}：$exact';

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 350),
      child: SoftSurface(
        radius: 10 + AppSkins.active.radiusBump,
        color: AppColors.surface2,
        depth: AppColors.softDepth * 0.6,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        // 图标上下居中；右侧涨跌贴顶；中间的文案块自己居中
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _kIconSlot,
                child: Center(
                  child: SizedBox(
                    width: _kIconSlot,
                    height: _kIconSlot,
                    child: iconAsset == null
                        ? _FallbackIcon(label: row.label)
                        : OverflowBox(
                            alignment: Alignment.center,
                            minWidth: _kIconBase,
                            maxWidth: _kIconBase,
                            minHeight: _kIconBase,
                            maxHeight: _kIconBase,
                            child: Image.asset(
                              iconAsset,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      row.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: AppColors.text3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrencyAmount(row.amount, format),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDelta) ...[
                const SizedBox(width: 6),
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    formatCurrencyDelta(delta, format),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: delta > 0 ? AppColors.green : AppColors.red,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Shown when an asset has no icon file: first character in a soft chip.
class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final char = label.isEmpty ? '?' : label.substring(0, 1);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(char, style: TextStyle(fontSize: 11, color: AppColors.text3)),
    );
  }
}

class _VisibilityResult {
  const _VisibilityResult({required this.order, required this.visible});

  final List<String> order;
  final Set<String> visible;
}

/// Lets the user choose which assets the panel shows and in which order.
class _VisibilityDialog extends StatefulWidget {
  const _VisibilityDialog({
    required this.order,
    required this.labels,
    required this.selected,
  });

  final List<String> order;
  final Map<String, String> labels;
  final Set<String> selected;

  @override
  State<_VisibilityDialog> createState() => _VisibilityDialogState();
}

class _VisibilityDialogState extends State<_VisibilityDialog> {
  late Set<String> _selected = {...widget.selected};
  late final List<String> _order = [...widget.order];

  void _move(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _order.length) {
      return;
    }
    setState(() {
      final item = _order.removeAt(index);
      _order.insert(target, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      clipBehavior: Clip.antiAlias,
      title: Text(
        '显示与排序',
        style: TextStyle(fontSize: 15, color: AppColors.text),
      ),
      content: SizedBox(
        width: 340,
        height: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _selected = {..._order}),
                  child: const Text('全选', style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => setState(() => _selected = {}),
                  child: const Text('全不选', style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                Text(
                  '${_selected.length}/${_order.length}',
                  style: TextStyle(fontSize: 11, color: AppColors.text3),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _order.length,
                itemBuilder: (context, index) {
                  final key = _order[index];
                  final label = widget.labels[key] ?? key;
                  final checked = _selected.contains(key);
                  return Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: checked,
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.text,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selected.add(key);
                              } else {
                                _selected.remove(key);
                              }
                            });
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: '上移',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: index == 0 ? null : () => _move(index, -1),
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                      IconButton(
                        tooltip: '下移',
                        visualDensity: VisualDensity.compact,
                        iconSize: 16,
                        onPressed: index == _order.length - 1
                            ? null
                            : () => _move(index, 1),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(fontSize: 12)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_VisibilityResult(order: _order, visible: _selected)),
          child: const Text('保存', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.message,
    required this.onRetry,
    this.canRetry = true,
  });

  final String message;
  final Future<void> Function() onRetry;
  final bool canRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.savings_outlined, size: 26, color: AppColors.text3),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.text3,
              ),
            ),
            if (canRetry) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => onRetry(),
                child: const Text('重试', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats an asset amount: large values collapse to `万` with two decimals,
/// small values keep thousand separators.
///
/// `84599 -> 8.46万`, `15456719 -> 1545.67万`, `4695 -> 4,695`.
String formatCurrencyAmount(int value, NumberFormat format) {
  final abs = value.abs();
  if (abs >= 10000) {
    return '${(value / 10000).toStringAsFixed(2)}万';
  }
  return format.format(value);
}

/// Formats a delta with an explicit sign.
///
/// `133 -> +133`, `-808216 -> -80.82万`.
String formatCurrencyDelta(int delta, NumberFormat format) {
  final abs = delta.abs();
  final body = abs >= 10000
      ? '${(abs / 10000).toStringAsFixed(2)}万'
      : format.format(abs);
  return delta > 0 ? '+$body' : '-$body';
}
