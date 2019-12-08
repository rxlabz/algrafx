import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'model.dart';

class GraphController {
  GraphController() {
    _config = Config();
    _configStreamer.stream.listen((c) => _config = c);
  }

  List<List<Node>> polygons = [];

  StreamController<List<List<Node>>> _polygonStreamer = StreamController();

  Stream<List<List<Node>>> get polygon$ => _polygonStreamer.stream;

  List<Node> nodes = [];

  get isEmpty => nodes.isEmpty && polygons.isEmpty;

  Config _config;

  Config get config => _config;

  set config(Config value) {
    _config = value;
    _configStreamer.add(value);
  }

  StreamController<Config> _configStreamer = BehaviorSubject.seeded(Config());

  Stream<Config> get config$ => _configStreamer.stream;

  get backgroundColor => _config.backgroundColor;

  set backgroundColor(Color backgroundColor) =>
      _configStreamer.add(_config.copyWith(backgroundColor: backgroundColor));

  Color get fillColor => _config.fillColor;

  set fillColor(Color fillColor) =>
      _configStreamer.add(_config.copyWith(fillColor: fillColor));

  Color get strokeColor => _config.strokeColor;

  set strokeColor(Color strokeColor) =>
      _configStreamer.add(_config.copyWith(strokeColor: strokeColor));

  bool get applyForce => _config.applyForce;

  set applyForce(bool applyForce) =>
      _configStreamer.add(_config.copyWith(applyForce: applyForce));

  bool get liveColor => _config.liveColor;

  set liveColor(bool liveColor) =>
      _configStreamer.add(_config.copyWith(liveColor: liveColor));

  @override
  dispose() {
    _configStreamer.close();
    _polygonStreamer.close();
  }

  void addPoint(Offset offset) {
    nodes.add(Node(
        offset, fillColor, strokeColor, config.applyForce, config.liveColor));
    //notifyListeners();
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
