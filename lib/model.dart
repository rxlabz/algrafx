import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

const double G = 2.0;

const double cG = 0.03;

const fBlue = const Color(0xff4FBDF6);

const fGrey = const Color(0xFF212121);

const black = const Color(0xff000000);

class Config {
  final Color backgroundColor;
  final Color fillColor;
  final Color strokeColor;
  final bool applyForce;
  final bool liveColor;

  Config([
    this.backgroundColor = fGrey,
    this.fillColor = fBlue,
    this.strokeColor = Colors.black,
    this.applyForce = true,
    this.liveColor = true,
  ]);

  copyWith({
    Color backgroundColor,
    Color fillColor,
    Color strokeColor,
    bool applyForce,
    bool liveColor,
  }) =>
      Config(
        backgroundColor ?? this.backgroundColor,
        fillColor ?? this.fillColor,
        strokeColor ?? this.strokeColor,
        applyForce ?? this.applyForce,
        liveColor ?? this.liveColor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Config &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          fillColor == other.fillColor &&
          strokeColor == other.strokeColor &&
          applyForce == other.applyForce &&
          liveColor == other.liveColor;

  @override
  int get hashCode =>
      backgroundColor.hashCode ^
      fillColor.hashCode ^
      strokeColor.hashCode ^
      applyForce.hashCode ^
      liveColor.hashCode;
}

class Node {
  static final yellowFill = Paint()..color = Color(0x55FFEB3B);

  Offset gravity = Offset(0, G);

  Offset offset;

  Color color;

  Color strokeColor;

  final bool applyForce;

  bool liveColor;

  bool _freezed = false;

  double get x => offset.dx;
  double get y => offset.dy;

  Node(this.offset, this.color, this.strokeColor, this.applyForce,
      this.liveColor);

  update() {
    if (_freezed) return;

    if (applyForce) {
      offset += gravity;
      gravity *= 1 + cG;
    }

    if (liveColor) {
      if (color != black) {
        final hsl = HSLColor.fromColor(color);
        color = hsl.withLightness(max(hsl.lightness - 0.01, 0)).toColor();
      }

      if (strokeColor != null && strokeColor != black) {
        final strokeHsl = HSLColor.fromColor(strokeColor);
        strokeColor = strokeHsl
            .withLightness(max(strokeHsl.lightness - 0.01, 0))
            .toColor();
      }

      if (color.value == black.value && strokeColor.value == black.value) {
        liveColor = false;
        if (!applyForce) freeze();
      }
    }
  }

  freeze() => _freezed = true;

  void draw(Canvas canvas) {
    canvas.drawCircle(offset, 2, yellowFill);
  }
}

class Line {
  final List<Node> points;

  static final paint = Paint()..color = const Color(0xFF424242);

  Line(this.points);

  void draw(Canvas canvas) {
    canvas.drawLine(points.first.offset, points.last.offset, paint);
  }
}

class Polygon {
  final List<Node> nodes;
  final double distance;

  final List<Offset> previousPoints;

  final Color fillColor;
  final Color strokeColor;

  List<Offset> get points {
    final width = Offset(0, 30) * distance / 100;
    final c0 = nodes.first.offset - width;
    final c1 = nodes.last.offset - width;
    final c2 = nodes.last.offset + width;
    final c3 = nodes.first.offset + width;
    return [c0, c1, c2, c3];
  }

  Polygon(this.nodes, {this.previousPoints, this.fillColor, this.strokeColor})
      : distance = (nodes.first.offset - nodes.last.offset).distance;

  void draw(Canvas canvas) {
    final width = Offset(0, 30) * distance / 100;

    final paint = Paint()..color = fillColor;
    final c0 = previousPoints.first;
    final c1 =
        nodes.last.offset - width /*> Offset(0, 5) ? width : Offset(0, 5)*/;
    final c2 =
        nodes.last.offset + width /*> Offset(0, 5) ? width : Offset(0, 5)*/;
    final c3 = previousPoints.last;

    final path = Path()
      ..moveTo(c0.dx, c0.dy)
      ..lineTo(c1.dx, c1.dy)
      ..lineTo(c2.dx, c2.dy)
      ..lineTo(c3.dx, c3.dy)
      ..lineTo(c0.dx, c0.dy);
    canvas.drawPath(path, paint);

    if (strokeColor != null)
      canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = strokeColor);
  }
}
