import 'package:flutter/foundation.dart';

import '../domain/exercise_generator.dart';
import '../domain/guitar.dart';
import '../domain/models/exercise.dart';
import '../domain/models/guitar_position.dart';
import '../domain/models/music_note.dart';

enum TrainingPhase { active, summary }

final class QuestionResult {
  const QuestionResult({
    required this.exercise,
    required this.mistakes,
    required this.hints,
    this.mistakenNotes = const [],
  });

  final Exercise exercise;
  final int mistakes;
  final int hints;
  final List<MusicNote> mistakenNotes;
}

final class TrainingController extends ChangeNotifier {
  TrainingController({ExerciseGenerator? generator, this.sessionLength = 20})
    : _generator = generator ?? ExerciseGenerator() {
    startSession();
  }

  final ExerciseGenerator _generator;
  final int sessionLength;
  final List<QuestionResult> _results = [];
  final List<MusicNote> _mistakenNotes = [];

  ExerciseType _mode = ExerciseType.firstPosition;
  SeriesStage _seriesStage = SeriesStage.stage1;
  TrainingPhase _phase = TrainingPhase.active;
  late Exercise _exercise;
  List<Exercise> _reviewQueue = [];
  late int _sessionTarget;
  int _answeredCount = 0;
  int _currentStepIndex = 0;
  int _mistakes = 0;
  int _hintLevel = 0;
  int _hintsUsed = 0;
  Set<GuitarPosition> _foundPositions = {};
  Set<GuitarPosition> _completedPositions = {};
  GuitarPosition? _selectedPosition;
  bool? _lastAnswerCorrect;
  String _feedback = '';

  Exercise get exercise => _exercise;
  ExerciseType get mode => _mode;
  SeriesStage get seriesStage => _seriesStage;
  NoteSet get noteSet => _generator.noteSet;
  TrainingPhase get phase => _phase;
  int get answeredCount => _answeredCount;
  int get sessionTarget => _sessionTarget;
  int get questionNumber => _answeredCount + (isAnswered ? 0 : 1);
  int get currentStepIndex => _currentStepIndex;
  ExerciseStep get currentStep => _exercise.steps[_currentStepIndex];
  MusicNote get currentNote => currentStep.note;
  int get hintLevel => _hintLevel;
  int get mistakes => _mistakes;
  GuitarPosition? get selectedPosition => _selectedPosition;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;
  String get feedback => _feedback;
  Set<GuitarPosition> get foundPositions =>
      Set.unmodifiable({..._completedPositions, ..._foundPositions});
  List<QuestionResult> get results => List.unmodifiable(_results);
  bool get isStepAnswered =>
      _foundPositions.length == currentStep.answers.length;
  bool get isAnswered =>
      isStepAnswered && _currentStepIndex == _exercise.steps.length - 1;
  bool get hasMistakes => _results.any((result) => result.mistakes > 0);

  double get accuracy {
    if (_results.isEmpty) {
      return 0;
    }
    final cleanAnswers = _results
        .where((result) => result.mistakes == 0)
        .length;
    return cleanAnswers / _results.length;
  }

  int get totalHints =>
      _results.fold(0, (total, result) => total + result.hints);

