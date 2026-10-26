import 'package:flutter/material.dart';

import '../../domain/guitar.dart';
import '../../domain/models/guitar_position.dart';
import 'fretboard_geometry.dart';

class FretboardView extends StatefulWidget {
  const FretboardView({
    super.key,
    required this.onPositionSelected,
    required this.onOpenStringPlay,
    required this.enabled,
    required this.foundPositions,
    required this.minFret,
    required this.maxFret,
    this.selectedPosition,
    this.lastAnswerCorrect,
    this.hintedPosition,
    this.height = 260,
  });

  final ValueChanged<GuitarPosition> onPositionSelected;
  final ValueChanged<GuitarString> onOpenStringPlay;
  final bool enabled;
  final Set<GuitarPosition> foundPositions;
  final GuitarPosition? selectedPosition;
  final bool? lastAnswerCorrect;
  final GuitarPosition? hintedPosition;
  final int minFret;
  final int maxFret;
  final double height;

  @override
  State<FretboardView> createState() => _FretboardViewState();
}

class _FretboardViewState extends State<FretboardView> {
  GuitarPosition? _hoveredPosition;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Гитарный гриф, двенадцать ладов',
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final geometry = FretboardGeometry(
              Size(constraints.maxWidth, widget.height),
            );
            return MouseRegion(
              cursor: widget.enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              onHover: (event) {
                if (!widget.enabled) {
                  return;
                }
                setState(() {
                  _hoveredPosition = geometry.positionAt(event.localPosition);
                });
              },
              onExit: (_) => setState(() => _hoveredPosition = null),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  if (!widget.enabled) {
                    return;
                  }
                  final position = geometry.positionAt(details.localPosition);
                  if (position != null &&
                      position.fret >= widget.minFret &&
                      position.fret <= widget.maxFret) {
                    widget.onPositionSelected(position);
                  }
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FretboardPainter(
                          geometry: geometry,
                          hoveredPosition: _hoveredPosition,
                          selectedPosition: widget.selectedPosition,
                          lastAnswerCorrect: widget.lastAnswerCorrect,
                          foundPositions: widget.foundPositions,
                          hintedPosition: widget.hintedPosition,
                          minFret: widget.minFret,
                          maxFret: widget.maxFret,
                        ),
                      ),
                    ),
                    for (final string in Guitar.strings)
                      Positioned(
                        left: 2,
                        top: geometry.stringCenterY(string.number) - 18,
                        width: 52,
                        height: 36,
                        child: _OpenStringButton(
                          string: string,
                          onPressed: () => widget.onOpenStringPlay(string),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OpenStringButton extends StatelessWidget {
  const _OpenStringButton({required this.string, required this.onPressed});

  final GuitarString string;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Слушать открытую струну: ${string.openNote.localizedName}',
      child: TextButton.icon(
        key: Key('open-string-${string.number}'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: const Color(0xFFC4CEC8),
        ),
        icon: const Icon(Icons.volume_up_outlined, size: 16),
        label: Text(
          '${string.number} ${string.openNote.displayName}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class FretboardPainter extends CustomPainter {
  const FretboardPainter({
    required this.geometry,
    required this.foundPositions,
    required this.minFret,
    required this.maxFret,
    this.hoveredPosition,
    this.selectedPosition,
    this.lastAnswerCorrect,
    this.hintedPosition,
  });

  final FretboardGeometry geometry;
  final GuitarPosition? hoveredPosition;
  final GuitarPosition? selectedPosition;
  final bool? lastAnswerCorrect;
  final Set<GuitarPosition> foundPositions;
  final GuitarPosition? hintedPosition;
  final int minFret;
  final int maxFret;

  @override
  void paint(Canvas canvas, Size size) {
    final boardRect = Rect.fromLTRB(
      FretboardGeometry.left,
      FretboardGeometry.top,
      size.width - FretboardGeometry.right,
      size.height - FretboardGeometry.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF594334),
    );

    for (var string = 1; string <= 6; string++) {
      for (var fret = 0; fret <= 12; fret++) {
        final position = GuitarPosition(stringNumber: string, fret: fret);
        if (fret < minFret || fret > maxFret) {
          canvas.drawRect(
            geometry.positionRect(position),
            Paint()..color = const Color(0x66000000),
          );
        }
      }
    }

    _drawInlays(canvas, size);
    _drawFrets(canvas, size);
    _drawStrings(canvas, size);
    _drawLabels(canvas, size);

    if (hoveredPosition != null && !foundPositions.contains(hoveredPosition)) {
      _drawMarker(
        canvas,
        hoveredPosition!,
        fill: const Color(0x22000000),
        border: const Color(0x88FFFFFF),
      );
    }
    for (final position in foundPositions) {
      _drawMarker(
        canvas,
        position,
        fill: const Color(0xFF4CAF7D),
        border: const Color(0xFFB9F6D2),
      );
    }
    if (selectedPosition != null && lastAnswerCorrect == false) {
      _drawMarker(
        canvas,
        selectedPosition!,
        fill: const Color(0xFFD06464),
        border: const Color(0xFFFFB4AB),
      );
    }
    if (hintedPosition != null) {
      _drawMarker(
        canvas,
        hintedPosition!,
        fill: const Color(0x66E9B949),
        border: const Color(0xFFFFDE8A),
      );
    }
  }

  void _drawFrets(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB7A99A)
      ..strokeWidth = 1.4;
    final bottom = size.height - FretboardGeometry.bottom;
    for (var fret = 0; fret <= 12; fret++) {
      final x =
          FretboardGeometry.left +
          FretboardGeometry.openWidth +
          fret * geometry.fretWidth;
      canvas.drawLine(
        Offset(x, FretboardGeometry.top),
        Offset(x, bottom),
        fret == 0
            ? (Paint()
                ..color = const Color(0xFFE7DED1)
                ..strokeWidth = 5)
            : paint,
      );
    }
  }

  void _drawStrings(Canvas canvas, Size size) {
    for (final string in Guitar.strings) {
      final y = geometry.stringCenterY(string.number);
      canvas.drawLine(
        Offset(FretboardGeometry.left + 4, y),
        Offset(size.width - FretboardGeometry.right, y),
        Paint()
          ..color = const Color(0xFFD8D1C5)
          ..strokeWidth = 1 + string.number * 0.22,
      );
    }
  }

  void _drawInlays(Canvas canvas, Size size) {
    final centerY =
        (FretboardGeometry.top + size.height - FretboardGeometry.bottom) / 2;
    final paint = Paint()..color = const Color(0x30F1E6D6);
    for (final fret in const [3, 5, 7, 9]) {
      canvas.drawCircle(Offset(geometry.fretCenterX(fret), centerY), 9, paint);
    }
    for (final offset in [-geometry.rowHeight, geometry.rowHeight]) {
      canvas.drawCircle(
        Offset(geometry.fretCenterX(12), centerY + offset),
        8,
        paint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    for (var fret = 0; fret <= 12; fret++) {
      final painter = _textPainter('$fret', 12, const Color(0xFF9EACA4));
      painter.paint(
        canvas,
        Offset(geometry.fretCenterX(fret) - painter.width / 2, 7),
      );
    }
  }

  void _drawMarker(
    Canvas canvas,
    GuitarPosition position, {
    required Color fill,
    required Color border,
  }) {
    final center = Offset(
      geometry.fretCenterX(position.fret),
      geometry.stringCenterY(position.stringNumber),
    );
    final radius = (geometry.rowHeight * 0.28).clamp(9.0, 15.0);
    canvas.drawCircle(center, radius, Paint()..color = fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  TextPainter _textPainter(String text, double fontSize, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(FretboardPainter oldDelegate) => true;
}
