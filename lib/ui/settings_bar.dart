import 'package:flutter/material.dart';
import 'package:quiver/time.dart';

import 'color_selector.dart';
import '../controller.dart';
import '../model.dart';

class SettingsBar extends StatefulWidget {
  final Axis direction;
  final Config config;
  final GraphController controller;

  const SettingsBar(
      {Key key, this.direction = Axis.vertical, this.config, this.controller})
      : super(key: key);

  @override
  _SettingsBarState createState() => _SettingsBarState();
}

class _SettingsBarState extends State<SettingsBar> {
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
    final isMobileScreen = MediaQuery.of(context).size.width <= 900;
    final luminance = widget.config.backgroundColor.computeLuminance();
    final brightness = luminance > 0.5 ? Brightness.light : Brightness.dark;
    final labelStyle = TextStyle(
        color:
            brightness == Brightness.light ? Colors.black54 : Colors.white54);

    return Flex(
      direction: widget.direction,
      crossAxisAlignment: widget.direction == Axis.vertical
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: <Widget>[
        ColorSelector(
          color: widget.config.backgroundColor,
          brightness: brightness,
          label: 'Background',
          onColorSelection: (c) {
            _currentEntry = null;
            widget.controller.backgroundColor = c;
          },
          onOpenOverlay: (entry) => _updateEntry(entry),
        ),
        SizedBox(width: 10),
        ColorSelector(
          color: widget.config.fillColor,
          brightness: brightness,
          label: 'Fill',
          onColorSelection: (c) {
            _currentEntry = null;
            widget.controller.fillColor = c;
          },
          onOpenOverlay: (entry) => _updateEntry(entry),
        ),
        if (!isMobileScreen) ...[
          Row(
            children: <Widget>[
              SizedBox(width: 10),
              Switch(
                value: widget.config.strokeColor != Colors.transparent,
                onChanged: (value) => widget.controller.strokeColor =
                    value ? Colors.black54 : Colors.transparent,
                activeColor: Colors.cyan,
                inactiveThumbColor: Colors.white,
                activeTrackColor: Colors.cyan.shade800,
                inactiveTrackColor: Colors.grey.shade700,
              ),
              ColorSelector(
                color: widget.config.strokeColor,
                brightness: brightness,
                label: isMobileScreen ? '' : 'Stroke',
                onColorSelection: (c) {
                  _currentEntry = null;
                  widget.controller.strokeColor = c;
                },
                onOpenOverlay: (entry) => _updateEntry(entry),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Row(
            children: <Widget>[
              Text('Force', style: labelStyle),
              Switch(
                value: widget.config.applyForce,
                onChanged: (value) {
                  if (!value) _showNoForceOverlay();
                  widget.controller.applyForce = value;
                },
                activeColor: Colors.cyan,
                inactiveThumbColor: Colors.white,
                activeTrackColor: Colors.cyan.shade800,
                inactiveTrackColor: Colors.grey.shade700,
              ),
            ],
          ),
          const SizedBox(width: 15),
          Row(
            children: <Widget>[
              Text('Dynamic color', style: labelStyle),
              Switch(
                value: widget.config.liveColor,
                onChanged: (value) => widget.controller.liveColor = value,
                activeColor: Colors.cyan,
                inactiveThumbColor: Colors.white,
                activeTrackColor: Colors.cyan.shade800,
                inactiveTrackColor: Colors.grey.shade700,
              ),
            ],
          ),
        ]
      ],
    );
  }

  void _showNoForceOverlay() {
    final renderer = context.findRenderObject() as RenderBox;
    final left =
        renderer.size.bottomLeft(renderer.localToGlobal(Offset.zero)).dx;

    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Color(0x66000000),
            width: 200,
            child: Text(
              'Click to draw',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
    Future.delayed(aSecond * 3, () => overlayEntry.remove());

    overlayState.insert(overlayEntry);
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
