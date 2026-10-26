import 'guitar_position.dart';
import 'music_note.dart';

enum ExerciseType { firstPosition, onString, allPositions, noteSeries }

enum NoteSet { naturals, chromatic }

enum SeriesStage {
  stage1('Этап 1', '3 ноты · 0–4 лад', 3, 0, 4, NoteSet.naturals),
  stage2('Этап 2', '5 нот · 0–7 ладов', 5, 0, 7, NoteSet.naturals),
  stage3('Этап 3', '7 нот · ♯ и ♭ · 0–12', 7, 0, 12, NoteSet.chromatic);

  const SeriesStage(
    this.label,
    this.description,
    this.length,
    this.minFret,
    this.maxFret,
    this.noteSet,
  );

  final String label;
  final String description;
  final int length;
  final int minFret;
  final int maxFret;
  final NoteSet noteSet;
}

final class ExerciseStep {
  ExerciseStep({required this.note, required Set<GuitarPosition> answers})
    : assert(answers.isNotEmpty),
      answers = Set.unmodifiable(answers);

  final MusicNote note;
  final Set<GuitarPosition> answers;
}

final class Exercise {
  Exercise({
    required MusicNote note,
    required ExerciseType type,
    required int minFret,
    required int maxFret,
    required Set<GuitarPosition> answers,
    int? stringNumber,
  }) : this._(
         note: note,
         type: type,
         minFret: minFret,
         maxFret: maxFret,
         answers: answers,
         stringNumber: stringNumber,
         steps: [ExerciseStep(note: note, answers: answers)],
       );

  factory Exercise.series({
    required ExerciseType type,
    required int minFret,
    required int maxFret,
    required List<ExerciseStep> steps,
  }) {
    assert(steps.isNotEmpty);
    return Exercise._(
      note: steps.first.note,
      type: type,
      minFret: minFret,
      maxFret: maxFret,
      answers: steps.first.answers,
      steps: steps,
    );
  }

  Exercise._({
    required this.note,
    required this.type,
    required this.minFret,
    required this.maxFret,
    required Set<GuitarPosition> answers,
    required List<ExerciseStep> steps,
    this.stringNumber,
  }) : answers = Set.unmodifiable(answers),
       steps = List.unmodifiable(steps);

  final MusicNote note;
  final ExerciseType type;
  final int minFret;
  final int maxFret;
  final int? stringNumber;
  final Set<GuitarPosition> answers;
  final List<ExerciseStep> steps;

  bool get isSeries => type == ExerciseType.noteSeries;
}
