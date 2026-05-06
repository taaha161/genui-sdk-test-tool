import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'extension_panel.dart';

void main() {
  runApp(const GenUiDevToolsExtension());
}

class GenUiDevToolsExtension extends StatelessWidget {
  const GenUiDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: ExtensionPanel(),
    );
  }
}
