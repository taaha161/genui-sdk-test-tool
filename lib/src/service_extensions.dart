import 'dart:convert';
import 'dart:developer';

import 'package:genui/genui.dart';

const _injectMessageExt = 'ext.genui.injectA2uiMessage';
const _injectUserActionExt = 'ext.genui.injectUserAction';

/// Registers the GenUI DevTools service extensions against the given sink and
/// event handler. Call once during app startup, gated by `kDebugMode`.
///
/// [sink] is typically your `SurfaceController` instance, but any
/// `A2uiMessageSink` works.
///
/// [onUserAction] is the function the simulator calls to inject a synthetic
/// user action. For most apps this is `controller.handleUiEvent`.
void registerGenUiDevToolsExtensions(
  A2uiMessageSink sink, {
  void Function(UiEvent event)? onUserAction,
}) {
  registerExtension(_injectMessageExt, (method, params) async {
    return handleInjectA2uiMessage(sink, params);
  });

  registerExtension(_injectUserActionExt, (method, params) async {
    return handleInjectUserAction(onUserAction, params);
  });
}

/// Top-level handler for `ext.genui.injectA2uiMessage`. Exposed for testing.
Future<ServiceExtensionResponse> handleInjectA2uiMessage(
  A2uiMessageSink sink,
  Map<String, String> params,
) async {
  try {
    final raw = params['message'];
    if (raw == null || raw.isEmpty) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        'Missing required param: message',
      );
    }
    final json = jsonDecode(raw) as Map<String, Object?>;
    final message = A2uiMessage.fromJson(json);
    sink.handleMessage(message);
    return ServiceExtensionResponse.result('{"status":"ok"}');
  } catch (e, st) {
    return ServiceExtensionResponse.error(
      ServiceExtensionResponse.extensionError,
      'Failed to inject A2uiMessage: $e\n$st',
    );
  }
}

/// Top-level handler for `ext.genui.injectUserAction`. Exposed for testing.
Future<ServiceExtensionResponse> handleInjectUserAction(
  void Function(UiEvent event)? onUserAction,
  Map<String, String> params,
) async {
  if (onUserAction == null) {
    return ServiceExtensionResponse.error(
      ServiceExtensionResponse.extensionError,
      'No onUserAction handler registered. Pass one to '
      'registerGenUiDevToolsExtensions to enable user-action injection.',
    );
  }
  try {
    final raw = params['event'];
    if (raw == null || raw.isEmpty) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        'Missing required param: event',
      );
    }
    final json = jsonDecode(raw) as Map<String, Object?>;
    final event = UserActionEvent.fromMap(json);
    onUserAction(event);
    return ServiceExtensionResponse.result('{"status":"ok"}');
  } catch (e, st) {
    return ServiceExtensionResponse.error(
      ServiceExtensionResponse.extensionError,
      'Failed to inject UserActionEvent: $e\n$st',
    );
  }
}
