import 'dart:html' as html;

import 'package:algrafx/model.dart';
import 'package:algrafx/ui/settings_bar.dart';
import 'package:flutter/material.dart';

import '../canvas_to_image_web.dart';
import '../controller.dart';

class Appbar extends StatefulWidget {
  final GraphController controller;

  final ImageExporterWeb exporter;

  const Appbar({Key key, this.controller})
      : exporter = const ImageExporterWeb(),
        super(key: key);

  @override
  _AppbarState createState() => _AppbarState();
}

class _AppbarState extends State<Appbar> {
  void _openDrawer() {
    Scaffold.of(context).openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = MediaQuery.of(context).size.width <= 900;
    final controller = widget.controller;
    return StreamBuilder<Config>(
      stream: controller.config$,
      builder: (c, snapshot) {
        final config = snapshot.data ?? Config();

        final luminance = config.backgroundColor.computeLuminance();
        final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
        final iconColor =
            brightness == Brightness.light ? Colors.black54 : Colors.white54;
        return Container(
          color: Colors.black12,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text('AlGrafx', style: TextStyle(color: iconColor)),
              ),
              SettingsBar(
                direction: Axis.horizontal,
                config: config,
                controller: controller,
              ),
              if (isMobileScreen)
                IconButton(
                  icon: Icon(Icons.menu, color: iconColor),
                  onPressed: _openDrawer,
                ),
              if (!isMobileScreen)
                Row(
                  children: <Widget>[
                    Tooltip(
                      message: 'Undo',
                      child: IconButton(
                        icon: Icon(Icons.undo, color: iconColor),
                        onPressed: controller.undo,
                      ),
                    ),
                    Tooltip(
                      message: 'Clear',
                      child: IconButton(
                        icon: Icon(Icons.delete_forever, color: iconColor),
                        onPressed: controller.clear,
                      ),
                    ),
                    Tooltip(
                      message: 'Download',
                      child: IconButton(
                        icon: Icon(Icons.file_download, color: iconColor),
                        onPressed: () {
                          return widget.exporter.saveImage(
                            controller.polygons,
                            controller.backgroundColor,
                            controller.strokeColor,
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
                            color: Colors.white54,
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
          ),
        );
      },
    );
  }
}
