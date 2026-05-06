import 'dart:convert';

import 'package:flutter/material.dart';

import '../vm_service_bridge.dart';
import 'history_model.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    super.key,
    required this.historyModel,
    required this.bridge,
  });

  final HistoryModel historyModel;
  final VmServiceBridge bridge;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<SentMessage>>(
      valueListenable: historyModel,
      builder: (context, messages, _) {
        if (messages.isEmpty) {
          return const Center(child: Text('No messages sent yet.'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${messages.length} message(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: historyModel.clear,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return _MessageTile(
                    message: msg,
                    onReplay: () => _replay(context, msg),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _replay(BuildContext context, SentMessage msg) async {
    try {
      if (msg.type == 'userAction') {
        await bridge.injectUserAction(msg.payload);
      } else {
        await bridge.injectA2uiMessage(msg.payload);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Replay error: $e')),
        );
      }
    }
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, required this.onReplay});

  final SentMessage message;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}:${message.timestamp.second.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        title: Text(message.type),
        subtitle: Text(time, style: Theme.of(context).textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.replay),
              tooltip: 'Replay',
              onPressed: onReplay,
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(message.payload),
              style:
                  const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
