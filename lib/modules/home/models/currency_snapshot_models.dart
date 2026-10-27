/// Models for the currency (asset) snapshot exposed by OAS.
///
/// The payload is produced by `tasks/CurrencySnapshot` and served by
/// `GET /currency/latest`, so every field is optional except the entry list.
class CurrencySnapshot {
  /// Creates a currency snapshot.
  const CurrencySnapshot({
    required this.entries,
    this.collectedAt,
    this.fileMtime,
    this.ageSeconds,
    this.playerName,
    this.playerLevel,
    this.playerServerId,
    this.platform,
    this.error,
  });

  /// Assets in the server-provided display order.
  final List<CurrencyEntry> entries;

  /// Timestamp of the in-game collection, if the payload reported one.
  final DateTime? collectedAt;

  /// Fallback timestamp taken from the snapshot file mtime.
  final DateTime? fileMtime;

  /// Seconds elapsed since the snapshot file was written.
  final int? ageSeconds;

  /// In-game player name.
  final String? playerName;

  /// In-game player level.
  final int? playerLevel;

  /// In-game server id.
  final int? playerServerId;

  /// Platform label reported by the collector (e.g. `mumu-android`).
  final String? platform;

  /// Collector error message, when the last run failed.
  final String? error;

  /// Returns the best-known collection time.
  DateTime? get displayTime => collectedAt ?? fileMtime;

  /// Builds a snapshot from the `GET /currency/latest` payload.
  factory CurrencySnapshot.fromJson(Map<String, dynamic> json) {
    final values = _asIntMap(json['values']);
    final labels = _asStringMap(json['labels']);
    final items = json['items'] is Map
        ? Map<String, dynamic>.from(json['items'] as Map)
        : const <String, dynamic>{};
    final order = json['order'] is List
        ? (json['order'] as List).map((e) => e.toString()).toList(growable: false)
        : values.keys.toList(growable: false);
    final player = json['player'] is Map
        ? Map<String, dynamic>.from(json['player'] as Map)
        : const <String, dynamic>{};
    final file = json['file'] is Map
        ? Map<String, dynamic>.from(json['file'] as Map)
        : const <String, dynamic>{};

    final entries = <CurrencyEntry>[];
    for (final key in order) {
      final count = values[key];
      if (count == null) {
        continue;
      }
      final item = items[key];
      entries.add(
        CurrencyEntry(
          key: key,
          label: labels[key] ?? key,
          count: count,
          itemId: item is Map ? item['id']?.toString() : null,
        ),
      );
    }

    return CurrencySnapshot(
      entries: entries,
      collectedAt: _asDateTime(json['collected_at']),
      fileMtime: _asDateTime(file['mtime']),
      ageSeconds: _asInt(file['age_seconds']),
      playerName: player['name']?.toString(),
      playerLevel: _asInt(player['level']),
      playerServerId: _asInt(player['serverid']),
      platform: json['platform']?.toString(),
      error: json['error']?.toString(),
    );
  }
}

/// One asset row (勾玉 / 体力 / 金币 ...).
class CurrencyEntry {
  /// Creates one asset row.
  const CurrencyEntry({
    required this.key,
    required this.label,
    required this.count,
    this.itemId,
  });

  /// Stable key from the payload (e.g. `jade`).
  final String key;

  /// Localized label from the payload (e.g. `勾玉`).
  final String label;

  /// Current amount.
  final int count;

  /// In-game item id, when the payload reported one.
  final String? itemId;
}

Map<String, int> _asIntMap(dynamic source) {
  final result = <String, int>{};
  if (source is! Map) {
    return result;
  }
  source.forEach((key, value) {
    final parsed = _asInt(value);
    if (parsed != null) {
      result[key.toString()] = parsed;
    }
  });
  return result;
}

Map<String, String> _asStringMap(dynamic source) {
  final result = <String, String>{};
  if (source is! Map) {
    return result;
  }
  source.forEach((key, value) {
    if (value != null) {
      result[key.toString()] = value.toString();
    }
  });
  return result;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text) ?? DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

/// Snapshot history served by `GET /currency/history`.
///
/// Records arrive newest first, so `records[index + 1]` is the previous
/// collection used to compute the day-over-day delta.
class CurrencyHistory {
  const CurrencyHistory({
    required this.order,
    required this.labels,
    required this.records,
  });

  /// Stable field order from the collector.
  final List<String> order;

  /// Localized labels keyed by field name.
  final Map<String, String> labels;

  /// Snapshots, newest first.
  final List<CurrencyRecord> records;

  factory CurrencyHistory.fromJson(Map<String, dynamic> json) {
    final labels = _asStringMap(json['labels']);
    final rawRecords = json['records'];
    final records = <CurrencyRecord>[];
    if (rawRecords is List) {
      for (final item in rawRecords) {
        if (item is Map) {
          records.add(
            CurrencyRecord.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return CurrencyHistory(
      order: json['order'] is List
          ? (json['order'] as List)
                .map((e) => e.toString())
                .toList(growable: false)
          : const [],
      labels: labels,
      records: records,
    );
  }
}

/// One collected snapshot inside [CurrencyHistory].
class CurrencyRecord {
  const CurrencyRecord({
    required this.values,
    this.collectedAt,
    this.collectedAtText,
    this.playerName,
    this.playerLevel,
  });

  /// Asset amounts keyed by field name.
  final Map<String, int> values;

  /// Parsed collection timestamp.
  final DateTime? collectedAt;

  /// Raw timestamp text, used when parsing fails.
  final String? collectedAtText;

  /// Player name reported with the snapshot.
  final String? playerName;

  /// Player level reported with the snapshot.
  final int? playerLevel;

  factory CurrencyRecord.fromJson(Map<String, dynamic> json) {
    final player = json['player'] is Map
        ? Map<String, dynamic>.from(json['player'] as Map)
        : const <String, dynamic>{};
    final rawText = json['collected_at']?.toString();
    return CurrencyRecord(
      values: _asIntMap(json['values']),
      collectedAt: _asDateTime(rawText),
      collectedAtText: rawText,
      playerName: player['name']?.toString(),
      playerLevel: _asInt(player['level']),
    );
  }

  /// Amount of [key] in this snapshot.
  int amountOf(String key) => values[key] ?? 0;
}
