import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/domain/models/music_note.dart';

void main() {
  test('natural notes have Russian names', () {
    const notes = [
      MusicNote(letter: NoteLetter.c, octave: 4),
      MusicNote(letter: NoteLetter.d, octave: 4),
      MusicNote(letter: NoteLetter.e, octave: 4),
      MusicNote(letter: NoteLetter.f, octave: 4),
      MusicNote(letter: NoteLetter.g, octave: 4),
      MusicNote(letter: NoteLetter.a, octave: 4),
      MusicNote(letter: NoteLetter.b, octave: 4),
    ];

    expect(notes.map((note) => note.russianName), [
      'До',
      'Ре',
      'Ми',
      'Фа',
      'Соль',
      'Ля',
      'Си',
    ]);
  });

  test('accidentals use Russian suffixes with international names', () {
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

    expect(sharp.localizedName, 'До-диез (C♯)');
    expect(flat.localizedName, 'Ре-бемоль (D♭)');
  });
}
