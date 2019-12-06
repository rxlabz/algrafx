import 'dart:math';

import 'package:algrafx/model.dart';
import 'package:flutter/material.dart';

class ColorSelector extends StatefulWidget {
  final Color color;

  final String label;

  final Brightness brightness;

  final ValueChanged<Color> onColorSelection;
  final ValueChanged<Future<OverlayEntry>> onOpenOverlay;

  const ColorSelector({
    Key key,
    @required this.color,
    @required this.brightness,
    @required this.label,
    this.onColorSelection,
    this.onOpenOverlay,
  }) : super(key: key);

  @override
  _ColorSelectorState createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  Future<OverlayEntry> colorPicker;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.brightness == Brightness.light ? Colors.black54 : Colors.white54;
    return Row(
      children: <Widget>[
        Text(
          widget.label,
          style: TextStyle(color: labelColor.withOpacity(0.7)),
        ),
        InkWell(
          onTap: () {
            if (colorPicker != null) {
              widget.onOpenOverlay(null);
              colorPicker = null;
              setState(() {});
            } else {
              colorPicker = _openColorPicker(context);
              widget.onOpenOverlay(colorPicker);
            }
          },
          child: Container(
            margin: EdgeInsets.all(8),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: labelColor, width: 2),
              color: widget.color,
            ),
          ),
        ),
      ],
    );
  }

  Future<OverlayEntry> _openColorPicker(BuildContext context) async {
    final renderer = context.findRenderObject() as RenderBox;
    final left =
        renderer.size.bottomRight(renderer.localToGlobal(Offset.zero)).dx;

    OverlayState overlayState = Overlay.of(context);
    OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (_) => _buildColorPicker(
        context,
        left,
        () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
    return overlayEntry;
  }

  Widget _buildColorPicker(
    BuildContext context,
    double left,
    VoidCallback onSelect,
  ) =>
      Positioned(
        top: 50.0,
        left: max(left - 120, 0),
        child: _ColorPickerGrid(
          currentColor: widget.color,
          onSelect: () {
            onSelect();
            colorPicker = null;
            setState(() {});
          },
          onColorSelection: (c) {
            widget.onColorSelection(c);
            colorPicker = null;
            setState(() {});
          },
        ),
      );
}

class _ColorPickerGrid extends StatefulWidget {
  final ValueChanged<Color> onColorSelection;
  final VoidCallback onSelect;
  final Color currentColor;

  const _ColorPickerGrid({
    Key key,
    this.onColorSelection,
    this.onSelect,
    this.currentColor,
  }) : super(key: key);

  @override
  __ColorPickerGridState createState() => __ColorPickerGridState();
}

class __ColorPickerGridState extends State<_ColorPickerGrid> {
  Color currentColor;

  @override
  void initState() {
    currentColor = widget.currentColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Material(
        color: Color(0x66333333),
        child: MouseRegion(
          onExit: (_) => widget.onSelect(),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 6,
            children: [...Colors.primaries, Colors.white, Colors.black, fGrey]
                .map((c) => InkWell(
                      onTap: () {
                        widget.onSelect();
                        widget.onColorSelection(c);
                      },
                      child: Container(
                        margin: EdgeInsets.all(
                            c.value == currentColor.value ? 13 : 8),
                        width: c.value == currentColor.value ? 8 : 18,
                        height: c.value == currentColor.value ? 8 : 18,
                        color: c,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
