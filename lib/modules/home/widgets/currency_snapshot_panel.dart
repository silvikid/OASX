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
                child: _DateDropdown(
                  caption: '起',
                  records: records,
                  value: startIndex,
                  format: _dateFormat,
                  onSelect: (index) => setState(() => _startIndex = index),
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
                child: _DateDropdown(
                  caption: '止',
                  records: records,
                  value: endIndex,
                  format: _dateFormat,
                  onSelect: (index) => setState(() => _endIndex = index),
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

class _DateDropdown extends StatelessWidget {
  const _DateDropdown({
    required this.caption,
    required this.records,
    required this.value,
    required this.format,
    required this.onSelect,
  });

  final String caption;
  final List<CurrencyRecord> records;
  final int value;
  final DateFormat format;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      radius: 8 + AppSkins.active.radiusBump,
      color: AppColors.surface2,
      depth: AppColors.softDepth * 0.6,
      child: Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            caption,
            // 与下拉文字同样的字号和行高，保证两者视觉处于同一水平线
            style: TextStyle(fontSize: 12, height: 1.2, color: AppColors.text3),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: value,
                isDense: true,
                isExpanded: true,
                alignment: Alignment.centerLeft,
                borderRadius: BorderRadius.circular(9),
                icon: Icon(
                  Icons.expand_more_rounded,
                  size: 15,
                  color: AppColors.text3,
                ),
                items: [
                  for (var index = 0; index < records.length; index++)
                    DropdownMenuItem<int>(
                      value: index,
                      child: Text(
                        _labelFor(records[index]),
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
                ],
                onChanged: (index) {
                  if (index != null) {
                    onSelect(index);
                  }
                },
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _labelFor(CurrencyRecord record) {
    final time = record.collectedAt;
    return time == null
        ? (record.collectedAtText ?? '--')
        : format.format(time);
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
