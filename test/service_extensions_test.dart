import 'dart:convert';
import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:genui_devtools/src/service_extensions.dart';
import 'package:mocktail/mocktail.dart';

class _MockSink extends Mock implements A2uiMessageSink {}

void main() {
  late _MockSink sink;
  late List<UiEvent> capturedEvents;

  setUpAll(() {
    registerFallbackValue(
      A2uiMessage.fromJson({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'fallback',
          'catalogId': 'fallback-catalog',
        },
      }),
    );
  });

  setUp(() {
    sink = _MockSink();
    capturedEvents = [];
  });

  group('handleInjectA2uiMessage', () {
    test('routes a valid createSurface message to the sink', () async {
      final payload = jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'test-surface',
          'catalogId': 'test-catalog',
        },
      });

      final response = await handleInjectA2uiMessage(
        sink,
        {'message': payload},
      );

      expect(response.result, isNotNull);
      expect(response.errorCode, isNull);
      final captured =
          verify(() => sink.handleMessage(captureAny())).captured;
      expect(captured.single, isA<CreateSurface>());
    });

    test('routes a valid updateComponents message to the sink', () async {
      final payload = jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'test-surface',
          'components': [
            {
              'id': 'root',
              'component': 'Text',
              'text': 'Hello',
            },
          ],
        },
      });

      final response = await handleInjectA2uiMessage(
        sink,
        {'message': payload},
      );

      expect(response.result, isNotNull);
      expect(response.errorCode, isNull);
      final captured =
          verify(() => sink.handleMessage(captureAny())).captured;
      expect(captured.single, isA<UpdateComponents>());
    });

    test('returns error for malformed JSON', () async {
      final response = await handleInjectA2uiMessage(
        sink,
        {'message': 'not valid json {{{'},
      );

      expect(response.errorCode, isNotNull);
      verifyNever(() => sink.handleMessage(any()));
    });

    test('returns error when message key is missing', () async {
      final response = await handleInjectA2uiMessage(sink, {});
      expect(response.errorCode, ServiceExtensionResponse.invalidParams);
    });

    test('returns error when message is empty string', () async {
      final response = await handleInjectA2uiMessage(
        sink,
        {'message': ''},
      );
      expect(response.errorCode, ServiceExtensionResponse.invalidParams);
      verifyNever(() => sink.handleMessage(any()));
    });
  });

  group('handleInjectUserAction', () {
    test('invokes onUserAction with a parsed UserActionEvent', () async {
      final payload = jsonEncode({
        'name': 'confirmBooking',
        'surfaceId': 'test-surface',
        'sourceComponentId': 'btn-1',
        'context': {'date': '2026-06-01'},
      });

      final response = await handleInjectUserAction(
        capturedEvents.add,
        {'event': payload},
      );

      expect(response.result, isNotNull);
      expect(response.errorCode, isNull);
      expect(capturedEvents.single, isA<UserActionEvent>());
      final action = capturedEvents.single as UserActionEvent;
      expect(action.name, 'confirmBooking');
      expect(action.sourceComponentId, 'btn-1');
    });

    test('returns extensionError when onUserAction is null', () async {
      final response = await handleInjectUserAction(
        null,
        {'event': '{}'},
      );
      expect(response.errorCode, ServiceExtensionResponse.extensionError);
    });

    test('returns error when event key is missing', () async {
      final response = await handleInjectUserAction(
        capturedEvents.add,
        {},
      );
      expect(response.errorCode, ServiceExtensionResponse.invalidParams);
      expect(capturedEvents, isEmpty);
    });
  });
}
