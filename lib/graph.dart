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
  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event) {
        if (event.data.keyLabel == ' ') widget.controller.freeze();
      },
      child: MouseRegion(
        onHover: (event) => widget.controller.addPoint(event.position),
        child: GestureDetector(
          onTap: widget.controller.freeze,
          onPanUpdate: (event) =>
              widget.controller.addPoint(event.localPosition),
          child: Container(
            constraints: BoxConstraints.expand(),
            color: Colors.grey.shade900,
            child: AnimatedBuilder(
              animation: AnimationController(
                  vsync: this, duration: Duration(milliseconds: 100))
                ..forward()
                ..repeat(),
              builder: (c, _) {
                final size = MediaQuery.of(c).size;
                widget.controller.update(size);
                return CustomPaint(
                  size: size,
                  painter: GraphPainter(
                      widget.controller.freezedNodes, widget.controller.nodes),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class GraphPainter extends CustomPainter {
  List<Node> circles;
  List<List<Node>> freezedCircles;

  GraphPainter(this.freezedCircles, this.circles);

  @override
  void paint(Canvas canvas, Size size) {
    freezedCircles.forEach(
      (circles) {
        circles
            .where((c) => c.offset.dy < size.height)
            .forEach((c) => c.draw(canvas));
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
      },
    );

    circles
        .where((c) => c.offset.dy < size.height)
        .forEach((c) => c.draw(canvas));
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
    return circles != oldDelegate.circles ||
        freezedCircles != oldDelegate.freezedCircles;
  }
}
