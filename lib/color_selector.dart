import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final Color color;

  final Axis direction;

  final ValueChanged<Color> onColorSelection;

  const ColorSelector(
      {Key key,
      this.color,
      this.direction = Axis.horizontal,
      this.onColorSelection})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Flex(
        direction: direction,
        children: Colors.primaries
            .map((c) => InkWell(
                  onTap: () => onColorSelection(c),
                  child: Container(
                    margin: EdgeInsets.all(c.value == color.value ? 13 : 8),
                    width: c.value == color.value ? 8 : 18,
                    height: c.value == color.value ? 8 : 18,
                    color: c,
                  ),
                ))
            .toList(),
      );
}
