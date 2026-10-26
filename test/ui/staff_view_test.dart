import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/domain/models/music_note.dart';
import 'package:guitar_trainer/ui/widgets/staff_view.dart';

void main() {
  testWidgets('staff renders extreme guitar notes and accidentals', (
    tester,
  ) async {
    const notes = [
      MusicNote(letter: NoteLetter.e, octave: 3),
      MusicNote(letter: NoteLetter.c, accidental: Accidental.sharp, octave: 5),
      MusicNote(letter: NoteLetter.e, accidental: Accidental.flat, octave: 6),
    ];

    for (final note in notes) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 900, child: StaffView(note: note)),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(StaffView), findsOneWidget);
    }
  });

  testWidgets('staff renders a wide note series with the current step', (
    tester,
  ) async {
    const notes = [
      MusicNote(letter: NoteLetter.e, octave: 3),
      MusicNote(letter: NoteLetter.c, accidental: Accidental.sharp, octave: 5),
      MusicNote(letter: NoteLetter.e, accidental: Accidental.flat, octave: 6),
      MusicNote(letter: NoteLetter.a, octave: 4),
      MusicNote(letter: NoteLetter.f, octave: 5),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1000,
            child: StaffView(notes: notes, currentIndex: 2),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.bySemanticsLabel('Серия из 5 нот на нотном стане'),
      findsOneWidget,
    );
  });
}
