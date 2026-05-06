import 'dart:convert';

import 'package:vm_service/vm_service.dart';

typedef VmServiceProvider = VmService? Function();
typedef IsolateIdProvider = String? Function();

class VmServiceBridge {
  VmServiceBridge({
    required VmServiceProvider serviceProvider,
    required IsolateIdProvider isolateIdProvider,
  })  : _serviceProvider = serviceProvider,
        _isolateIdProvider = isolateIdProvider;

  final VmServiceProvider _serviceProvider;
  final IsolateIdProvider _isolateIdProvider;

  Future<Response?> injectA2uiMessage(Map<String, Object?> message) {
    return _call(
      'ext.genui.injectA2uiMessage',
      {'message': jsonEncode(message)},
    );
  }

  Future<Response?> injectUserAction(Map<String, Object?> event) {
    return _call(
      'ext.genui.injectUserAction',
      {'event': jsonEncode(event)},
    );
  }

  Future<Response?> _call(String method, Map<String, String> args) async {
    final service = _serviceProvider();
    if (service == null) return null;

    final isolateId = _isolateIdProvider();
    if (isolateId == null) return null;

    return service.callServiceExtension(
      method,
      isolateId: isolateId,
      args: args,
    );
  }
}
