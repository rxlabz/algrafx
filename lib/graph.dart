import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quiver/time.dart';

import 'appbar.dart' as rx;
import 'color_selector.dart';
import 'controller.dart';
import 'model.dart';

class GraphScreen extends StatelessWidget {
  final GraphController controller;

  const GraphScreen(this.controller, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //print('GraphScreen.build... ');
    final isMobileScreen = !(MediaQuery.of(context).size.shortestSide >= 600);
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Graph(this.controller),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: rx.Appbar(controller: controller),
          ),
          if (isMobileScreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: StreamBuilder(
                  initialData: controller.fillColor,
                  stream: controller.selectedColor$,
                  builder: (c, snapshot) => ColorSelector(
                    color:
                        snapshot.hasData ? snapshot.data : controller.fillColor,
                    onColorSelection: (c) => controller.fillColor = c,
                  ),
                ),
              ),
            ),
          OnBoarding(),
        ],
      ),
    );
  }
}

class OnBoarding extends StatefulWidget {
  @override
  _OnBoardingState createState() => _OnBoardingState();
}

class _OnBoardingState extends State<OnBoarding> {
  double opacity = 1;

  @override
  void initState() {
    Timer(aSecond * 5, () => setState(() => opacity = 0));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: aSecond,
      opacity: opacity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.black54,
          child: Text(
            'Move your cursor / Click or hit Space to freeze',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class Graph extends StatelessWidget {
  final GraphController controller;

  Graph(this.controller);

  @override
  Widget build(BuildContext context) {
    //print('Graph.build... ');
    final size = MediaQuery.of(context).size;
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event.data.keyLabel == ' ') controller.freeze();
      },
      child: MouseRegion(
        onHover: (event) => controller.addPoint(event.position),
        child: GestureDetector(
          onTap: controller.freeze,
          onPanUpdate: (event) => controller.addPoint(event.localPosition),
          child: Container(
            constraints: BoxConstraints.expand(),
            color: Colors.grey.shade900,
            child: Stack(
              children: <Widget>[
                StreamBuilder<List<List<Node>>>(
                    stream: controller.polygon$,
                    builder: (context, snapshot) => BackgroundCanvas(
                          freezedNodes: snapshot.data ?? [],
                          size: size,
                        )),
                LiveCanvas(size: size, controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiveCanvas extends StatefulWidget {
  final Size size;
  final GraphController controller;

  const LiveCanvas({
    Key key,
    @required this.size,
    @required this.controller,
  }) : super(key: key);

  @override
  _LiveCanvasState createState() => _LiveCanvasState();
}

class _LiveCanvasState extends State<LiveCanvas> with TickerProviderStateMixin {
  AnimationController anim;

  @override
  void initState() {
    anim = AnimationController(vsync: this, duration: Duration(seconds: 1))
      ..forward()
      ..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (c, _) {
        widget.controller.update(widget.size);
        return CustomPaint(
          size: widget.size,
          painter: ForegroundPainter(widget.controller.nodes),
        );
      },
    );
  }
}

class BackgroundCanvas extends StatelessWidget {
  final List<List<Node>> freezedNodes;
  final Size size;

  const BackgroundCanvas({Key key, this.freezedNodes, this.size})
      : super(key: key);

  Widget build(BuildContext context) {
    //print('BackgroundCanvas.build... ${freezedNodes.length}');
    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        isComplex: true,
        willChange: false,
        painter: BackgroundPainter(freezedNodes),
      ),
    );
  }
}

class ForegroundPainter extends CustomPainter {
  List<Node> nodes;

  ForegroundPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    //print('GraphPainter.paint... ${nodes.length}');
    nodes
        .where((c) => c.offset.dy < size.height)
        .forEach((c) => c.draw(canvas));
    for (int i = 1; i < nodes.length; i++) {
      final l = Line([nodes[i - 1], nodes[i]]);
      l.draw(canvas);
    }
    for (int i = 1; i < nodes.length; i++) {
      if (i > 2) {
        final prevR = Polygon([nodes[i - 2], nodes[i - 1]]);
        final r = Polygon([nodes[i - 1], nodes[i]],
            previousPoints: [prevR.points[1], prevR.points[2]],
            color: nodes[i].color);
        r.draw(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(ForegroundPainter oldDelegate) {
    return listEquals(nodes, oldDelegate.nodes);
  }
}

class BackgroundPainter extends CustomPainter {
  List<List<Node>> polygons;

  BackgroundPainter(this.polygons);

  @override
  void paint(Canvas canvas, Size size) {
    polygons.forEach(
      (nodes) {
        nodes
            .where((c) => c.offset.dy < size.height)
            .forEach((c) => c.draw(canvas));
        for (int i = 1; i < nodes.length; i++) {
          final l = Line([nodes[i - 1], nodes[i]]);
          l.draw(canvas);
        }
        for (int i = 1; i < nodes.length; i++) {
          if (i > 2) {
            final prevR = Polygon([nodes[i - 2], nodes[i - 1]]);
            final r = Polygon([nodes[i - 1], nodes[i]],
                previousPoints: [prevR.points[1], prevR.points[2]],
                color: nodes[i].color);
            r.draw(canvas);
          }
        }
      },
    );
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
