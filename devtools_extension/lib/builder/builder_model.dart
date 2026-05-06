import 'package:flutter/foundation.dart';

int _idCounter = 0;

class ComponentNode {
  ComponentNode(this.type)
      : id = '${type.toLowerCase()}-${++_idCounter}',
        props = {};

  final String id;
  final String type;
  final Map<String, String> props;
  final List<ComponentNode> children = [];
  ComponentNode? child;

  void setProp(String key, String value) => props[key] = value;
}

class BuilderModel extends ChangeNotifier {
  ComponentNode? root;

  void setRoot(ComponentNode node) {
    root = node;
    notifyListeners();
  }

  void addChildToNode(ComponentNode parent, ComponentNode newChild) {
    parent.children.add(newChild);
    notifyListeners();
  }

  void setSingleChild(ComponentNode parent, ComponentNode newChild) {
    parent.child = newChild;
    notifyListeners();
  }

  void removeNode(ComponentNode target) {
    if (root == target) {
      root = null;
    } else if (root != null) {
      _removeFrom(root!, target);
    }
    notifyListeners();
  }

  bool _removeFrom(ComponentNode node, ComponentNode target) {
    if (node.children.remove(target)) return true;
    if (node.child == target) {
      node.child = null;
      return true;
    }
    for (final c in List.of(node.children)) {
      if (_removeFrom(c, target)) return true;
    }
    if (node.child != null && _removeFrom(node.child!, target)) return true;
    return false;
  }

  void updateProp(ComponentNode node, String key, String value) {
    node.setProp(key, value);
    notifyListeners();
  }

  void clear() {
    root = null;
    notifyListeners();
  }
}
