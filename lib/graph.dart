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
          if( isMobileScreen )
          Positioned(
            left: 0 , right: 0, bottom: 30,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: AnimatedBuilder(
                animation: controller,
                builder:(c,_)=> ColorSelector(
                  color: controller.fillColor,
                  onColorSelection: (c) => controller.fillColor = c,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: controller,
            builder: (c, _) => AnimatedOpacity(
              duration: aSecond,
              opacity: controller.isEmpty ? 1 : 0,
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
            ),
          )
        ],
      ),
    );
  }
}

class Graph extends StatefulWidget {
  final GraphController controller;

  Graph(this.controller);

  @override
  _GraphState createState() => _GraphState();
}

class _GraphState extends State<Graph> with TickerProviderStateMixin {
  CustomPaint _frozenNodePainter;
  AnimationController _gravityAnimationController;
  Size size;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = MediaQuery.of(context).size;
    _recreateFrozenNodePainter();
    _gravityAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    )
      ..addListener(() {
        widget.controller.update(size);
        if (widget.controller.nodes.isEmpty) {
          _gravityAnimationController.stop();
        }
      })
      ..forward()
      ..repeat();
  }

  void _recreateFrozenNodePainter() {
    setState(() {
      _frozenNodePainter = CustomPaint(
        size: size,
        painter: MultiPainter([
          for (List<Node> frozenList in widget.controller.freezedNodes)
            GraphPainter(frozenList)
        ]),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event.data.keyLabel == ' ') {
          widget.controller.freeze();
          _recreateFrozenNodePainter();
        }
      },
      child: GestureDetector(
        onTap: () {
          widget.controller.freeze();
          _recreateFrozenNodePainter();
        },
        onPanUpdate: (event) {
          widget.controller.addPoint(event.localPosition);
          _gravityAnimationController
            ..forward()
            ..repeat();
        },
        child: Container(
          constraints: BoxConstraints.expand(),
          color: Colors.grey.shade900,
          child: Stack(
            children: [
              _frozenNodePainter,
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _gravityAnimationController,
                  builder: (c, _) {
                    return _trackMouse(CustomPaint(
                      size: size,
                      painter: GraphPainter(widget.controller.nodes),
                    ));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MouseRegion _trackMouse(Widget child) {
    return MouseRegion(
      onHover: (event) {
        widget.controller.addPoint(event.position);
        _gravityAnimationController
          ..forward()
          ..repeat();
      },
      child: GestureDetector(
        onTap: () {
          widget.controller.freeze();
          _recreateFrozenNodePainter();
        },
        onPanUpdate: (event) {
          widget.controller.addPoint(event.globalPosition);
          _gravityAnimationController
            ..forward()
            ..repeat();
        },
        child: child,
      ),
    );
  }
}

class MultiPainter extends CustomPainter {
  MultiPainter(this.painters);

  final List<CustomPainter> painters;

  @override
  void paint(Canvas canvas, Size size) {
    for (CustomPainter painter in painters) {
      painter.paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(MultiPainter oldDelegate) {
    return !identical(this, oldDelegate);
  }
}

class GraphPainter extends CustomPainter {
  final List<Node> circles;

  GraphPainter(this.circles);

  static final Paint dummyRectPaint = Paint()
    ..color = Color.fromARGB(0, 255, 255, 255)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    // The dummy rect is to workaround a bug in Flutter for web that this app
    // uncovered. It seems when the canvas size changes due to changing contents
    // we are unable to compute the mouse event offset correctly. A second benefit
    // is that this keeps the canvas size stable, letting the engine reuse the
    // same canvas no matter what nodes are painted.
    canvas.drawRect(Offset.zero & size, dummyRectPaint);
    circles
        .where((c) => c.offset.dy < size.height)
        .forEach((c) {
          c.draw(canvas);
        });
    for (int i = 1; i < circles.length; i++) {
      final l = Line([circles[i - 1], circles[i]]);
      l.draw(canvas);
    }
    for (int i = 1; i < circles.length; i++) {
      if (i > 2) {
        final prevR = Polygon([circles[i - 2], circles[i - 1]]);
        final r = Polygon([circles[i - 1], circles[i]],
            previousPoints: [prevR.points[1], prevR.points[2]],
            color: circles[i].color);
        r.draw(canvas);
      }
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    // We always have to repaint because the circle lists are internally mutable,
    // and so comparing them does not tell us whether anything's changed or not.
    return true;
  }
}
