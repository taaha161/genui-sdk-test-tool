import 'dart:convert';

import 'package:flutter/material.dart';

import '../history/history_model.dart';
import '../templates/message_templates.dart';
import '../vm_service_bridge.dart';
import 'form_fields.dart';
import 'json_editor.dart';

class ComposerView extends StatefulWidget {
  const ComposerView({
    super.key,
    required this.bridge,
    required this.historyModel,
  });

  final VmServiceBridge bridge;
  final HistoryModel historyModel;

  @override
  State<ComposerView> createState() => _ComposerViewState();
}

class _ComposerViewState extends State<ComposerView> {
  MessageType _selectedType = MessageType.createSurface;
  bool _rawMode = false;
  String? _jsonError;

  final _surfaceIdCtrl = TextEditingController(text: 'demo');
  final _catalogIdCtrl = TextEditingController(
    text: 'https://a2ui.org/specification/v0_9/basic_catalog.json',
  );
  final _pathCtrl = TextEditingController(text: '/greeting');
  final _valueCtrl = TextEditingController(text: 'Hello from DevTools!');
  final _actionNameCtrl = TextEditingController(text: 'greet');
  final _sourceComponentIdCtrl = TextEditingController(text: 'submit-btn');
  final _rawJsonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _syncRawFromTemplate();
    _selectedType.name; // no-op, keeps lint happy
    for (final c in _allControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _allControllers => [
        _surfaceIdCtrl,
        _catalogIdCtrl,
        _pathCtrl,
        _valueCtrl,
        _actionNameCtrl,
        _sourceComponentIdCtrl,
        _rawJsonCtrl,
      ];

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  void _onTypeChanged(MessageType? type) {
    if (type == null) return;
    setState(() {
      _selectedType = type;
      _syncRawFromTemplate();
    });
  }

  void _syncRawFromTemplate() {
    final payload = _buildPayload();
    _rawJsonCtrl.text =
        const JsonEncoder.withIndent('  ').convert(payload);
  }

  Map<String, Object?> _buildPayload() => switch (_selectedType) {
        MessageType.createSurface => MessageTemplates.createSurface(
            surfaceId: _surfaceIdCtrl.text.trim(),
            catalogId: _catalogIdCtrl.text.trim(),
          ),
        MessageType.updateComponents => MessageTemplates.updateComponents(
            surfaceId: _surfaceIdCtrl.text.trim(),
          ),
        MessageType.updateDataModel => MessageTemplates.updateDataModel(
            surfaceId: _surfaceIdCtrl.text.trim(),
            path: _pathCtrl.text.trim(),
            value: _valueCtrl.text.trim(),
          ),
        MessageType.deleteSurface => MessageTemplates.deleteSurface(
            surfaceId: _surfaceIdCtrl.text.trim(),
          ),
        MessageType.userAction => MessageTemplates.userAction(
            name: _actionNameCtrl.text.trim(),
            sourceComponentId: _sourceComponentIdCtrl.text.trim(),
            surfaceId: _surfaceIdCtrl.text.trim(),
          ),
      };

  bool get _canSend {
    if (_rawMode) {
      return _rawJsonCtrl.text.trim().isNotEmpty;
    }
    return switch (_selectedType) {
      MessageType.createSurface =>
        _surfaceIdCtrl.text.trim().isNotEmpty &&
            _catalogIdCtrl.text.trim().isNotEmpty,
      MessageType.updateComponents => _surfaceIdCtrl.text.trim().isNotEmpty,
      MessageType.updateDataModel =>
        _surfaceIdCtrl.text.trim().isNotEmpty &&
            _pathCtrl.text.trim().isNotEmpty,
      MessageType.deleteSurface => _surfaceIdCtrl.text.trim().isNotEmpty,
      MessageType.userAction =>
        _actionNameCtrl.text.trim().isNotEmpty &&
            _sourceComponentIdCtrl.text.trim().isNotEmpty,
    };
  }

  Future<void> _send() async {
    Map<String, Object?> payload;
    if (_rawMode) {
      try {
        payload = jsonDecode(_rawJsonCtrl.text) as Map<String, Object?>;
      } catch (e) {
        setState(() => _jsonError = 'Invalid JSON: $e');
        return;
      }
    } else {
      payload = _buildPayload();
    }

    setState(() => _jsonError = null);

    widget.historyModel.add(SentMessage(
      timestamp: DateTime.now(),
      type: _selectedType.label,
      payload: payload,
    ));

    try {
      if (_selectedType.isUserAction) {
        await widget.bridge.injectUserAction(payload);
      } else {
        await widget.bridge.injectA2uiMessage(payload);
      }
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
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Message type',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<MessageType>(
                      key: const Key('messageTypeDropdown'),
                      value: _selectedType,
                      isDense: true,
                      isExpanded: true,
                      items: MessageType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ),
                          )
                          .toList(),
                      onChanged: _onTypeChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Text('Raw JSON'),
                  Switch(
                    value: _rawMode,
                    onChanged: (v) => setState(() => _rawMode = v),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _rawMode ? _buildRawEditor() : _buildFormFields(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('sendButton'),
            onPressed: _canSend ? _send : null,
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildRawEditor() {
    return JsonEditor(
      controller: _rawJsonCtrl,
      errorText: _jsonError,
    );
  }

  Widget _buildFormFields() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_selectedType != MessageType.userAction) ...[
            LabeledField(
              label: 'surfaceId',
              fieldKey: const Key('surfaceIdField'),
              controller: _surfaceIdCtrl,
              hint: 'my-surface',
            ),
          ],
          if (_selectedType == MessageType.createSurface)
            LabeledField(
              label: 'catalogId',
              fieldKey: const Key('catalogIdField'),
              controller: _catalogIdCtrl,
              hint: 'https://a2ui.org/specification/v0_9/basic_catalog.json',
            ),
          if (_selectedType == MessageType.updateDataModel) ...[
            LabeledField(
              label: 'path',
              fieldKey: const Key('dataPathField'),
              controller: _pathCtrl,
              hint: '/key',
            ),
            LabeledField(
              label: 'value (JSON)',
              fieldKey: const Key('dataValueField'),
              controller: _valueCtrl,
              hint: '"some value"',
            ),
          ],
          if (_selectedType == MessageType.userAction) ...[
            LabeledField(
              label: 'surfaceId',
              fieldKey: const Key('surfaceIdField'),
              controller: _surfaceIdCtrl,
              hint: 'my-surface',
            ),
            LabeledField(
              label: 'action name',
              fieldKey: const Key('actionNameField'),
              controller: _actionNameCtrl,
              hint: 'confirmBooking',
            ),
            LabeledField(
              label: 'sourceComponentId',
              fieldKey: const Key('sourceComponentIdField'),
              controller: _sourceComponentIdCtrl,
              hint: 'btn',
            ),
          ],
        ],
      ),
    );
  }
}
