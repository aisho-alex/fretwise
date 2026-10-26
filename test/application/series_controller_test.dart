import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/application/training_controller.dart';
import 'package:guitar_trainer/domain/exercise_generator.dart';
import 'package:guitar_trainer/domain/models/exercise.dart';
import 'package:guitar_trainer/domain/models/guitar_position.dart';

TrainingController createController() =>
    TrainingController(generator: ExerciseGenerator(random: Random(61)));

void main() {
  test('series advances in order and completes only after the last note', () {
    final controller = createController()..setMode(ExerciseType.noteSeries);
    final series = controller.exercise;

    expect(controller.sessionTarget, 5);
    expect(series.steps, hasLength(3));
    expect(controller.currentStepIndex, 0);

    final firstAnswer = controller.currentStep.answers.single;
    controller.submit(firstAnswer);

    expect(controller.currentStepIndex, 1);
    expect(controller.answeredCount, 0);
    expect(controller.isAnswered, isFalse);
    expect(controller.foundPositions, contains(firstAnswer));
    controller.next();
    expect(controller.currentStepIndex, 1);

    for (final step in series.steps.skip(1)) {
      controller.submit(step.answers.single);
    }

    expect(controller.isAnswered, isTrue);
    expect(controller.answeredCount, 1);
    expect(controller.feedback, 'Серия завершена!');
    controller.next();
    expect(controller.currentStepIndex, 0);
    expect(controller.questionNumber, 2);
  });

  test(
    'hints reset per note and mistakes are attributed to the current note',
    () {
      final controller = createController()..setMode(ExerciseType.noteSeries);
      final series = controller.exercise;

      controller.useHint();
      expect(controller.hintLevel, 1);
      controller.submit(series.steps[0].answers.single);
      expect(controller.hintLevel, 0);

      final secondAnswer = series.steps[1].answers.single;
      controller.submit(
        GuitarPosition(
          stringNumber: secondAnswer.stringNumber,
          fret: secondAnswer.fret + 1,
        ),
      );
      controller.submit(secondAnswer);
      controller.submit(series.steps[2].answers.single);

      expect(controller.results.single.hints, 1);
      expect(controller.results.single.mistakes, 1);
      expect(controller.results.single.mistakenNotes, [series.steps[1].note]);
      expect(
        controller.weakNotes.single.key,
        series.steps[1].note.localizedName,
      );
    },
  );

  test('all stages are freely selectable', () {
    final controller = createController()..setMode(ExerciseType.noteSeries);

    controller.setSeriesStage(SeriesStage.stage3);

    expect(controller.seriesStage, SeriesStage.stage3);
    expect(controller.exercise.steps, hasLength(7));
    expect(controller.exercise.maxFret, 12);
    expect(controller.answeredCount, 0);
  });
}
