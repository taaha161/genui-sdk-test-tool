import 'package:flutter/material.dart';

import 'catalog_parser.dart';
import 'component_specs.dart';

/// Shows an import dialog and returns the parsed [ComponentSpec] list, or null
/// if the user cancelled or the JSON was invalid.
Future<List<ComponentSpec>?> showImportCatalogDialog(
  BuildContext context,
) {
  return showDialog<List<ComponentSpec>>(
    context: context,
    builder: (_) => const _ImportCatalogDialog(),
  );
}

class _ImportCatalogDialog extends StatefulWidget {
  const _ImportCatalogDialog();

  @override
  State<_ImportCatalogDialog> createState() => _ImportCatalogDialogState();
}

class _ImportCatalogDialogState extends State<_ImportCatalogDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _import() {
    final specs = parseCatalogJson(_ctrl.text.trim());
    if (specs == null) {
      setState(() => _error =
          'Invalid catalog JSON. Paste the full contents of a catalog spec file '
          '(must have a top-level "components" object).');
      return;
    }
    Navigator.of(context).pop(specs);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Import Catalog'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Paste a catalog JSON spec (e.g. standard_catalog.json or a custom catalog). '
              'The palette will be replaced with the components defined in it.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 14,
              decoration: InputDecoration(
                hintText: '{ "components": { "MyWidget": { ... } } }',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _ctrl.text.trim().isEmpty ? null : _import,
        child: const Text('Import'),
        ),
      ],
    );
  }
}
