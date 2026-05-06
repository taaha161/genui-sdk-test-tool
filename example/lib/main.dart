import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_devtools/genui_devtools.dart';

void main() {
  runApp(const GenUiDemoApp());
}

class GenUiDemoApp extends StatelessWidget {
  const GenUiDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GenUI DevTools Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SurfaceSimulatorPage(),
    );
  }
}

class SurfaceSimulatorPage extends StatefulWidget {
  const SurfaceSimulatorPage({super.key});

  @override
  State<SurfaceSimulatorPage> createState() => _SurfaceSimulatorPageState();
}

class _SurfaceSimulatorPageState extends State<SurfaceSimulatorPage> {
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final Conversation _conversation;

  final List<String> _surfaceIds = [];
  // Log of UiEvents received via the 'greet' action (or any injected userAction).
  final List<_ActionRecord> _actionLog = [];

  @override
  void initState() {
    super.initState();

    _controller = SurfaceController(
      catalogs: [BasicCatalogItems.asCatalog()],
    );

    // No real LLM — the transport is a stub. Use the GenUI DevTools tab in
    // Flutter DevTools to inject messages and bypass the model entirely.
    _transport = A2uiTransportAdapter(
      onSend: (_) async {},
    );

    _conversation = Conversation(
      controller: _controller,
      transport: _transport,
    );

    _conversation.events.listen((event) {
      if (event is ConversationSurfaceAdded) {
        setState(() => _surfaceIds.add(event.surfaceId));
      } else if (event is ConversationSurfaceRemoved) {
        setState(() => _surfaceIds.remove(event.surfaceId));
      }
    });

    if (kDebugMode) {
      registerGenUiDevToolsExtensions(
        _controller,
        onUserAction: _onUserAction,
      );
    }
  }

  void _onUserAction(UiEvent event) {
    _controller.handleUiEvent(event);

    if (event is UserActionEvent) {
      if (event.name == 'greet') {
        final name = (event.context['name-field'] as String?)?.trim();
        final greeting =
            (name != null && name.isNotEmpty) ? 'Hello, $name!' : 'Hello!';
        _controller.handleMessage(
          A2uiMessage.fromJson({
            'version': 'v0.9',
            'updateDataModel': {
              'surfaceId': event.surfaceId,
              'path': '/greeting',
              'value': greeting,
            },
          }),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Button tapped — greeting updated to "$greeting"'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Action "${event.name}" received from ${event.sourceComponentId}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      setState(() {
        _actionLog.insert(
          0,
          _ActionRecord(
            name: event.name,
            sourceComponentId: event.sourceComponentId,
            surfaceId: event.surfaceId,
            timestamp: DateTime.now(),
          ),
        );
        if (_actionLog.length > 20) _actionLog.removeLast();
      });
      debugPrint('[GenUI] userAction received: ${jsonEncode(event.toMap())}');
    }
  }

  @override
  void dispose() {
    _conversation.dispose();
    _transport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GenUI Surface Simulator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_surfaceIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear all surfaces',
              onPressed: () {
                for (final id in List.of(_surfaceIds)) {
                  _controller.handleMessage(
                    A2uiMessage.fromJson({
                      'version': 'v0.9',
                      'deleteSurface': {'surfaceId': id},
                    }),
                  );
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _surfaceIds.isEmpty
                ? _buildEmptyState(context)
                : _buildSurfaces(),
          ),
          if (_actionLog.isNotEmpty) _buildActionLog(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.developer_board_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No surfaces yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Open Flutter DevTools → GenUI DevTools tab\n'
            'and inject messages in this order:',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 20),
          _buildFlowHint(context),
        ],
      ),
    );
  }

  Widget _buildFlowHint(BuildContext context) {
    final steps = [
      ('1', 'createSurface', 'surface "demo" appears'),
      ('2', 'updateComponents', 'form renders with bound fields'),
      ('3', 'updateDataModel  /greeting', 'greeting text updates live'),
      ('4', 'userAction  greet', 'action appears in the log below'),
      ('5', 'deleteSurface', 'surface disappears'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps
            .map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        s.$1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: s.$2,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            TextSpan(text: '  → ${s.$3}'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSurfaces() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _surfaceIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final id = _surfaceIds[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Surface: $id',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      tooltip: 'Delete surface',
                      onPressed: () => _controller.handleMessage(
                        A2uiMessage.fromJson({
                          'version': 'v0.9',
                          'deleteSurface': {'surfaceId': id},
                        }),
                      ),
                    ),
                  ],
                ),
                Surface(
                  surfaceContext: _controller.contextFor(id),
                  defaultBuilder: (_) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Waiting for components — send updateComponents next.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionLog(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.bolt, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Received user actions',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() => _actionLog.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _actionLog.length,
              itemBuilder: (context, i) {
                final record = _actionLog[i];
                final time =
                    '${record.timestamp.hour.toString().padLeft(2, '0')}:'
                    '${record.timestamp.minute.toString().padLeft(2, '0')}:'
                    '${record.timestamp.second.toString().padLeft(2, '0')}';
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Text(
                    '$time  action=${record.name}  '
                    'source=${record.sourceComponentId}  '
                    'surface=${record.surfaceId}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRecord {
  const _ActionRecord({
    required this.name,
    required this.sourceComponentId,
    required this.surfaceId,
    required this.timestamp,
  });

  final String name;
  final String sourceComponentId;
  final String surfaceId;
  final DateTime timestamp;
}
