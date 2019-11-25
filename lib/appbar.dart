import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'color_selector.dart';
import 'controller.dart';

class Appbar extends StatelessWidget {
  final GraphController controller;

  const Appbar({Key key, this.controller}) : super(key: key);

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
          AnimatedBuilder(
            animation: controller,
            builder: (c, _) => ColorSelector(
              color: controller.fillColor,
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
                  final color = Colors.grey.shade900.value
                      .toRadixString(16)
                      .padLeft(6, '0')
                      .substring(2);
                  return controller.canvasToImage('#$color');
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: InkWell(
                hoverColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade700,),
                  child: Image.asset('github.png', width: 24,),
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
