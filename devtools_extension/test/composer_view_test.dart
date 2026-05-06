import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui_devtools_extension/composer/composer_view.dart';
import 'package:genui_devtools_extension/history/history_model.dart';
import 'package:genui_devtools_extension/vm_service_bridge.dart';
import 'package:mocktail/mocktail.dart';

class _MockBridge extends Mock implements VmServiceBridge {}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late _MockBridge bridge;
  late HistoryModel historyModel;

  setUp(() {
    bridge = _MockBridge();
    historyModel = HistoryModel();
    when(() => bridge.injectA2uiMessage(any()))
        .thenAnswer((_) async => null);
    when(() => bridge.injectUserAction(any()))
        .thenAnswer((_) async => null);
  });

  tearDown(() => historyModel.dispose());

  testWidgets('createSurface payload includes version v0.9', (tester) async {
    await tester.pumpWidget(
      _wrap(ComposerView(bridge: bridge, historyModel: historyModel)),
    );

    // The default type is createSurface, so just clear and type surfaceId.
    final surfaceField = find.byKey(const Key('surfaceIdField'));
    final catalogField = find.byKey(const Key('catalogIdField'));
    expect(surfaceField, findsOneWidget);
    expect(catalogField, findsOneWidget);

    await tester.enterText(surfaceField, 'main');
    await tester.enterText(catalogField, 'basic');
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pumpAndSettle();

    final captured =
        verify(() => bridge.injectA2uiMessage(captureAny()))
            .captured
            .single as Map<String, Object?>;
    expect(captured['version'], 'v0.9');
    expect(captured['createSurface'], isA<Map>());
  });

  testWidgets('send button is disabled when required fields are empty',
      (tester) async {
    await tester.pumpWidget(
      _wrap(ComposerView(bridge: bridge, historyModel: historyModel)),
    );

    await tester.enterText(find.byKey(const Key('surfaceIdField')), '');
    await tester.pump();

    final sendBtn = tester.widget<ElevatedButton>(
      find.byKey(const Key('sendButton')),
    );
    expect(sendBtn.onPressed, isNull);
  });

  testWidgets('selecting userAction shows action name and sourceComponentId',
      (tester) async {
    await tester.pumpWidget(
      _wrap(ComposerView(bridge: bridge, historyModel: historyModel)),
    );

    await tester.tap(find.byKey(const Key('messageTypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('userAction').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('actionNameField')), findsOneWidget);
    expect(find.byKey(const Key('sourceComponentIdField')), findsOneWidget);
  });

  testWidgets('userAction calls injectUserAction on bridge', (tester) async {
    await tester.pumpWidget(
      _wrap(ComposerView(bridge: bridge, historyModel: historyModel)),
    );

    await tester.tap(find.byKey(const Key('messageTypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('userAction').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('actionNameField')), 'confirmBooking');
    await tester.enterText(
        find.byKey(const Key('sourceComponentIdField')), 'btn-1');
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pumpAndSettle();

    verify(() => bridge.injectUserAction(any())).called(1);
    verifyNever(() => bridge.injectA2uiMessage(any()));
  });

  testWidgets('Raw JSON toggle shows the text editor', (tester) async {
    await tester.pumpWidget(
      _wrap(ComposerView(bridge: bridge, historyModel: historyModel)),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // The form fields should be gone, the json editor text field should be visible.
    expect(find.byKey(const Key('catalogIdField')), findsNothing);
    expect(find.byWidgetPredicate((w) => w is TextField && w.maxLines == null),
        findsOneWidget);
  });

  testWidgets('updateDataModel payload includes version v0.9', (tester) async {
    await tester.pumpWidget(
      _wrap(ComposerView(bridge: bridge, historyModel: historyModel)),
    );

    await tester.tap(find.byKey(const Key('messageTypeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('updateDataModel').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('surfaceIdField')), 's1');
    await tester.enterText(find.byKey(const Key('dataPathField')), '/name');
    await tester.enterText(find.byKey(const Key('dataValueField')), '"Alice"');
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pumpAndSettle();

    final captured =
        verify(() => bridge.injectA2uiMessage(captureAny()))
            .captured
            .single as Map<String, Object?>;
    expect(captured['version'], 'v0.9');
    expect(captured['updateDataModel'], isA<Map>());
  });
}
