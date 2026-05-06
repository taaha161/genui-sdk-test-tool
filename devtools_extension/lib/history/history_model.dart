import 'package:flutter/foundation.dart';

class SentMessage {
  const SentMessage({
    required this.timestamp,
    required this.type,
    required this.payload,
  });

  final DateTime timestamp;
  final String type;
  final Map<String, Object?> payload;
}

class HistoryModel extends ChangeNotifier
    implements ValueListenable<List<SentMessage>> {
  final List<SentMessage> _messages = [];

  @override
  List<SentMessage> get value => List.unmodifiable(_messages);

  void add(SentMessage message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
