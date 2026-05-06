import 'package:flutter/material.dart';

import 'builder_model.dart';
import 'component_specs.dart';

class BlockWidget extends StatefulWidget {
  const BlockWidget({
    required super.key,
    required this.node,
    required this.model,
    required this.spec,
    this.depth = 0,
  });

  final ComponentNode node;
  final BuilderModel model;
  final ComponentSpec spec;
  final int depth;

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  late final Map<String, TextEditingController> _textControllers;

  @override
  void initState() {
    super.initState();
    _textControllers = {
      for (final prop in widget.spec.props.where((p) => p.options == null))
        prop.key: TextEditingController(
          text: widget.node.props[prop.key] ?? '',
        ),
    };
    for (final entry in _textControllers.entries) {
      entry.value.addListener(
        () => widget.model.updateProp(widget.node, entry.key, entry.value.text),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.spec.color);
    return Container(
      margin: EdgeInsets.only(left: widget.depth * 8.0, bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(color),
          if (widget.spec.props.isNotEmpty) _buildProps(context),
          if (widget.spec.slotKind == SlotKind.multiChild)
            _buildMultiChildSlot(context, color),
          if (widget.spec.slotKind == SlotKind.singleChild)
            _buildSingleChildSlot(context, color),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            widget.node.type,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.node.id,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
          ),
          const Spacer(),
          InkWell(
            onTap: () => widget.model.removeNode(widget.node),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildProps(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Column(
        children: widget.spec.props.map(_buildPropField).toList(),
      ),
    );
  }

  Widget _buildPropField(PropSpec prop) {
    if (prop.options != null) {
      return _DropdownPropField(
        prop: prop,
        node: widget.node,
        model: widget.model,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: TextField(
        controller: _textControllers[prop.key],
        decoration: InputDecoration(
          labelText: prop.key,
          hintText: prop.hint,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildMultiChildSlot(BuildContext context, Color color) {
    return _SlotContainer(
      color: color,
      label: 'children',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.node.children.map((child) {
            final childSpec = specFor(child.type);
            if (childSpec == null) return const SizedBox.shrink();
            return BlockWidget(
              key: ValueKey(child.id),
              node: child,
              model: widget.model,
              spec: childSpec,
              depth: widget.depth + 1,
            );
          }),
          _DropZone(
            onDrop: (type) {
              widget.model.addChildToNode(widget.node, ComponentNode(type));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChildSlot(BuildContext context, Color color) {
    final child = widget.node.child;
    return _SlotContainer(
      color: color,
      label: 'child',
      child: child != null
          ? () {
              final childSpec = specFor(child.type);
              if (childSpec == null) return const SizedBox.shrink();
              return BlockWidget(
                key: ValueKey(child.id),
                node: child,
                model: widget.model,
                spec: childSpec,
                depth: widget.depth + 1,
              );
            }()
          : _DropZone(
              onDrop: (type) {
                widget.model.setSingleChild(widget.node, ComponentNode(type));
              },
            ),
    );
  }
}

class _DropdownPropField extends StatefulWidget {
  const _DropdownPropField({
    required this.prop,
    required this.node,
    required this.model,
  });

  final PropSpec prop;
  final ComponentNode node;
  final BuilderModel model;

  @override
  State<_DropdownPropField> createState() => _DropdownPropFieldState();
}

class _DropdownPropFieldState extends State<_DropdownPropField> {
  late String _value;

  @override
  void initState() {
    super.initState();
    _value = widget.node.props[widget.prop.key] ??
        widget.prop.options!.first;
    widget.node.setProp(widget.prop.key, _value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.prop.key,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _value,
            isDense: true,
            isExpanded: true,
            style: const TextStyle(fontSize: 12),
            items: widget.prop.options!
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _value = v);
              widget.model.updateProp(widget.node, widget.prop.key, v);
            },
          ),
        ),
      ),
    );
  }
}

class _SlotContainer extends StatelessWidget {
  const _SlotContainer({
    required this.color,
    required this.label,
    required this.child,
  });

  final Color color;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _DropZone extends StatefulWidget {
  const _DropZone({required this.onDrop});

  final void Function(String type) onDrop;

  @override
  State<_DropZone> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovering = false);
        widget.onDrop(details.data);
      },
      builder: (context, candidateData, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: _hovering ? 52 : 32,
        decoration: BoxDecoration(
          color: _hovering
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _hovering
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withAlpha(80),
          ),
        ),
        child: Center(
          child: Text(
            _hovering ? 'Release to drop' : '+ Drop component here',
            style: TextStyle(
              fontSize: 10,
              color: _hovering
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}
