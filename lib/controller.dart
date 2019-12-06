import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'model.dart';

class GraphController extends ChangeNotifier {
  List<List<Node>> polygons = [];

  StreamController<List<List<Node>>> _polygonStreamer = StreamController();

  Stream<List<List<Node>>> get polygon$ => _polygonStreamer.stream;

  List<Node> nodes = [];

  StreamController<Color> _colorStreamer = StreamController.broadcast();

  Stream<Color> get selectedColor$ => _colorStreamer.stream;

  StreamController<Color> _backgroundColorStreamer =
      StreamController.broadcast();

  Stream<Color> get backgroundColor$ => _backgroundColorStreamer.stream;

  get isEmpty => nodes.isEmpty && polygons.isEmpty;

  Color _backgroundColor = fGrey;

  get backgroundColor => _backgroundColor;

  set backgroundColor(Color backgroundColor) {
    _backgroundColor = backgroundColor;
    _backgroundColorStreamer.add(_backgroundColor);
    _colorStreamer.add(_fillColor);
  }

  Color _fillColor = fBlue;

  Color get fillColor => _fillColor;

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

  void addPoint(Offset offset) {
    nodes.add(Node(offset, fillColor));
    notifyListeners();
  }

  void update(Size size) {
    final filteredNodes = <Node>[];
    for (final node in nodes) {
      if (node.offset.dy < size.height) {
        node.update();
        filteredNodes.add(node);
      }
      nodes = filteredNodes;
    }
  }

  void clear() {
    nodes = [];
    polygons = [];
    _polygonStreamer.add(polygons);
  }

  void freeze() {
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
