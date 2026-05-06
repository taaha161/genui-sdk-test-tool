import 'builder_model.dart';
import 'component_specs.dart';

typedef JsonMap = Map<String, Object?>;

/// Walks [root] depth-first (pre-order) and returns the flat components array
/// expected by the A2UI updateComponents wire format.
///
/// The root node is always emitted with id "root" — GenUI requires it.
List<JsonMap> serializeTree(ComponentNode root) {
  final result = <JsonMap>[];
  _visit(root, result, forcedId: 'root');
  return result;
}

void _visit(ComponentNode node, List<JsonMap> out, {String? forcedId}) {
  final id = forcedId ?? node.id;
  final spec = specFor(node.type);
  final map = <String, Object?>{'id': id, 'component': node.type};

  if (spec != null) {
    for (final prop in spec.props) {
      final raw = node.props[prop.key]?.trim() ?? '';
      if (raw.isEmpty) continue;

      if (prop.isPath) {
        map[prop.key] = {'path': raw};
      } else if (prop.key == 'options') {
        map[prop.key] = raw
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (prop.key == 'action') {
        map[prop.key] = {'name': raw};
      } else if (prop.key == 'min' || prop.key == 'max') {
        map[prop.key] = num.tryParse(raw) ?? raw;
      } else {
        map[prop.key] = raw;
      }
    }

    switch (spec.slotKind) {
      case SlotKind.multiChild when node.children.isNotEmpty:
        map['children'] = node.children.map((c) => c.id).toList();
      case SlotKind.singleChild when node.child != null:
        map['child'] = node.child!.id;
      default:
        break;
    }
  }

  out.add(map);

  for (final child in node.children) {
    _visit(child, out);
  }
  if (node.child != null) _visit(node.child!, out);
}
