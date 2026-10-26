enum NoteLetter {
  c(0, 0, 'C', 'До'),
  d(2, 1, 'D', 'Ре'),
  e(4, 2, 'E', 'Ми'),
  f(5, 3, 'F', 'Фа'),
  g(7, 4, 'G', 'Соль'),
  a(9, 5, 'A', 'Ля'),
  b(11, 6, 'B', 'Си');

  const NoteLetter(this.semitone, this.step, this.label, this.russianLabel);

  final int semitone;
  final int step;
  final String label;
  final String russianLabel;
}

enum Accidental {
  flat(-1, '♭'),
  natural(0, ''),
  sharp(1, '♯');

  const Accidental(this.offset, this.symbol);

  final int offset;
  final String symbol;
}

final class MusicNote {
  const MusicNote({
    required this.letter,
    this.accidental = Accidental.natural,
    required this.octave,
  });

  final NoteLetter letter;
  final Accidental accidental;
  final int octave;

  int get midi => 12 * (octave + 1) + letter.semitone + accidental.offset;

  int get diatonicIndex => octave * 7 + letter.step;

  String get displayName => '${letter.label}${accidental.symbol}';

  String get russianName {
    final suffix = switch (accidental) {
      Accidental.flat => '-бемоль',
      Accidental.natural => '',
      Accidental.sharp => '-диез',
    };
    return '${letter.russianLabel}$suffix';
  }

  String get localizedName => '$russianName ($displayName)';

  String get fullName => '$displayName$octave';

  MusicNote get writtenForGuitar =>
      MusicNote(letter: letter, accidental: accidental, octave: octave + 1);

  static List<MusicNote> spellingsForMidi(int midi) {
    final octave = midi ~/ 12 - 1;
    final pitchClass = midi % 12;

    return switch (pitchClass) {
      0 => [MusicNote(letter: NoteLetter.c, octave: octave)],
      1 => [
        MusicNote(
          letter: NoteLetter.c,
          accidental: Accidental.sharp,
          octave: octave,
        ),
        MusicNote(
          letter: NoteLetter.d,
          accidental: Accidental.flat,
          octave: octave,
        ),
      ],
      2 => [MusicNote(letter: NoteLetter.d, octave: octave)],
      3 => [
        MusicNote(
          letter: NoteLetter.d,
          accidental: Accidental.sharp,
          octave: octave,
        ),
        MusicNote(
          letter: NoteLetter.e,
          accidental: Accidental.flat,
          octave: octave,
        ),
      ],
      4 => [MusicNote(letter: NoteLetter.e, octave: octave)],
      5 => [MusicNote(letter: NoteLetter.f, octave: octave)],
      6 => [
        MusicNote(
          letter: NoteLetter.f,
          accidental: Accidental.sharp,
          octave: octave,
        ),
        MusicNote(
          letter: NoteLetter.g,
          accidental: Accidental.flat,
          octave: octave,
        ),
      ],
      7 => [MusicNote(letter: NoteLetter.g, octave: octave)],
      8 => [
        MusicNote(
          letter: NoteLetter.g,
          accidental: Accidental.sharp,
          octave: octave,
        ),
        MusicNote(
          letter: NoteLetter.a,
          accidental: Accidental.flat,
          octave: octave,
        ),
      ],
      9 => [MusicNote(letter: NoteLetter.a, octave: octave)],
      10 => [
        MusicNote(
          letter: NoteLetter.a,
          accidental: Accidental.sharp,
          octave: octave,
        ),
        MusicNote(
          letter: NoteLetter.b,
          accidental: Accidental.flat,
          octave: octave,
        ),
      ],
      11 => [MusicNote(letter: NoteLetter.b, octave: octave)],
      _ => throw ArgumentError.value(midi, 'midi'),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is MusicNote &&
      other.letter == letter &&
      other.accidental == accidental &&
      other.octave == octave;

  @override
  int get hashCode => Object.hash(letter, accidental, octave);

  @override
  String toString() => fullName;
}
