/// Defensive JSON coercion.
///
/// The backend returns bare dicts, so a field typed `number` in OpenAPI arrives
/// as an `int` when it happens to be whole (`0`) and a `double` otherwise
/// (`14.32`). A plain `json['x'] as double` throws on the int case, so every
/// read goes through these helpers.
library;

double? asDoubleOrNull(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s),
  _ => null,
};

double asDouble(Object? v, [double fallback = 0]) =>
    asDoubleOrNull(v) ?? fallback;

int? asIntOrNull(Object? v) => switch (v) {
  int i => i,
  num n => n.round(),
  String s => int.tryParse(s) ?? double.tryParse(s)?.round(),
  _ => null,
};

int asInt(Object? v, [int fallback = 0]) => asIntOrNull(v) ?? fallback;

String asString(Object? v, [String fallback = '']) =>
    v == null ? fallback : (v is String ? v : v.toString());

bool asBool(Object? v, [bool fallback = false]) => switch (v) {
  bool b => b,
  num n => n != 0,
  String s => s.toLowerCase() == 'true',
  _ => fallback,
};

List<String> asStringList(Object? v) => v is List
    ? v.map(asString).where((s) => s.isNotEmpty).toList(growable: false)
    : const [];

List<Map<String, dynamic>> asMapList(Object? v) => v is List
    ? v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false)
    : const [];

Map<String, dynamic>? asMapOrNull(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

DateTime? asDate(Object? v) => v is String ? DateTime.tryParse(v) : null;
