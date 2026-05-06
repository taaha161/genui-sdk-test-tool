import 'package:devtools_app_shared/ui.dart' show SplitPane;
import 'package:devtools_extensions/devtools_extensions.dart'
    show serviceManager;
import 'package:flutter/material.dart';

import 'builder/builder_tab.dart';
import 'composer/composer_view.dart';
import 'history/history_model.dart';
import 'history/history_view.dart';
import 'vm_service_bridge.dart';

class ExtensionPanel extends StatefulWidget {
  const ExtensionPanel({super.key});

  @override
  State<ExtensionPanel> createState() => _ExtensionPanelState();
}

class _ExtensionPanelState extends State<ExtensionPanel>
    with SingleTickerProviderStateMixin {
  late final VmServiceBridge _bridge;
  late final HistoryModel _historyModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _bridge = VmServiceBridge(
      serviceProvider: () => serviceManager.service,
      isolateIdProvider: () =>
          serviceManager.isolateManager.mainIsolate.value?.id,
    );
    _historyModel = HistoryModel();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _historyModel.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SplitPane(
      axis: Axis.horizontal,
      initialFractions: const [0.6, 0.4],
      children: [
        Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Composer'),
                Tab(text: 'Builder'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ComposerView(bridge: _bridge, historyModel: _historyModel),
                  BuilderTab(bridge: _bridge, historyModel: _historyModel),
                ],
              ),
            ),
          ],
        ),
        HistoryView(historyModel: _historyModel, bridge: _bridge),
      ],
    );
  }
}
