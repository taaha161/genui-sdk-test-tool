import 'package:devtools_app_shared/ui.dart' show SplitPane;
import 'package:devtools_extensions/devtools_extensions.dart'
    show serviceManager;
import 'package:flutter/material.dart';

import 'composer/composer_view.dart';
import 'history/history_model.dart';
import 'history/history_view.dart';
import 'vm_service_bridge.dart';

class ExtensionPanel extends StatefulWidget {
  const ExtensionPanel({super.key});

  @override
  State<ExtensionPanel> createState() => _ExtensionPanelState();
}

class _ExtensionPanelState extends State<ExtensionPanel> {
  late final VmServiceBridge _bridge;
  late final HistoryModel _historyModel;

  @override
  void initState() {
    super.initState();
    _bridge = VmServiceBridge(
      serviceProvider: () => serviceManager.service,
      isolateIdProvider: () =>
          serviceManager.isolateManager.mainIsolate.value?.id,
    );
    _historyModel = HistoryModel();
  }

  @override
  void dispose() {
    _historyModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SplitPane(
      axis: Axis.horizontal,
      initialFractions: const [0.6, 0.4],
      children: [
        ComposerView(bridge: _bridge, historyModel: _historyModel),
        HistoryView(historyModel: _historyModel, bridge: _bridge),
      ],
    );
  }
}
