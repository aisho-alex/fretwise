import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/domain/models/guitar_position.dart';
import 'package:guitar_trainer/ui/widgets/fretboard_geometry.dart';

void main() {
  test('every position center maps back to the same string and fret', () {
    const geometry = FretboardGeometry(Size(1100, 260));

    for (var string = 1; string <= 6; string++) {
      for (var fret = 0; fret <= 12; fret++) {
        final position = GuitarPosition(stringNumber: string, fret: fret);
        expect(
          geometry.positionAt(geometry.positionRect(position).center),
          position,
        );
      }
    }
  });

  test('open string and outside hit areas are distinct', () {
    const geometry = FretboardGeometry(Size(1100, 260));
    const open = GuitarPosition(stringNumber: 6, fret: 0);
    const first = GuitarPosition(stringNumber: 6, fret: 1);

    expect(
      geometry.positionRect(open).right,
      geometry.positionRect(first).left,
    );
    expect(geometry.positionAt(Offset.zero), isNull);
    expect(geometry.positionAt(const Offset(1099, 259)), isNull);
  });
}
