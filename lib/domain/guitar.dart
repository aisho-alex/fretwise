import 'models/guitar_position.dart';
import 'models/music_note.dart';

final class GuitarString {
  const GuitarString({required this.number, required this.openNote});

  final int number;
  final MusicNote openNote;
}

abstract final class Guitar {
  static const strings = [
    GuitarString(
      number: 1,
      openNote: MusicNote(letter: NoteLetter.e, octave: 4),
    ),
    GuitarString(
      number: 2,
      openNote: MusicNote(letter: NoteLetter.b, octave: 3),
    ),
    GuitarString(
      number: 3,
      openNote: MusicNote(letter: NoteLetter.g, octave: 3),
    ),
    GuitarString(
      number: 4,
      openNote: MusicNote(letter: NoteLetter.d, octave: 3),
    ),
    GuitarString(
      number: 5,
      openNote: MusicNote(letter: NoteLetter.a, octave: 2),
    ),
    GuitarString(
      number: 6,
      openNote: MusicNote(letter: NoteLetter.e, octave: 2),
    ),
  ];

  static Set<GuitarPosition> positionsFor(
    MusicNote note, {
    int minFret = 0,
    int maxFret = 12,
    int? stringNumber,
  }) {
    final result = <GuitarPosition>{};
    for (final string in strings) {
      if (stringNumber != null && string.number != stringNumber) {
        continue;
      }
      final fret = note.midi - string.openNote.midi;
      if (fret >= minFret && fret <= maxFret) {
        result.add(GuitarPosition(stringNumber: string.number, fret: fret));
      }
    }
    return result;
  }

  static MusicNote noteAt(GuitarPosition position, {bool preferFlats = false}) {
    final string = strings.firstWhere(
      (item) => item.number == position.stringNumber,
    );
    final spellings = MusicNote.spellingsForMidi(
      string.openNote.midi + position.fret,
    );
    if (preferFlats && spellings.length > 1) {
      return spellings.last;
    }
    return spellings.first;
  }
}
