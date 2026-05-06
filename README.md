# genui_devtools

A Flutter DevTools extension for the GenUI SDK (`package:genui` v0.9.x). It lets you craft and inject `A2uiMessage` commands and user action events directly into a running Flutter app — no LLM calls needed.

## What it does

The **Surface Simulator** panel has two sections:

- **Composer** — select a message type (`createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface`, `userAction`), fill in the fields, and hit Send. A raw JSON escape hatch is always available via the toggle.
- **History** — every sent message appears here with a Replay button so you can re-fire the same payload.

Messages bypass the transport layer entirely and are injected directly at the `A2uiMessageSink.handleMessage` level, which is the same point the SDK's parser hands off to `SurfaceController`.

## Adding to your app

Add `genui_devtools` as a dev dependency in your app's `pubspec.yaml`:

```yaml
dev_dependencies:
  genui_devtools:
    path: ../genui_devtools   # or the published version once released
```

Then register the extensions during app startup, gated by `kDebugMode`:

```dart
import 'package:flutter/foundation.dart';
import 'package:genui/genui.dart';
import 'package:genui_devtools/genui_devtools.dart';

void main() {
  final controller = SurfaceController(catalogs: [...]);

  if (kDebugMode) {
    registerGenUiDevToolsExtensions(
      controller,
      onUserAction: controller.handleUiEvent,
    );
  }

  runApp(MyApp(controller: controller));
}
```

The `onUserAction` parameter is optional. Omit it if you only need to inject AI-to-UI messages and don't need to simulate user actions.

Run your app in debug mode and open Flutter DevTools. The **genui_devtools** tab appears automatically.

## Iterating on the extension UI

To work on the extension panel itself without recompiling into DevTools every time, run it in the simulated DevTools environment:

```bash
cd devtools_extension
flutter run -d chrome --dart-define=use_simulated_environment=true
```

Or use the pre-configured VS Code launch config (`devtools_extension/.vscode/launch.json`).

## Running tests

From the root package:

```bash
flutter test
```

From the extension web app:

```bash
cd devtools_extension
flutter test
```

## Rebuilding the extension

After editing the extension web app source, rebuild and copy the output:

```bash
cd devtools_extension
dart run devtools_extensions build_and_copy \
  --source=. \
  --dest=../extension/devtools
```

Then validate the config:

```bash
cd ..
dart run devtools_extensions validate --package=.
```

## Notes

- The service extensions only register in debug builds. Never ship this in a release build.
- The extension depends on `genui` v0.9.x. Users still on `package:genui_a2ui` (v0.8 protocol) are not supported in the initial release. The two packages use different runtime types and wire formats.
- The simulator never calls an LLM. Its purpose is to bypass the model entirely.
