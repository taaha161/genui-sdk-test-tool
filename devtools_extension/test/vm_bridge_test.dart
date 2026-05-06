import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui_devtools_extension/vm_service_bridge.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vm_service/vm_service.dart';

class _MockVmService extends Mock implements VmService {}

void main() {
  late _MockVmService service;
  late VmServiceBridge bridge;

  const testIsolateId = 'isolates/1';

  setUp(() {
    service = _MockVmService();
    bridge = VmServiceBridge(
      serviceProvider: () => service,
      isolateIdProvider: () => testIsolateId,
    );

    when(
      () => service.callServiceExtension(
        any(),
        isolateId: any(named: 'isolateId'),
        args: any(named: 'args'),
      ),
    ).thenAnswer((_) async => Response());
  });

  test('injectA2uiMessage forwards the encoded payload', () async {
    final message = {
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'test',
        'catalogId': 'test-catalog',
      },
    };

    await bridge.injectA2uiMessage(message);

    verify(
      () => service.callServiceExtension(
        'ext.genui.injectA2uiMessage',
        isolateId: testIsolateId,
        args: {'message': jsonEncode(message)},
      ),
    ).called(1);
  });

  test('injectUserAction forwards the encoded payload', () async {
    final event = {
      'name': 'tap',
      'sourceComponentId': 'btn',
      'surfaceId': 'test',
    };

    await bridge.injectUserAction(event);

    verify(
      () => service.callServiceExtension(
        'ext.genui.injectUserAction',
        isolateId: testIsolateId,
        args: {'event': jsonEncode(event)},
      ),
    ).called(1);
  });

  test('returns null when the service is unavailable', () async {
    final disconnected = VmServiceBridge(
      serviceProvider: () => null,
      isolateIdProvider: () => testIsolateId,
    );

    final result = await disconnected.injectA2uiMessage({
      'version': 'v0.9',
      'createSurface': {'surfaceId': 'x', 'catalogId': 'y'},
    });

    expect(result, isNull);
    verifyNever(
      () => service.callServiceExtension(
        any(),
        isolateId: any(named: 'isolateId'),
        args: any(named: 'args'),
      ),
    );
  });

  test('returns null when the isolate id is unavailable', () async {
    final noIsolate = VmServiceBridge(
      serviceProvider: () => service,
      isolateIdProvider: () => null,
    );

    final result = await noIsolate.injectA2uiMessage({'version': 'v0.9'});

    expect(result, isNull);
    verifyNever(
      () => service.callServiceExtension(
        any(),
        isolateId: any(named: 'isolateId'),
        args: any(named: 'args'),
      ),
    );
  });
}
