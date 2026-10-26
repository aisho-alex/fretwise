import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/application/training_controller.dart';
import 'package:guitar_trainer/domain/exercise_generator.dart';
import 'package:guitar_trainer/domain/models/exercise.dart';
import 'package:guitar_trainer/domain/models/guitar_position.dart';

TrainingController createController({int sessionLength = 20}) =>
    TrainingController(
      generator: ExerciseGenerator(random: Random(31)),
      sessionLength: sessionLength,
    );

void answerCorrectly(TrainingController controller) {
  final answers = controller.exercise.answers.toList();
  for (final answer in answers) {
    controller.submit(answer);
  }
}

void main() {
  test('correct answer completes a simple exercise once', () {
    final controller = createController();
    final answer = controller.exercise.answers.single;

    controller.submit(answer);
    controller.submit(answer);

    expect(controller.isAnswered, isTrue);
    expect(controller.answeredCount, 1);
    expect(controller.accuracy, 1);
    expect(controller.feedback, contains('Верно'));

    controller.next();
    expect(controller.questionNumber, 2);
    expect(controller.isAnswered, isFalse);
  });

  test('wrong answer explains the selected and expected notes', () {
    final controller = createController();
    final answer = controller.exercise.answers.single;
    final wrong = GuitarPosition(
      stringNumber: answer.stringNumber,
      fret: answer.fret == 12 ? 11 : answer.fret + 1,
    );

    controller.submit(wrong);

    expect(controller.mistakes, 1);
    expect(controller.isAnswered, isFalse);
    expect(controller.feedback, contains('Ты выбрал'));
    expect(controller.feedback, contains(controller.exercise.note.displayName));
    answerCorrectly(controller);
    expect(controller.accuracy, 0);
  });

  test('all positions are completed one by one', () {
    final controller = createController();
    controller.setMode(ExerciseType.allPositions);
    final answers = controller.exercise.answers.toList();

    controller.submit(answers.first);
    expect(controller.isAnswered, isFalse);
    expect(controller.foundPositions, {answers.first});
    controller.submit(answers.first);
    expect(controller.mistakes, 0);

    for (final answer in answers.skip(1)) {
      controller.submit(answer);
    }
    expect(controller.isAnswered, isTrue);
    expect(controller.feedback, 'Все позиции найдены!');
  });

  test('hints progress from note name to exact position', () {
    final controller = createController();

    expect(controller.hintText, isNull);
    controller.useHint();
    expect(controller.hintText, contains(controller.exercise.note.displayName));
    controller.useHint();
    expect(controller.hintLevel, 2);
    expect(controller.hintedPosition, isNull);
    controller.useHint();
    expect(controller.hintedPosition, controller.exercise.answers.single);
    controller.useHint();
    expect(controller.hintLevel, 3);
  });

  test('last question leads to summary and mistake review', () {
    final controller = createController(sessionLength: 2);
    final answer = controller.exercise.answers.single;
    final wrong = GuitarPosition(
      stringNumber: answer.stringNumber,
      fret: answer.fret + 1,
    );
    final failedExercise = controller.exercise;

    controller.submit(wrong);
    answerCorrectly(controller);
    controller.next();
    answerCorrectly(controller);
    controller.next();

    expect(controller.phase, TrainingPhase.summary);
    expect(controller.results, hasLength(2));
    expect(controller.accuracy, 0.5);
    expect(controller.hasMistakes, isTrue);

    controller.repeatMistakes();
    expect(controller.phase, TrainingPhase.active);
    expect(controller.sessionTarget, 1);
    expect(controller.exercise, same(failedExercise));
  });

  test('mode and note set changes start a fresh session', () {
    final controller = createController();
    answerCorrectly(controller);

    controller.setMode(ExerciseType.onString);
    expect(controller.mode, ExerciseType.onString);
    expect(controller.answeredCount, 0);
    expect(controller.exercise.type, ExerciseType.onString);

    controller.setNoteSet(NoteSet.chromatic);
    expect(controller.noteSet, NoteSet.chromatic);
    expect(controller.answeredCount, 0);
  });
}
