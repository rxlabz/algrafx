import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'model.dart';

class GraphController extends ChangeNotifier {
  List<List<Node>> polygons = [];

  StreamController<List<List<Node>>> _polygonStreamer = StreamController();

  Stream<List<List<Node>>> get polygon$ => _polygonStreamer.stream;

  List<Node> nodes = [];

  StreamController<Color> _colorStreamer = StreamController();

  Stream<Color> get selectedColor$ => _colorStreamer.stream;

  Color _fillColor = fBlue;

  Color get fillColor => _fillColor;

  get isEmpty => nodes.isEmpty && polygons.isEmpty;

  set fillColor(Color fillColor) {
    _fillColor = fillColor;
    _colorStreamer.add(_fillColor);
  }

  @override
  dispose() {
    _polygonStreamer.close();
    _colorStreamer.close();
    super.dispose();
  }

  addPoint(Offset offset) {
    nodes.add(Node(offset, fillColor));
    notifyListeners();
  }

  update(Size size) {
    final filteredNodes = <Node>[];
    for (final node in nodes) {
      if (node.offset.dy < size.height) {
        node.update();
        filteredNodes.add(node);
      }
      nodes = filteredNodes;
    }
  }

  clear() {
    nodes = [];
    polygons = [];
    _polygonStreamer.add(polygons);
  }

  freeze() {
    polygons.add([for (final node in nodes) node..freeze()]);
    _polygonStreamer.add(polygons);
    nodes = [];
  }

  void undo() {
    if (polygons.isEmpty) return;

    polygons.removeLast();
    _polygonStreamer.add(polygons);
  }
}
