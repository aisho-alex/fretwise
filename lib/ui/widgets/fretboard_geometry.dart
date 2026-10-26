import 'dart:ui';

import '../../domain/models/guitar_position.dart';

final class FretboardGeometry {
  const FretboardGeometry(this.size);

  final Size size;

  static const left = 56.0;
  static const right = 16.0;
  static const top = 30.0;
  static const bottom = 24.0;
  static const openWidth = 48.0;

  double get fretWidth => (size.width - left - right - openWidth) / 12;
  double get rowHeight => (size.height - top - bottom) / 6;

  double stringCenterY(int stringNumber) =>
      top + (stringNumber - 0.5) * rowHeight;

  double fretCenterX(int fret) {
    if (fret == 0) {
      return left + openWidth / 2;
    }
    return left + openWidth + (fret - 0.5) * fretWidth;
  }

  Rect positionRect(GuitarPosition position) {
    final x = position.fret == 0
        ? left
        : left + openWidth + (position.fret - 1) * fretWidth;
    final width = position.fret == 0 ? openWidth : fretWidth;
    return Rect.fromLTWH(
      x,
      top + (position.stringNumber - 1) * rowHeight,
      width,
      rowHeight,
    );
  }

  GuitarPosition? positionAt(Offset point) {
    for (var stringNumber = 1; stringNumber <= 6; stringNumber++) {
      for (var fret = 0; fret <= 12; fret++) {
        final position = GuitarPosition(stringNumber: stringNumber, fret: fret);
        if (positionRect(position).contains(point)) {
          return position;
        }
      }
    }
    return null;
  }
}
