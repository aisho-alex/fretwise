import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/domain/exercise_generator.dart';
import 'package:guitar_trainer/domain/guitar.dart';
import 'package:guitar_trainer/domain/models/exercise.dart';
import 'package:guitar_trainer/domain/models/music_note.dart';

void main() {
  test('every stage generates an ordered series with unique answers', () {
    final generator = ExerciseGenerator(random: Random(53));

    for (final stage in SeriesStage.values) {
      final exercise = generator.nextSeries(stage);

      expect(exercise.isSeries, isTrue);
      expect(exercise.steps, hasLength(stage.length));
      expect(exercise.minFret, stage.minFret);
      expect(exercise.maxFret, stage.maxFret);
      expect(exercise.answers, exercise.steps.first.answers);
      for (var index = 0; index < exercise.steps.length; index++) {
        final step = exercise.steps[index];
        expect(step.answers, hasLength(1));
        final answer = step.answers.single;
        expect(answer.fret, inInclusiveRange(stage.minFret, stage.maxFret));
        expect(Guitar.noteAt(answer).midi, step.note.midi);
        if (index > 0) {
          expect(step.note.midi, isNot(exercise.steps[index - 1].note.midi));
        }
        if (stage.noteSet == NoteSet.naturals) {
          expect(step.note.accidental, Accidental.natural);
        }
      }
    }
  });

  test('third stage includes chromatic spellings', () {
    final generator = ExerciseGenerator(random: Random(59));
    final notes = <MusicNote>[];

    for (var index = 0; index < 20; index++) {
      notes.addAll(
        generator.nextSeries(SeriesStage.stage3).steps.map((step) => step.note),
      );
    }

    expect(notes.any((note) => note.accidental != Accidental.natural), isTrue);
  });
}
