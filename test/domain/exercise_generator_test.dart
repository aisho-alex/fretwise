import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/domain/exercise_generator.dart';
import 'package:guitar_trainer/domain/guitar.dart';
import 'package:guitar_trainer/domain/models/exercise.dart';

void main() {
  test('first position exercises have one minimum-fret answer', () {
    final generator = ExerciseGenerator(random: Random(7));

    for (var index = 0; index < 200; index++) {
      final exercise = generator.next(ExerciseType.firstPosition);
      final allPositions = Guitar.positionsFor(
        exercise.note,
        minFret: 0,
        maxFret: 4,
      );
      final minimum = allPositions.map((position) => position.fret).reduce(min);

      expect(exercise.answers, hasLength(1));
      expect(exercise.answers.single.fret, minimum);
      expect(exercise.answers.single.fret, inInclusiveRange(0, 4));
    }
  });

  test('on-string exercises have one answer on the requested string', () {
    final generator = ExerciseGenerator(random: Random(11));

    for (var index = 0; index < 200; index++) {
      final exercise = generator.next(ExerciseType.onString);

      expect(exercise.answers, hasLength(1));
      expect(exercise.answers.single.stringNumber, exercise.stringNumber);
      expect(Guitar.noteAt(exercise.answers.single).midi, exercise.note.midi);
    }
  });

  test('all-positions exercises contain every valid answer', () {
    final generator = ExerciseGenerator(random: Random(19));

    for (var index = 0; index < 200; index++) {
      final exercise = generator.next(ExerciseType.allPositions);

      expect(exercise.answers.length, greaterThan(1));
      expect(exercise.answers, Guitar.positionsFor(exercise.note));
      for (final answer in exercise.answers) {
        expect(Guitar.noteAt(answer).midi, exercise.note.midi);
      }
    }
  });

  test('chromatic mode generates sharps and flats', () {
    final generator = ExerciseGenerator(
      random: Random(23),
      noteSet: NoteSet.chromatic,
    );
    final names = <String>{};

    for (var index = 0; index < 100; index++) {
      names.add(generator.next(ExerciseType.onString).note.displayName);
    }

    expect(names.any((name) => name.contains('♯')), isTrue);
    expect(names.any((name) => name.contains('♭')), isTrue);
  });
}
