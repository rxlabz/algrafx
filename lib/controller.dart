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
    nodes = nodes.where((node) => node.offset.dy < size.height).toList()
      ..forEach((node) => node.update());
  }

  clear() {
    nodes = [];
    polygons = [];
  }

  freeze() {
    nodes.forEach((c) => c.freeze());
    polygons.add([...nodes]);
    _polygonStreamer.add(polygons);
    nodes = [];
  }

  void undo() {
    polygons.removeLast();
  }
}
