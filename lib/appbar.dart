import 'package:algrafx/model.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'canvas_to_image_web.dart';
import 'color_selector.dart';
import 'controller.dart';

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
  OverlayEntry _currentEntry;

  @override
  void dispose() {
    if (_currentEntry != null) {
      _currentEntry.remove();
      _currentEntry = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobileScreen = !(MediaQuery.of(context).size.shortestSide >= 600);

    return StreamBuilder(
      stream: widget.controller.backgroundColor$,
      builder: (c, snapshot) {
        final luminance = (snapshot.data ?? fGrey).computeLuminance();
        final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
        final iconColor =
            brightness == Brightness.light ? Colors.black54 : Colors.white54;
        return Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('AlGrafx', style: TextStyle(color: Colors.pink)),
              ),
              ...[
                ColorSelector(
                  color: snapshot.data ?? fGrey,
                  brightness: (snapshot.data ?? fGrey).computeLuminance() > 0.5
                      ? Brightness.light
                      : Brightness.dark,
                  label: isMobileScreen ? '' : 'Background',
                  onColorSelection: (c) {
                    _currentEntry = null;
                    widget.controller.backgroundColor = c;
                  },
                  onOpenOverlay: (entry) => _updateEntry(entry),
                ),
                /*),*/
                StreamBuilder(
                  stream: widget.controller.selectedColor$,
                  builder: (c, snapshot) {
                    final luminance =
                        (widget.controller.backgroundColor ?? fGrey)
                            .computeLuminance();
                    final brightness =
                        luminance > 0.5 ? Brightness.light : Brightness.dark;
                    return ColorSelector(
                      color: snapshot.data ?? widget.controller.fillColor,
                      brightness: brightness,
                      label: isMobileScreen ? '' : 'Pen',
                      onColorSelection: (c) {
                        _currentEntry = null;
                        widget.controller.fillColor = c;
                      },
                      onOpenOverlay: (entry) => _updateEntry(entry),
                    );
                  },
                ),
              ]
            ]),
            Row(
              children: <Widget>[
                Tooltip(
                  message: 'Undo',
                  child: IconButton(
                    icon: Icon(Icons.undo, color: iconColor),
                    onPressed: widget.controller.undo,
                  ),
                ),
                Tooltip(
                  message: 'Clear',
                  child: IconButton(
                    icon: Icon(Icons.delete_forever, color: iconColor),
                    onPressed: widget.controller.clear,
                  ),
                ),
                Tooltip(
                  message: 'Download',
                  child: IconButton(
                    icon: Icon(Icons.file_download, color: iconColor),
                    onPressed: () {
                      return widget.exporter.saveImage(
                        widget.controller.polygons,
                        widget.controller.backgroundColor,
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
        );
      },
    );
  }

  void _updateEntry(Future<OverlayEntry> entry) async {
    _clearOverlay();
    if (entry != null) _currentEntry = await entry;

    setState(() {});
  }

  void _clearOverlay() {
    print('_AppbarState._clearOverlay... $_currentEntry');
    if (_currentEntry != null) {
      _currentEntry.remove();
      _currentEntry = null;
    }
  }
}
