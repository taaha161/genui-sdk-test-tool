import 'dart:convert';

import 'package:flutter/material.dart';

class JsonEditor extends StatelessWidget {
  const JsonEditor({
    super.key,
    required this.controller,
    required this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;

  static String? tryFormat(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: null,
      expands: true,
      decoration: InputDecoration(
        hintText: '{ "version": "v0.9", ... }',
        errorText: errorText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
    );
  }
}
