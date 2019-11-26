import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'canvas_to_image_web.dart';
import 'color_selector.dart';
import 'controller.dart';

class Appbar extends StatelessWidget {
  final GraphController controller;

  final ImageExporterWeb exporter;

  const Appbar({Key key, this.controller})
      : exporter = const ImageExporterWeb(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = !(MediaQuery.of(context).size.shortestSide >= 600);
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('AlGrafx', style: TextStyle(color: Colors.pink)),
        ),
        if (!isMobileScreen)
          StreamBuilder(
            stream: controller.selectedColor$,
            builder: (c, snapshot) => ColorSelector(
              color: snapshot.data ?? controller.fillColor,
              onColorSelection: (c) => controller.fillColor = c,
            ),
          ),
        Row(
          children: <Widget>[
            Tooltip(
              message: 'Undo',
              child: IconButton(
                icon: Icon(Icons.undo, color: Colors.grey),
                onPressed: controller.undo,
              ),
            ),
            Tooltip(
              message: 'Clear',
              child: IconButton(
                icon: Icon(Icons.delete_forever, color: Colors.red),
                onPressed: controller.clear,
              ),
            ),
            Tooltip(
              message: 'Download',
              child: IconButton(
                icon: Icon(Icons.file_download, color: Colors.yellow),
                onPressed: () {
                  return exporter.saveImage(
                    controller.polygons,
                    Colors.grey.shade900,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: InkWell(
                hoverColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade700,
                  ),
                  child: Image.asset(
                    'github.png',
                    width: 24,
                  ),
                ),
                onTap: () => html.window
                    .open('http://github.com/rxlabz/algrafx', '_blank'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
