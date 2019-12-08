import 'dart:async';

import 'package:algrafx/ui/settings_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quiver/time.dart';

import 'appbar.dart' as rx;
import 'controller.dart';
import 'model.dart';

class GraphScreen extends StatelessWidget {
  final GraphController controller;

  const GraphScreen(this.controller, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = MediaQuery.of(context).size.width <= 900;
    final luminance = controller.config.backgroundColor.computeLuminance();
    final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
    final iconColor =
        brightness == Brightness.light ? Colors.black54 : Colors.white54;
    return Scaffold(
      endDrawer: isMobileScreen
          ? Theme(
              data: ThemeData.dark(),
              child:
                  SettingsDrawer(controller: controller, iconColor: iconColor),
            )
          : null,
      body: Stack(
        children: <Widget>[
          Graph(this.controller),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: rx.Appbar(controller: controller),
          ),
          OnBoarding(isMobileScreen
              ? 'Touch/Pan to draw & Tap to freeze'
              : 'Move your cursor to draw & Click or hit Space to freeze'),
        ],
      ),
    );
  }
}

class OnBoarding extends StatefulWidget {
  final String content;

  OnBoarding(this.content);

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
            widget.content,
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
      child: StreamBuilder<Color>(
          stream:
              controller.config$.map<Color>((Config c) => c.backgroundColor),
          builder: (context, snapshot) {
            return Container(
              constraints: BoxConstraints.expand(),
              color: snapshot.data ?? fGrey,
              child: _buildCanvasStack(size),
            );
          }),
    );
  }

  Stack _buildCanvasStack(Size size) {
    return Stack(
      children: <Widget>[
        StreamBuilder<List<List<Node>>>(
          stream: controller.polygon$,
          builder: (context, snapshot) => BackgroundCanvas(
            freezedNodes: snapshot.data ?? [],
            size: size,
          ),
        ),
        LiveCanvas(size: size, controller: controller),
      ],
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('_LiveCanvasState.didChangeDependencies... ');
  }

  @override
  void initState() {
    anim = AnimationController(vsync: this, duration: Duration(seconds: 1))
      ..addListener(() {
        widget.controller.update(widget.size);
        if (widget.controller.nodes.isEmpty) anim.stop();
      })
      ..forward()
      ..repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onHover: widget.controller.config.applyForce
            ? (event) {
                widget.controller.addPoint(event.localPosition);
                anim
                  ..forward()
                  ..repeat();
              }
            : null,
        onEnter: (event) {
          widget.controller.addPoint(event.localPosition);
          anim
            ..forward()
            ..repeat();
        },
        child: GestureDetector(
            onTap: widget.controller.freeze,
            onPanUpdate: (event) {
              widget.controller.addPoint(event.localPosition);
              anim
                ..forward()
                ..repeat();
            },
            onPanEnd: widget.controller.config.applyForce
                ? null
                : (_) => widget.controller.freeze(),
            child: AnimatedBuilder(
              animation: anim,
              builder: (c, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: widget.size,
                    painter: LivePainter(widget.controller.nodes),
                  ),
                );
              },
            )));
  }
}

class LivePainter extends CustomPainter {
  List<Node> nodes;

  LivePainter(this.nodes);

  static final Paint dummyRectPaint = Paint()
    ..color = Color.fromARGB(0, 255, 255, 255)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    //print('GraphPainter.paint... ${nodes.length}');

    canvas.drawRect(Offset.zero & size, dummyRectPaint);

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node.offset.dy < size.height) node.draw(canvas);

      if (i > 0) {
        final l = Line([nodes[i - 1], nodes[i]]);
        l.draw(canvas);
      }

      if (i > 2) {
        final prevR = Polygon([nodes[i - 2], nodes[i - 1]]);
        final r = Polygon(
          [nodes[i - 1], nodes[i]],
          previousPoints: [prevR.points[1], prevR.points[2]],
          fillColor: nodes[i].color,
          strokeColor: nodes[i].strokeColor,
        );
        r.draw(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(LivePainter oldDelegate) {
    return true;
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

class BackgroundPainter extends CustomPainter {
  List<List<Node>> polygons;

  BackgroundPainter(this.polygons);

  @override
  void paint(Canvas canvas, Size size) {
    polygons.forEach(
      (nodes) {
        for (int i = 0; i < nodes.length; i++) {
          /*
          final node = nodes[i];
          if (node.offset.dy < size.height) node.draw(canvas);

          if (i > 0) {
            final l = Line([nodes[i - 1], nodes[i]]);
            l.draw(canvas);
          }
          */
          if (i > 2) {
            final prevR = Polygon([nodes[i - 2], nodes[i - 1]]);
            final r = Polygon(
              [nodes[i - 1], nodes[i]],
              previousPoints: [prevR.points[1], prevR.points[2]],
              fillColor: nodes[i].color,
              strokeColor: nodes[i].strokeColor,
            );
            r.draw(canvas);
          }
        }
      },
    );
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
