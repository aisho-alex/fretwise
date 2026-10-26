final class GuitarPosition {
  const GuitarPosition({required this.stringNumber, required this.fret})
    : assert(stringNumber >= 1 && stringNumber <= 6),
      assert(fret >= 0);

  final int stringNumber;
  final int fret;

  String get locationLabel {
    final string = switch (stringNumber) {
      1 => '1-й',
      2 => '2-й',
      3 => '3-й',
      _ => '$stringNumber-й',
    };
    return '$string струна, $fret-й лад';
  }

  @override
  bool operator ==(Object other) =>
      other is GuitarPosition &&
      other.stringNumber == stringNumber &&
      other.fret == fret;

  @override
  int get hashCode => Object.hash(stringNumber, fret);

  @override
  String toString() => '($stringNumber, $fret)';
}
