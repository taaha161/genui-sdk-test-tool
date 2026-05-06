import 'dart:convert';

import 'component_specs.dart';

/// Parses a catalog JSON string (the standard_catalog.json / basic_catalog.json
/// format) into a list of [ComponentSpec] entries usable by the palette.
///
/// Returns null if the JSON is invalid or missing the 'components' key.
List<ComponentSpec>? parseCatalogJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;

    final components = decoded['components'];
    if (components is! Map) return null;

    final specs = <ComponentSpec>[];
    for (final entry in components.entries) {
      final type = entry.key as String;
      final def = entry.value;
      if (def is! Map) continue;
      specs.add(_parseSpec(type, Map<String, Object?>.from(def)));
    }
    return specs.isEmpty ? null : specs;
  } catch (_) {
    return null;
  }
}

ComponentSpec _parseSpec(String type, Map<String, Object?> def) {
  // The component-specific schema is typically the last item in allOf.
  final allOf = def['allOf'];
  final specificSchema = (allOf is List && allOf.isNotEmpty)
      ? Map<String, Object?>.from(allOf.last as Map)
      : def;

  final rawProps = specificSchema['properties'];
  final properties = rawProps is Map
      ? Map<String, Object?>.from(rawProps)
      : <String, Object?>{};
  properties.remove('component');

  final rawRequired = specificSchema['required'];
  final required = rawRequired is List
      ? rawRequired.cast<String>().toSet()
      : <String>{};
  required.remove('component');

  // Infer slot kind from structural props.
  final SlotKind slotKind;
  if (properties.containsKey('children') || properties.containsKey('tabs')) {
    slotKind = SlotKind.multiChild;
  } else if (properties.containsKey('child') ||
      (properties.containsKey('trigger') &&
          properties.containsKey('content'))) {
    slotKind = SlotKind.singleChild;
  } else {
    slotKind = SlotKind.none;
  }

  // Remove slot props — they're managed by the drop zone UI, not prop fields.
  properties
    ..remove('children')
    ..remove('child')
    ..remove('tabs')
    ..remove('trigger')
    ..remove('content');

  final props = <PropSpec>[];
  for (final propEntry in properties.entries) {
    final key = propEntry.key;
    if (key == 'id') continue;

    final schema = propEntry.value is Map
        ? Map<String, Object?>.from(propEntry.value as Map)
        : <String, Object?>{};

    final enumValues = (schema['enum'] as List?)?.cast<String>();
    if (enumValues != null && enumValues.isNotEmpty) {
      props.add(PropSpec(key, options: enumValues));
    } else {
      final ref = schema[r'$ref'] as String? ?? '';
      final isPath = ref.contains('Dynamic') || _hasDynamicOneOf(schema);
      props.add(PropSpec(
        key,
        hint: required.contains(key) ? 'required' : '',
        isPath: isPath,
      ));
    }
  }

  final color = _colorFor(type, slotKind);
  return ComponentSpec(type, slotKind, props, color: color);
}

bool _hasDynamicOneOf(Map<String, Object?> schema) {
  final oneOf = schema['oneOf'];
  if (oneOf is! List) return false;
  return oneOf.any((item) {
    if (item is! Map) return false;
    final ref = item[r'$ref'] as String? ?? '';
    return ref.contains('Dynamic');
  });
}

int _colorFor(String type, SlotKind slot) {
  // Reuse the same colors as the built-in specs where possible, so imported
  // components from the basic catalog look consistent.
  const known = {
    'Column': 0xFF5C6BC0,
    'Row': 0xFF7E57C2,
    'Card': 0xFF26A69A,
    'Text': 0xFF42A5F5,
    'Button': 0xFFEF5350,
    'TextField': 0xFF66BB6A,
    'CheckBox': 0xFFFF7043,
    'Slider': 0xFFAB47BC,
    'DateTimeInput': 0xFF26C6DA,
    'Image': 0xFF8D6E63,
    'Icon': 0xFFFFCA28,
    'ChoicePicker': 0xFF78909C,
    'Divider': 0xFF90A4AE,
    'List': 0xFF3949AB,
    'Tabs': 0xFF00897B,
    'Modal': 0xFFE53935,
    'AudioPlayer': 0xFF6D4C41,
    'Video': 0xFF546E7A,
  };
  if (known.containsKey(type)) return known[type]!;
  return switch (slot) {
    SlotKind.multiChild => 0xFF5C6BC0,
    SlotKind.singleChild => 0xFF26A69A,
    SlotKind.none => 0xFF78909C,
  };
}
