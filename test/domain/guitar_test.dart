import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/domain/guitar.dart';
import 'package:guitar_trainer/domain/models/guitar_position.dart';
import 'package:guitar_trainer/domain/models/music_note.dart';

void main() {
  test('open strings use standard tuning and scientific pitch', () {
    expect(Guitar.strings.map((string) => string.openNote.midi), [
      64,
      59,
      55,
      50,
      45,
      40,
    ]);
    expect(
      Guitar.positionsFor(Guitar.strings.first.openNote),
      contains(const GuitarPosition(stringNumber: 1, fret: 0)),
    );
  });

  test('twelfth fret is one octave above the open string', () {
    const position = GuitarPosition(stringNumber: 1, fret: 12);
    final note = Guitar.noteAt(position);

    expect(note.fullName, 'E5');
    expect(note.midi, Guitar.strings.first.openNote.midi + 12);
  });

  test('guitar notation is written one octave above sounding pitch', () {
    const lowE = MusicNote(letter: NoteLetter.e, octave: 2);

    expect(lowE.midi, 40);
    expect(lowE.writtenForGuitar.fullName, 'E3');
    expect(lowE.writtenForGuitar.midi, 52);
  });

  test('finds every position within twelve frets', () {
    const middleC = MusicNote(letter: NoteLetter.c, octave: 4);

    expect(Guitar.positionsFor(middleC), {
      const GuitarPosition(stringNumber: 2, fret: 1),
      const GuitarPosition(stringNumber: 3, fret: 5),
      const GuitarPosition(stringNumber: 4, fret: 10),
    });
  });

  test('enharmonic spellings have the same positions', () {
    const sharp = MusicNote(
      letter: NoteLetter.c,
      accidental: Accidental.sharp,
      octave: 4,
    );
    const flat = MusicNote(
      letter: NoteLetter.d,
      accidental: Accidental.flat,
      octave: 4,
    );

    expect(sharp.midi, flat.midi);
    expect(sharp.diatonicIndex, isNot(flat.diatonicIndex));
    expect(Guitar.positionsFor(sharp), Guitar.positionsFor(flat));
  });
}
