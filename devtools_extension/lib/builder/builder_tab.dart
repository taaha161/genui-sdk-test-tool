import 'package:flutter/material.dart';

import '../history/history_model.dart';
import '../vm_service_bridge.dart';
import 'builder_model.dart';
import 'canvas_panel.dart';
import 'palette_panel.dart';

class BuilderTab extends StatefulWidget {
  const BuilderTab({
    super.key,
    required this.bridge,
    required this.historyModel,
  });

  final VmServiceBridge bridge;
  final HistoryModel historyModel;

  @override
  State<BuilderTab> createState() => _BuilderTabState();
}

class _BuilderTabState extends State<BuilderTab> {
  final _model = BuilderModel();
  final _surfaceIdCtrl = TextEditingController(text: 'demo');

  @override
  void dispose() {
    _model.dispose();
    _surfaceIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _inject(Map<String, Object?> payload) async {
    widget.historyModel.add(SentMessage(
      timestamp: DateTime.now(),
      type: 'updateComponents (builder)',
      payload: payload,
    ));
    try {
      await widget.bridge.injectA2uiMessage(payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PalettePanel(model: _model),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child: CanvasPanel(
            model: _model,
            surfaceIdCtrl: _surfaceIdCtrl,
            onInject: _inject,
          ),
        ),
      ],
    );
  }
}
