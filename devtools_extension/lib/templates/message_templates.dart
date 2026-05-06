typedef JsonMap = Map<String, Object?>;

// All templates share surfaceId 'demo' so they work together as a sequential
// flow: createSurface → updateComponents → updateDataModel → userAction → deleteSurface.
//
// updateComponents creates two data-bound components (/greeting and /name) so
// that updateDataModel produces a visible UI change. The Button dispatches the
// 'greet' action, so userAction references it directly.

abstract final class MessageTemplates {
  static const _defaultSurfaceId = 'demo';
  static const _defaultCatalogId =
      'https://a2ui.org/specification/v0_9/basic_catalog.json';

  static JsonMap createSurface({
    String surfaceId = _defaultSurfaceId,
    String catalogId = _defaultCatalogId,
  }) =>
      {
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': surfaceId,
          'catalogId': catalogId,
        },
      };

  /// Renders a form with:
  /// - A heading
  /// - A greeting Text bound to /greeting (changes when updateDataModel fires)
  /// - A TextField bound to /name
  /// - A primary Button that dispatches the 'greet' action
  ///
  /// Send this after createSurface, then send updateDataModel to see the
  /// greeting text change live.
  static JsonMap updateComponents({
    String surfaceId = _defaultSurfaceId,
  }) =>
      {
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': surfaceId,
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': [
                'heading',
                'greeting-display',
                'name-field',
                'submit-btn',
                'submit-label',
              ],
            },
            {
              'id': 'heading',
              'component': 'Text',
              'text': 'Surface Simulator Demo',
              'variant': 'h3',
            },
            {
              // This text is bound to /greeting in the data model.
              // Inject an updateDataModel to '/greeting' to see it update live.
              'id': 'greeting-display',
              'component': 'Text',
              'text': {'path': '/greeting'},
            },
            {
              'id': 'name-field',
              'component': 'TextField',
              'label': 'Your name',
              'value': {'path': '/name'},
            },
            {
              // Tapping this button dispatches the 'greet' action.
              // Use userAction with name='greet' and sourceComponentId='submit-btn'
              // to simulate a tap from the DevTools panel.
              'id': 'submit-btn',
              'component': 'Button',
              'child': 'submit-label',
              'action': {
                'name': 'greet',
                'context': ['name-field'],
              },
              'variant': 'primary',
            },
            {
              'id': 'submit-label',
              'component': 'Text',
              'text': 'Say Hello',
            },
          ],
        },
      };

  /// Updates /greeting in the data model. After sending updateComponents,
  /// injecting this message will make the 'greeting-display' Text change live.
  static JsonMap updateDataModel({
    String surfaceId = _defaultSurfaceId,
    String path = '/greeting',
    Object? value = 'Hello from DevTools!',
  }) =>
      {
        'version': 'v0.9',
        'updateDataModel': {
          'surfaceId': surfaceId,
          'path': path,
          'value': value,
        },
      };

  static JsonMap deleteSurface({
    String surfaceId = _defaultSurfaceId,
  }) =>
      {
        'version': 'v0.9',
        'deleteSurface': {
          'surfaceId': surfaceId,
        },
      };

  /// Simulates a tap on the 'submit-btn' Button created by updateComponents.
  /// The app receives this as a UiEvent on SurfaceController.handleUiEvent.
  /// The 'context' map mirrors what GenUI collects when the button is tapped
  /// for real — keyed by component ID, valued by the current field value.
  static JsonMap userAction({
    String name = 'greet',
    String sourceComponentId = 'submit-btn',
    String surfaceId = _defaultSurfaceId,
    JsonMap context = const {'name-field': 'World'},
  }) =>
      {
        'name': name,
        'sourceComponentId': sourceComponentId,
        'surfaceId': surfaceId,
        'context': context,
      };
}

enum MessageType {
  createSurface,
  updateComponents,
  updateDataModel,
  deleteSurface,
  userAction;

  String get label => switch (this) {
        createSurface => 'createSurface',
        updateComponents => 'updateComponents',
        updateDataModel => 'updateDataModel',
        deleteSurface => 'deleteSurface',
        userAction => 'userAction',
      };

  bool get isUserAction => this == MessageType.userAction;
}
