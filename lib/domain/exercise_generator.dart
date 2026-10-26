import 'dart:math';

import 'guitar.dart';
import 'models/exercise.dart';
import 'models/music_note.dart';

final class ExerciseGenerator {
  ExerciseGenerator({Random? random, this.noteSet = NoteSet.naturals})
    : _random = random ?? Random();

  final Random _random;
  NoteSet noteSet;

  Exercise next(ExerciseType type) {
    return switch (type) {
      ExerciseType.firstPosition => _firstPosition(),
      ExerciseType.onString => _onString(),
      ExerciseType.allPositions => _allPositions(),
      ExerciseType.noteSeries => nextSeries(SeriesStage.stage1),
    };
  }

  Exercise nextSeries(SeriesStage stage) {
    final steps = <ExerciseStep>[];
    MusicNote? previousNote;
    while (steps.length < stage.length) {
      final note = _pickNote(
        minFret: stage.minFret,
        maxFret: stage.maxFret,
        noteSet: stage.noteSet,
      );
      if (note.midi == previousNote?.midi) {
        continue;
      }
      final positions = Guitar.positionsFor(
        note,
        minFret: stage.minFret,
        maxFret: stage.maxFret,
      );
      final minimumFret = positions
          .map((position) => position.fret)
          .reduce(min);
      steps.add(
        ExerciseStep(
          note: note,
          answers: positions
              .where((position) => position.fret == minimumFret)
              .toSet(),
        ),
      );
      previousNote = note;
    }
    return Exercise.series(
      type: ExerciseType.noteSeries,
      minFret: stage.minFret,
      maxFret: stage.maxFret,
      steps: steps,
    );
  }

  Exercise _firstPosition() {
    final note = _pickNote(minFret: 0, maxFret: 4);
    final positions = Guitar.positionsFor(note, minFret: 0, maxFret: 4);
    final minimumFret = positions.map((position) => position.fret).reduce(min);
    final answers = positions.where((position) => position.fret == minimumFret);
    return Exercise(
      note: note,
      type: ExerciseType.firstPosition,
      minFret: 0,
      maxFret: 4,
      answers: answers.toSet(),
    );
  }

  Exercise _onString() {
    final stringNumber = _random.nextInt(Guitar.strings.length) + 1;
    final note = _pickNote(minFret: 0, maxFret: 12, stringNumber: stringNumber);
    return Exercise(
      note: note,
      type: ExerciseType.onString,
      stringNumber: stringNumber,
      minFret: 0,
      maxFret: 12,
      answers: Guitar.positionsFor(
        note,
        minFret: 0,
        maxFret: 12,
        stringNumber: stringNumber,
      ),
    );
  }

  Exercise _allPositions() {
    final candidates = _candidateNotes(
      minFret: 0,
      maxFret: 12,
    ).where((note) => Guitar.positionsFor(note).length > 1).toList();
    final note = candidates[_random.nextInt(candidates.length)];
    return Exercise(
      note: note,
      type: ExerciseType.allPositions,
      minFret: 0,
      maxFret: 12,
      answers: Guitar.positionsFor(note),
    );
  }

  MusicNote _pickNote({
    required int minFret,
    required int maxFret,
    int? stringNumber,
    NoteSet? noteSet,
  }) {
    final candidates = _candidateNotes(
      minFret: minFret,
      maxFret: maxFret,
      stringNumber: stringNumber,
      noteSet: noteSet,
    );
    if (candidates.isEmpty) {
      throw StateError('Нет нот для заданного диапазона');
    }
    return candidates[_random.nextInt(candidates.length)];
  }

  List<MusicNote> _candidateNotes({
    required int minFret,
    required int maxFret,
    int? stringNumber,
    NoteSet? noteSet,
  }) {
    const lowestMidi = 40;
    final effectiveNoteSet = noteSet ?? this.noteSet;
    final highestMidi = Guitar.strings.first.openNote.midi + maxFret;
    final result = <MusicNote>[];
    for (var midi = lowestMidi; midi <= highestMidi; midi++) {
      for (final note in MusicNote.spellingsForMidi(midi)) {
        if (effectiveNoteSet == NoteSet.naturals &&
            note.accidental != Accidental.natural) {
          continue;
        }
        final positions = Guitar.positionsFor(
          note,
          minFret: minFret,
          maxFret: maxFret,
          stringNumber: stringNumber,
        );
        if (positions.isNotEmpty) {
          result.add(note);
        }
      }
    }
    return result;
  }
}
