import 'dart:async';
import 'dart:html' as html;

import 'package:algrafx/ui/settings_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quiver/time.dart';

import 'appbar.dart' as rx;
import 'canvas_to_image_web.dart';
import 'color_selector.dart';
import 'controller.dart';
import 'model.dart';

class GraphScreen extends StatelessWidget {
  final GraphController controller;

  const GraphScreen(this.controller, {Key key}) : super(key: key);

  final ImageExporterWeb exporter = const ImageExporterWeb();

  @override
  Widget build(BuildContext context) {
    //print('GraphScreen.build... ');
    final isMobileScreen = !(MediaQuery.of(context).size.shortestSide >= 600);
    final textTheme = Theme.of(context).accentTextTheme;
    final luminance = controller.config.backgroundColor.computeLuminance();
    final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
    final iconColor =
        brightness == Brightness.light ? Colors.black54 : Colors.white54;
    return Scaffold(
      endDrawer: isMobileScreen
          ? Theme(
              data: ThemeData.dark(),
              child: Drawer(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: <Widget>[
                      StreamBuilder<bool>(
                          stream: controller.config$
                              .map((c) => c.strokeColor != Colors.transparent),
                          builder: (context, snapshot) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Switch(
                                  value: controller.config.strokeColor !=
                                      Colors.transparent,
                                  onChanged: (value) => controller.strokeColor =
                                      value
                                          ? Colors.black54
                                          : Colors.transparent,
                                  activeColor: Colors.cyan,
                                  inactiveThumbColor: Colors.white,
                                  activeTrackColor: Colors.cyan.shade800,
                                  inactiveTrackColor: Colors.grey.shade700,
                                ),
                                Text('Stroke'),
                                /*ColorSelector(
                                color: controller.config.strokeColor,
                                brightness: brightness,
                                label: isMobileScreen ? '' : 'Stroke',
                                onColorSelection: (c) {
                                  _currentEntry = null;
                                  controller.strokeColor = c;
                                },
                                onOpenOverlay: (entry) => _updateEntry(entry),
                              ),*/
                              ],
                            );
                          }),
                      FlatButton.icon(
                        label: Text('Undo'),
                        icon: Icon(Icons.undo, color: iconColor),
                        onPressed: controller.undo,
                      ),
                      FlatButton.icon(
                        label: Text('Clear'),
                        icon: Icon(Icons.delete_forever, color: iconColor),
                        onPressed: controller.clear,
                      ),
                      FlatButton.icon(
                        label: Text('Download'),
                        icon: Icon(Icons.file_download, color: iconColor),
                        onPressed: () {
                          return exporter.saveImage(
                            controller.polygons,
                            controller.backgroundColor,
                            controller.strokeColor,
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: InkWell(
                          hoverColor: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white54,
                                ),
                                child: Image.asset('github.png', width: 24),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Text('On Github'),
                              ),
                            ],
                          ),
                          onTap: () => html.window.open(
                              'http://github.com/rxlabz/algrafx', '_blank'),
                        ),
                      ),
                    ],
                  )
                  /*Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Settings', style: textTheme.title),
                      ),
                      StreamBuilder<Config>(
                          stream: controller.config$,
                          builder: (context, snapshot) {
                            return SettingsBar(
                              config: controller.config,
                              controller: controller,
                            );
                          }),
                    ],
                  )*/
                  ,
                ),
              ),
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
        onHover: (event) {
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
            child: AnimatedBuilder(
              animation: anim,
              builder: (c, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    size: widget.size,
                    painter: ForegroundPainter(widget.controller.nodes),
                  ),
                );
              },
            )));
  }
}

class ForegroundPainter extends CustomPainter {
  List<Node> nodes;

  ForegroundPainter(this.nodes);

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
  bool shouldRepaint(ForegroundPainter oldDelegate) {
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
