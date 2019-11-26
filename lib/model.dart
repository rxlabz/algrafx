import 'dart:ui';
import 'dart:html' as html;

import 'package:flutter/material.dart';

const double G = 2.0;

const double cG = 0.03;

const fBlue = Color(0xff4FBDF6);

class Node {
  Offset gravity = Offset(0, G);

  Offset offset;

  Color color;

  bool _freezed = false;

  double get x => offset.dx;
  double get y => offset.dy;

  Node(this.offset, this.color);

  update() {
    if (_freezed) return;
    offset += gravity;
    gravity *= 1 + cG;
    final hsl = HSLColor.fromColor(color);
    final lightness = hsl.lightness;
    color = hsl.withLightness(lightness - lightness * 0.03).toColor();
  }

  freeze() => _freezed = true;

  static final paint = Paint()..color = Colors.yellow.withOpacity(0.3);

  void draw(Canvas canvas) {
    canvas.drawCircle(offset, 2, paint);
  }
}

class Line {
  final List<Node> points;

  Line(this.points);

  static final paint = Paint()..color = Colors.grey.shade800;

  void draw(Canvas canvas) {
    canvas.drawLine(points.first.offset, points.last.offset, paint);
  }
}

class Polygon {
  final List<Node> circles;
  final double dist;

  final List<Offset> previousPoints;

  final Color color;

  List<Offset> get points {
    final width = Offset(0, 30) * dist / 100;
    final c0 = circles.first.offset - width;
    final c1 = circles.last.offset - width;
    final c2 = circles.last.offset + width;
    final c3 = circles.first.offset + width;
    return [c0, c1, c2, c3];
  }

  Polygon(this.circles, {this.previousPoints, this.color})
      : dist = (circles.first.offset - circles.last.offset).distance;

  void draw(Canvas canvas) {
    final width = Offset(0, 30) * dist / 100;

    final paint = Paint()..color = color;
    final c0 = previousPoints.first;
    final c1 = circles.last.offset - width;
    final c2 = circles.last.offset + width;
    final c3 = previousPoints.last;

    final path = Path()
      ..moveTo(c0.dx, c0.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c0.dx, c0.dy);
    canvas.drawPath(path, paint);
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Color(0x88000000));
  }

  void drawWeb(html.CanvasElement canvas) {
    final rubanWidth = Offset(0, 30) * dist / 100;

    final c0 =
        previousPoints.first; // last point topRight from previous polygon
    final c1 = circles.last.offset - rubanWidth;
    final c2 = circles.last.offset + rubanWidth;
    final c3 =
        previousPoints.last; // last point bottomRight from previous polygon

    canvas.context2D
      ..beginPath()
      ..fillStyle =
          'rgba(${color.red},${color.green},${color.blue},${color.opacity})'
      ..strokeStyle = 'black'
      ..moveTo(c0.dx, c0.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c0.dx, c0.dy)
      ..stroke()
      ..fill()
      ..closePath();
  }
}
