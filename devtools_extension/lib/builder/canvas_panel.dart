import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'block_widget.dart';
import 'builder_model.dart';
import 'component_specs.dart';
import 'json_serializer.dart';

class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    super.key,
    required this.model,
    required this.surfaceIdCtrl,
    required this.onInject,
  });

  final BuilderModel model;
  final TextEditingController surfaceIdCtrl;
  final void Function(Map<String, Object?>) onInject;

  Map<String, Object?> _buildPayload() {
    return {
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': surfaceIdCtrl.text.trim(),
        'components': serializeTree(model.root!),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context),
          Expanded(
            child: model.root == null
                ? _buildEmptyState(context)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: BlockWidget(
                      key: ValueKey(model.root!.id),
                      node: model.root!,
                      model: model,
                      spec: specFor(model.root!.type)!,
                    ),
                  ),
          ),
          if (model.root != null) _buildJsonPreview(context),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final canInject = model.root != null &&
        surfaceIdCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: TextField(
              controller: surfaceIdCtrl,
              decoration: const InputDecoration(
                labelText: 'surfaceId',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: canInject ? () => onInject(_buildPayload()) : null,
            icon: const Icon(Icons.send, size: 14),
            label: const Text('Inject'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          if (model.root != null)
            TextButton(
              onPressed: model.clear,
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        model.setRoot(ComponentNode(details.data));
      },
      builder: (context, candidateData, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: candidateData.isNotEmpty
            ? Theme.of(context).colorScheme.primary.withAlpha(15)
            : null,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.widgets_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                candidateData.isNotEmpty
                    ? 'Drop to set as root'
                    : 'Drag a component here to start',
                style: TextStyle(
                  color: candidateData.isNotEmpty
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJsonPreview(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ')
        .convert(_buildPayload());
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Generated JSON',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: json));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('JSON copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Copy', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: SelectableText(
                json,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
