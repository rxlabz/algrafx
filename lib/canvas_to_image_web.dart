import 'dart:html';
import 'dart:ui' as ui;

import 'model.dart';

abstract class ImageExporter {
  saveImage(List<List<Node>> polygons, ui.Color color, ui.Color strokeColor);
}

class ImageExporterWeb implements ImageExporter {
  const ImageExporterWeb();

  void saveImage(
      List<List<Node>> polygons, ui.Color color, ui.Color strokeColor) {
    final link = AnchorElement();

    final canvas = CanvasElement(
      width: window.innerWidth,
      height: window.innerHeight,
    );
    final context = canvas.context2D;
    num w = canvas.width;
    num h = canvas.height;

    polygons.forEach((polygonCircles) {
      for (int i = 1; i < polygonCircles.length; i++) {
        if (i > 2) {
          final prevR = Polygon([polygonCircles[i - 2], polygonCircles[i - 1]]);
          final polygon = Polygon(
            [polygonCircles[i - 1], polygonCircles[i]],
            previousPoints: [prevR.points[1], prevR.points[2]],
            fillColor: polygonCircles[i].color,
            strokeColor: polygonCircles[i].strokeColor,
          );
          _drawWeb(polygon, canvas);
        }
      }
    });

    ImageData data = context.getImageData(0, 0, w, h);

    //store the current globalCompositeOperation
    String compositeOperation = context.globalCompositeOperation;

    //set to draw behind current content
    context.globalCompositeOperation = "destination-over";

    final hex = color.value.toRadixString(16).padLeft(6, '0').substring(2);
    //set background color
    context.fillStyle = '#$hex';

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

  void _drawWeb(Polygon polygon, CanvasElement canvas) {
    final rubanWidth = ui.Offset(0, 30) * polygon.distance / 100;

    final c0 = polygon
        .previousPoints.first; // last point topRight from previous polygon
    final c1 = polygon.nodes.last.offset - rubanWidth;
    final c2 = polygon.nodes.last.offset + rubanWidth;
    final c3 = polygon
        .previousPoints.last; // last point bottomRight from previous polygon

    canvas.context2D
      ..beginPath()
      ..fillStyle =
          'rgba(${polygon.fillColor.red},${polygon.fillColor.green},${polygon.fillColor.blue},${polygon.fillColor.opacity})'
      ..strokeStyle = polygon.strokeColor != null
          ? 'rgba(${polygon.strokeColor.red},${polygon.strokeColor.green},${polygon.strokeColor.blue},${polygon.strokeColor.opacity})'
          : 'transparent'
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
