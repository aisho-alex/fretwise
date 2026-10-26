import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guitar_trainer/application/note_player.dart';
import 'package:guitar_trainer/application/training_controller.dart';
import 'package:guitar_trainer/domain/exercise_generator.dart';
import 'package:guitar_trainer/domain/models/guitar_position.dart';
import 'package:guitar_trainer/domain/models/music_note.dart';
import 'package:guitar_trainer/ui/screens/training_screen.dart';
import 'package:guitar_trainer/ui/widgets/fretboard_geometry.dart';
import 'package:guitar_trainer/ui/widgets/fretboard_view.dart';

final class FakeNotePlayer implements NotePlayer {
  final playedMidi = <int>[];

  @override
  Future<void> playNote(MusicNote note) async {
    playedMidi.add(note.midi);
  }

  @override
  void dispose() {}
}

Future<TrainingController> pumpTraining(
  WidgetTester tester, {
  int sessionLength = 20,
  NotePlayer? notePlayer,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = TrainingController(
    generator: ExerciseGenerator(random: Random(41)),
    sessionLength: sessionLength,
  );
  final player = notePlayer ?? FakeNotePlayer();
  addTearDown(controller.dispose);
  addTearDown(player.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: TrainingScreen(controller: controller, notePlayer: player),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> tapPosition(WidgetTester tester, GuitarPosition position) async {
  final finder = find.byType(FretboardView);
  final geometry = FretboardGeometry(tester.getSize(finder));
  await tester.tapAt(
    tester.getTopLeft(finder) + geometry.positionRect(position).center,
  );
  await tester.pump();
}

void main() {
  testWidgets('answer and advance through the real fretboard', (tester) async {
    final controller = await pumpTraining(tester);

    expect(find.text('Найди ноту в первой позиции'), findsOneWidget);
    expect(find.text('Вопрос 1 из 20'), findsOneWidget);
    await tapPosition(tester, controller.exercise.answers.single);

    expect(controller.isAnswered, isTrue);
    expect(find.textContaining('Верно:'), findsOneWidget);
    await tester.tap(find.byKey(const Key('next-button')));
    await tester.pump();
    expect(find.text('Вопрос 2 из 20'), findsOneWidget);
  });

  testWidgets('wrong fret shows explanatory feedback', (tester) async {
    final controller = await pumpTraining(tester);
    final exercise = controller.exercise;
    GuitarPosition? wrong;
    for (var string = 1; string <= 6 && wrong == null; string++) {
      for (var fret = exercise.minFret; fret <= exercise.maxFret; fret++) {
        final candidate = GuitarPosition(stringNumber: string, fret: fret);
        if (!exercise.answers.contains(candidate)) {
          wrong = candidate;
          break;
        }
      }
    }

    await tapPosition(tester, wrong!);

    expect(controller.mistakes, 1);
    expect(find.textContaining('Ты выбрал'), findsOneWidget);
    expect(find.byKey(const Key('next-button')), findsOneWidget);
    expect(controller.isAnswered, isFalse);
  });

  testWidgets('hints and all-positions mode work through the UI', (
    tester,
  ) async {
    final controller = await pumpTraining(tester);
    await tester.tap(find.byKey(const Key('mode-allPositions')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('hint-button')));
    await tester.pump();
    expect(find.textContaining('Нота:'), findsOneWidget);
    expect(controller.hintLevel, 1);

    for (final answer in controller.exercise.answers) {
      await tapPosition(tester, answer);
    }
    expect(controller.isAnswered, isTrue);
    expect(find.text('Все позиции найдены!'), findsOneWidget);
  });

  testWidgets('completed session shows summary and starts again', (
    tester,
  ) async {
    final controller = await pumpTraining(tester, sessionLength: 1);
    await tapPosition(tester, controller.exercise.answers.single);
    await tester.tap(find.byKey(const Key('next-button')));
    await tester.pumpAndSettle();

    expect(controller.phase, TrainingPhase.summary);
    expect(find.text('Сессия завершена'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('new-session-button')));
    await tester.pump();
    expect(controller.phase, TrainingPhase.active);
    expect(find.text('Вопрос 1 из 1'), findsOneWidget);
  });

  testWidgets('all open strings and answered positions play their notes', (
    tester,
  ) async {
    final player = FakeNotePlayer();
    final controller = await pumpTraining(tester, notePlayer: player);

    for (var string = 1; string <= 6; string++) {
      await tester.tap(find.byKey(Key('open-string-$string')));
      await tester.pump();
    }

    expect(player.playedMidi, [64, 59, 55, 50, 45, 40]);
    expect(controller.answeredCount, 0);
    expect(controller.mistakes, 0);

    await tapPosition(tester, controller.exercise.answers.single);
    expect(player.playedMidi.last, controller.exercise.note.midi);
  });

  testWidgets('note series runs through every stage step in order', (
    tester,
  ) async {
    final controller = await pumpTraining(tester);
    await tester.tap(find.byKey(const Key('mode-noteSeries')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('series-stage-stage3')));
    await tester.pump();

    final series = controller.exercise;
    expect(series.steps, hasLength(7));
    expect(find.text('Отметь серию нот по порядку'), findsOneWidget);
    expect(find.text('Серия 1 из 5'), findsOneWidget);

    for (var index = 0; index < series.steps.length; index++) {
      await tapPosition(tester, series.steps[index].answers.single);
      if (index < series.steps.length - 1) {
        expect(controller.currentStepIndex, index + 1);
        expect(
          find.text('Нота ${index + 2} из 7 · минимальный лад · диапазон 0–12'),
          findsOneWidget,
        );
      }
    }

    expect(controller.isAnswered, isTrue);
    expect(controller.answeredCount, 1);
    expect(find.text('Серия завершена!'), findsOneWidget);
  });
}
