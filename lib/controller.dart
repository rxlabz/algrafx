import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'model.dart';

class GraphController extends ChangeNotifier{
  List<List<Node>> freezedNodes = [];
  List<Node> nodes = [];

  Color _fillColor = fBlue;

  Color get fillColor => _fillColor;

  get isEmpty => nodes.isEmpty;

  set fillColor(Color fillColor) {
    _fillColor = fillColor;
    notifyListeners();
  }

  addPoint(Offset offset) {
    nodes.add(Node(offset, fillColor));
    notifyListeners();
  }

  update(Size size) {
    nodes = [
      for (Node c in nodes)
        if (c.offset.dy < size.height)
          c..update(),
    ];
  }

  clear() {
    nodes = [];
    freezedNodes = [];
  }

  freeze() {
    nodes.forEach((c) => c.freeze());
    freezedNodes.add([...nodes]);
    nodes = [];
  }

  void undo() {
    freezedNodes.removeLast();
  }

  void canvasToImage([String backgroundColor = "#666666"]) {
    final link = html.AnchorElement();

    final canvas = html.CanvasElement(
      width: html.window.innerWidth,
      height: html.window.innerHeight,
    );
    final context = canvas.context2D;
    num w = canvas.width;
    num h = canvas.height;

    freezedNodes.forEach((polygonCircles) {
      for (int i = 1; i < polygonCircles.length; i++) {
        if (i > 2) {
          final prevR = Polygon([polygonCircles[i - 2], polygonCircles[i - 1]]);
          final r = Polygon([polygonCircles[i - 1], polygonCircles[i]],
              previousPoints: [prevR.points[1], prevR.points[2]],
              color: polygonCircles[i].color);
          r.drawWeb(canvas);
        }
      }
    });

    html.ImageData data = context.getImageData(0, 0, w, h);

    //store the current globalCompositeOperation
    String compositeOperation = context.globalCompositeOperation;

    //set to draw behind current content
    context.globalCompositeOperation = "destination-over";

    //set background color
    context.fillStyle = backgroundColor;

    //draw background / rect on entire canvas
    context.fillRect(0, 0, w, h);

    //get the image data from the canvas
    var imageData = canvas.toDataUrl("image/png");

    //clear the canvas
    context.clearRect(0, 0, w, h);

    //restore it with original / cached ImageData
    context.putImageData(data, 0, 0);

    //reset the globalCompositeOperation to what it was
    context.globalCompositeOperation = compositeOperation;

    //return the Base64 encoded data url string
    link.download = "algrafr-${DateTime.now().millisecondsSinceEpoch}.png";
    link.href = imageData;

    link.click();
  }
}
