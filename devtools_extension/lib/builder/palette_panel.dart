import 'package:flutter/material.dart';

import 'builder_model.dart';
import 'component_specs.dart';
import 'import_catalog_dialog.dart';

class PalettePanel extends StatefulWidget {
  const PalettePanel({super.key, required this.model});

  final BuilderModel model;

  @override
  State<PalettePanel> createState() => _PalettePanelState();
}

class _PalettePanelState extends State<PalettePanel> {
  List<ComponentSpec> _specs = kComponentSpecs;
  bool _isCustom = false;

  Future<void> _importCatalog() async {
    final specs = await showImportCatalogDialog(context);
    if (specs != null) {
      setState(() {
        _specs = specs;
        _isCustom = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              children: _specs
                  .map((spec) => _PaletteTile(spec: spec))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isCustom ? 'Custom catalog' : 'Components',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (_isCustom)
            IconButton(
              icon: const Icon(Icons.refresh, size: 14),
              tooltip: 'Reset to default catalog',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() {
                _specs = kComponentSpecs;
                _isCustom = false;
              }),
            ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined, size: 14),
            tooltip: 'Import catalog',
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
            onPressed: _importCatalog,
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.spec});

  final ComponentSpec spec;

  @override
  Widget build(BuildContext context) {
    final color = Color(spec.color);
    final chip = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              spec.type,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (spec.slotKind == SlotKind.multiChild)
            const Icon(Icons.account_tree_outlined,
                size: 12, color: Colors.white70),
          if (spec.slotKind == SlotKind.singleChild)
            const Icon(Icons.subdirectory_arrow_right,
                size: 12, color: Colors.white70),
        ],
      ),
    );

    return Draggable<String>(
      data: spec.type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.85,
          child: SizedBox(width: 128, child: chip),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: chip),
      child: chip,
    );
  }
}
