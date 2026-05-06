enum SlotKind { none, singleChild, multiChild }

class PropSpec {
  const PropSpec(
    this.key, {
    this.options,
    this.hint = '',
    this.isPath = false,
  });

  final String key;
  final List<String>? options; // null → text field, non-null → dropdown
  final String hint;
  final bool isPath; // true → serialized as {'path': value}
}

class ComponentSpec {
  const ComponentSpec(this.type, this.slotKind, this.props, {required this.color});

  final String type;
  final SlotKind slotKind;
  final List<PropSpec> props;
  final int color; // ARGB
}

const List<ComponentSpec> kComponentSpecs = [
  ComponentSpec('Column', SlotKind.multiChild, [], color: 0xFF5C6BC0),
  ComponentSpec('Row', SlotKind.multiChild, [], color: 0xFF7E57C2),
  ComponentSpec(
    'Card',
    SlotKind.singleChild,
    [],
    color: 0xFF26A69A,
  ),
  ComponentSpec(
    'Text',
    SlotKind.none,
    [
      PropSpec('text', hint: 'Hello world'),
      PropSpec('variant',
          options: ['body', 'h1', 'h2', 'h3', 'h4', 'h5', 'caption']),
    ],
    color: 0xFF42A5F5,
  ),
  ComponentSpec(
    'Button',
    SlotKind.singleChild,
    [
      PropSpec('action', hint: 'submitForm'),
      PropSpec('variant', options: ['primary', 'secondary']),
    ],
    color: 0xFFEF5350,
  ),
  ComponentSpec(
    'TextField',
    SlotKind.none,
    [
      PropSpec('label', hint: 'Your name'),
      PropSpec('value', hint: '/name', isPath: true),
    ],
    color: 0xFF66BB6A,
  ),
  ComponentSpec(
    'CheckBox',
    SlotKind.none,
    [
      PropSpec('label', hint: 'Option'),
      PropSpec('value', hint: '/checked', isPath: true),
    ],
    color: 0xFFFF7043,
  ),
  ComponentSpec(
    'Slider',
    SlotKind.none,
    [
      PropSpec('value', hint: '/amount', isPath: true),
      PropSpec('min', hint: '0'),
      PropSpec('max', hint: '100'),
    ],
    color: 0xFFAB47BC,
  ),
  ComponentSpec(
    'DateTimeInput',
    SlotKind.none,
    [
      PropSpec('label', hint: 'Select date'),
      PropSpec('value', hint: '/date', isPath: true),
    ],
    color: 0xFF26C6DA,
  ),
  ComponentSpec(
    'Image',
    SlotKind.none,
    [PropSpec('url', hint: 'https://example.com/img.png')],
    color: 0xFF8D6E63,
  ),
  ComponentSpec(
    'Icon',
    SlotKind.none,
    [PropSpec('name', hint: 'star')],
    color: 0xFFFFCA28,
  ),
  ComponentSpec(
    'ChoicePicker',
    SlotKind.none,
    [
      PropSpec('label', hint: 'Choose one'),
      PropSpec('value', hint: '/choice', isPath: true),
      PropSpec('options', hint: 'Option A, Option B, Option C'),
    ],
    color: 0xFF78909C,
  ),
  ComponentSpec('Divider', SlotKind.none, [], color: 0xFF90A4AE),
];

ComponentSpec? specFor(String type) =>
    kComponentSpecs.where((s) => s.type == type).firstOrNull;