  List<MapEntry<String, int>> get weakNotes {
    final mistakes = <String, int>{};
    for (final result in _results) {
      for (final note in result.mistakenNotes) {
        final name = note.localizedName;
        mistakes.update(name, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final entries = mistakes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String? get hintText {
    if (_hintLevel == 0) {
      return null;
    }
    if (_hintLevel == 1) {
      return 'Нота: ${currentNote.localizedName}';
    }

    final remaining = currentStep.answers
        .where((position) => !_foundPositions.contains(position))
        .toList();
    if (remaining.isEmpty) {
      return null;
    }
    final position = remaining.first;
    if (_hintLevel == 3) {
      return 'Точная позиция: ${position.locationLabel}';
    }

    return switch (_exercise.type) {
      ExerciseType.firstPosition ||
      ExerciseType.noteSeries => 'Ищи на ${position.stringNumber}-й струне',
      ExerciseType.onString => _regionHint(position.fret),
      ExerciseType.allPositions =>
        'Одна из оставшихся позиций — на ${position.stringNumber}-й струне',
    };
  }

  GuitarPosition? get hintedPosition {
    if (_hintLevel < 3 || isAnswered) {
      return null;
    }
    return currentStep.answers
        .where((position) => !_foundPositions.contains(position))
        .firstOrNull;
  }

  void setMode(ExerciseType value) {
    if (_mode == value && _phase == TrainingPhase.active) {
      return;
    }
    _mode = value;
    startSession();
  }

  void setSeriesStage(SeriesStage value) {
    if (_seriesStage == value && _phase == TrainingPhase.active) {
      return;
    }
    _seriesStage = value;
    startSession();
  }

  void setNoteSet(NoteSet value) {
    if (_generator.noteSet == value && _phase == TrainingPhase.active) {
      return;
    }
    _generator.noteSet = value;
    startSession();
  }

  void startSession() {
    _beginSession(null);
  }

  void repeatMistakes() {
    final review = _results
        .where((result) => result.mistakes > 0)
        .map((result) => result.exercise)
        .toList();
    if (review.isEmpty) {
      return;
    }
    _beginSession(review);
  }

  void submit(GuitarPosition position) {
    if (_phase != TrainingPhase.active || isAnswered) {
      return;
    }
    if (_foundPositions.contains(position)) {
      _feedback = 'Эта позиция уже найдена';
      notifyListeners();
      return;
    }

    _selectedPosition = position;
    if (currentStep.answers.contains(position)) {
      _lastAnswerCorrect = true;
      _foundPositions = {..._foundPositions, position};
      if (isAnswered) {
        _results.add(
          QuestionResult(
            exercise: _exercise,
            mistakes: _mistakes,
            hints: _hintsUsed,
            mistakenNotes: List.unmodifiable(_mistakenNotes),
          ),
        );
        _answeredCount++;
        _feedback = switch (_exercise.type) {
          ExerciseType.allPositions => 'Все позиции найдены!',
          ExerciseType.noteSeries => 'Серия завершена!',
          _ => 'Верно: ${position.locationLabel}',
        };
      } else if (_exercise.isSeries) {
        _completedPositions = {..._completedPositions, ..._foundPositions};
        _currentStepIndex++;
        _foundPositions = {};
        _selectedPosition = null;
        _hintLevel = 0;
        _feedback =
            'Верно! Нота ${_currentStepIndex + 1} из ${_exercise.steps.length}';
      } else {
        _feedback =
            'Верно! Найдено ${_foundPositions.length} из ${currentStep.answers.length}';
      }
    } else {
      _lastAnswerCorrect = false;
      _mistakes++;
      _mistakenNotes.add(currentNote);
      final selectedNote = Guitar.noteAt(
        position,
        preferFlats: currentNote.accidental == Accidental.flat,
      );
      _feedback =
          'Ты выбрал ${selectedNote.localizedName} · ${position.locationLabel}. '
          'Нужно найти ${currentNote.localizedName}.';
    }
    notifyListeners();
  }

  void useHint() {
    if (_phase != TrainingPhase.active || isAnswered || _hintLevel >= 3) {
      return;
    }
    _hintLevel++;
    _hintsUsed++;
    notifyListeners();
  }

  void next() {
    if (_phase != TrainingPhase.active || !isAnswered) {
      return;
    }
    if (_answeredCount >= _sessionTarget) {
      _phase = TrainingPhase.summary;
      notifyListeners();
      return;
    }
    _loadNextExercise();
  }

  void _beginSession(List<Exercise>? review) {
    _results.clear();
    _reviewQueue = List.of(review ?? const []);
    _sessionTarget =
        review?.length ??
        (_mode == ExerciseType.noteSeries ? 5 : sessionLength);
    _answeredCount = 0;
    _phase = TrainingPhase.active;
    _loadNextExercise();
  }

  void _loadNextExercise() {
    _exercise = _reviewQueue.isEmpty
        ? (_mode == ExerciseType.noteSeries
              ? _generator.nextSeries(_seriesStage)
              : _generator.next(_mode))
        : _reviewQueue.removeAt(0);
    _currentStepIndex = 0;
    _mistakes = 0;
    _mistakenNotes.clear();
    _hintLevel = 0;
    _hintsUsed = 0;
    _foundPositions = {};
    _completedPositions = {};
    _selectedPosition = null;
    _lastAnswerCorrect = null;
    _feedback = '';
    notifyListeners();
  }

  String _regionHint(int fret) {
    final lower = (fret - 2).clamp(_exercise.minFret, _exercise.maxFret);
    final upper = (fret + 2).clamp(_exercise.minFret, _exercise.maxFret);
    if (lower == upper) {
      return 'Это $lower-й лад';
    }
    return 'Ищи с $lower-го по $upper-й лад';
  }
}
