import 'dart:html' as html;

import 'package:algrafx/controller.dart';
import 'package:flutter/material.dart';

import '../canvas_to_image_web.dart';

class SettingsDrawer extends StatelessWidget {
  final GraphController controller;

  final Color iconColor;

  final ImageExporterWeb exporter = const ImageExporterWeb();

  const SettingsDrawer({Key key, this.controller, this.iconColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            StreamBuilder<bool>(
                stream: controller.config$
                    .map((c) => c.strokeColor != Colors.transparent),
                builder: (context, snapshot) {
                  return Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Stroke'),
                          Switch(
                            value: controller.config.strokeColor !=
                                Colors.transparent,
                            onChanged: (value) => controller.strokeColor =
                                value ? Colors.black54 : Colors.transparent,
                            activeColor: Colors.cyan,
                            inactiveThumbColor: Colors.white,
                            activeTrackColor: Colors.cyan.shade800,
                            inactiveTrackColor: Colors.grey.shade700,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Force' /*, style: labelStyle*/),
                          Switch(
                            value: controller.config.applyForce,
                            onChanged: (value) => controller.applyForce = value,
                            activeColor: Colors.cyan,
                            inactiveThumbColor: Colors.white,
                            activeTrackColor: Colors.cyan.shade800,
                            inactiveTrackColor: Colors.grey.shade700,
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Dynamic color' /*, style: labelStyle*/),
                          Switch(
                            value: controller.config.liveColor,
                            onChanged: (value) => controller.liveColor = value,
                            activeColor: Colors.cyan,
                            inactiveThumbColor: Colors.white,
                            activeTrackColor: Colors.cyan.shade800,
                            inactiveTrackColor: Colors.grey.shade700,
                          ),
                        ],
                      ),
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
                onTap: () => html.window
                    .open('http://github.com/rxlabz/algrafx', '_blank'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
