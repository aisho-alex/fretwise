import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/note_player.dart';
import '../../application/training_controller.dart';
import '../../domain/guitar.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/music_note.dart';
import '../widgets/fretboard_view.dart';
import '../widgets/staff_view.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key, this.controller, this.notePlayer});

  final TrainingController? controller;
  final NotePlayer? notePlayer;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late final TrainingController _controller;
  late final NotePlayer _notePlayer;
  late final bool _ownsController;
  late final bool _ownsNotePlayer;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _ownsNotePlayer = widget.notePlayer == null;
    _controller = widget.controller ?? TrainingController();
    _notePlayer = widget.notePlayer ?? AssetNotePlayer();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsNotePlayer) {
      _notePlayer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _controller.next,
        const SingleActivator(LogicalKeyboardKey.keyH): _controller.useHint,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 22,
                      ),
                      child: _controller.phase == TrainingPhase.summary
                          ? _buildSummary()
                          : _buildTraining(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playNote(MusicNote note) async {
    try {
      await _notePlayer.playNote(note);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Не удалось воспроизвести звук')),
        );
    }
  }

  Widget _buildTraining() {
    final exercise = _controller.exercise;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 22),
        _buildSettings(),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              '${exercise.isSeries ? 'Серия' : 'Вопрос'} ${_controller.questionNumber} из ${_controller.sessionTarget}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text('Выполнено: ${_controller.answeredCount}'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _controller.answeredCount / _controller.sessionTarget,
          minHeight: 6,
          backgroundColor: const Color(0xFF29332D),
        ),
        const SizedBox(height: 18),
        Card(
          color: const Color(0xFF1A211D),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              children: [
                Text(
                  _promptFor(exercise),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _subtitleFor(exercise),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9EACA4),
                  ),
                ),
                StaffView(
                  notes: exercise.steps
                      .map((step) => step.note.writtenForGuitar)
                      .toList(),
                  currentIndex: _controller.currentStepIndex,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildMessage(),
        const SizedBox(height: 12),
        Card(
          color: const Color(0xFF1A211D),
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boardWidth = max(constraints.maxWidth, 900.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: boardWidth,
                  child: FretboardView(
                    enabled: !_controller.isAnswered,
                    foundPositions: _controller.foundPositions,
                    selectedPosition: _controller.selectedPosition,
                    lastAnswerCorrect: _controller.lastAnswerCorrect,
                    hintedPosition: _controller.hintedPosition,
                    minFret: exercise.minFret,
                    maxFret: exercise.maxFret,
                    onPositionSelected: (position) {
                      _controller.submit(position);
                      unawaited(_playNote(Guitar.noteAt(position)));
                    },
                    onOpenStringPlay: (string) {
                      unawaited(_playNote(string.openNote));
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.tonalIcon(
              key: const Key('hint-button'),
              onPressed: _controller.isAnswered || _controller.hintLevel >= 3
                  ? null
                  : _controller.useHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text('Подсказка · ${_controller.hintLevel}/3'),
            ),
            FilledButton.icon(
              key: const Key('next-button'),
              onPressed: _controller.isAnswered ? _controller.next : null,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                _controller.answeredCount >= _controller.sessionTarget
                    ? 'К итогам'
                    : 'Следующий вопрос',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'H — подсказка  ·  Enter — следующий вопрос',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7F8E85)),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 13),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ГРИФ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Text('Тренажёр чтения нот'),
              ],
            ),
          ],
        ),
        Text(
          'EADGBE  ·  0–12 ладов',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: const Color(0xFF9EACA4)),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Card(
      color: const Color(0xFF171E1A),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('Режим:'),
            ),
            for (final (type, label) in const [
              (ExerciseType.firstPosition, 'Первая позиция'),
              (ExerciseType.onString, 'По струне'),
              (ExerciseType.allPositions, 'Все позиции'),
              (ExerciseType.noteSeries, 'Серии нот'),
            ])
              ChoiceChip(
                key: Key('mode-${type.name}'),
                label: Text(label),
                selected: _controller.mode == type,
                onSelected: (_) => _controller.setMode(type),
              ),
            const SizedBox(width: 12),
            if (_controller.mode == ExerciseType.noteSeries) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('Этап:'),
              ),
              for (final stage in SeriesStage.values)
                Tooltip(
                  message: stage.description,
                  child: ChoiceChip(
                    key: Key('series-stage-${stage.name}'),
                    label: Text(stage.label),
                    selected: _controller.seriesStage == stage,
                    onSelected: (_) => _controller.setSeriesStage(stage),
                  ),
                ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('Ноты:'),
              ),
              ChoiceChip(
                key: const Key('notes-naturals'),
                label: const Text('Натуральные'),
                selected: _controller.noteSet == NoteSet.naturals,
                onSelected: (_) => _controller.setNoteSet(NoteSet.naturals),
              ),
              ChoiceChip(
                key: const Key('notes-chromatic'),
                label: const Text('♯ и ♭'),
                selected: _controller.noteSet == NoteSet.chromatic,
                onSelected: (_) => _controller.setNoteSet(NoteSet.chromatic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    final hint = _controller.hintText;
    final feedback = _controller.feedback;
    final hasFeedback = feedback.isNotEmpty;
    final correct = _controller.lastAnswerCorrect;
    final color = !hasFeedback
        ? const Color(0xFF252E29)
        : correct == true
        ? const Color(0xFF203C2E)
        : const Color(0xFF422728);
    final icon = !hasFeedback
        ? Icons.touch_app_outlined
        : correct == true
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;

    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              hasFeedback ? feedback : 'Выбери позицию на грифе',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                hint,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFFFFDE8A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final accuracy = (_controller.accuracy * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        const SizedBox(height: 54),
        Icon(
          Icons.emoji_events_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Сессия завершена',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Отвечено на ${_controller.results.length} вопросов',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard('$accuracy%', 'без ошибок'),
            _statCard(
              '${_controller.results.fold(0, (sum, result) => sum + result.mistakes)}',
              'ошибок',
            ),
            _statCard('${_controller.totalHints}', 'подсказок'),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          color: const Color(0xFF1A211D),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Над чем поработать',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (_controller.weakNotes.isEmpty)
                  const Text('Все ответы даны без ошибок. Отличная работа!')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in _controller.weakNotes)
                        Chip(label: Text('${entry.key} · ${entry.value}')),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            if (_controller.hasMistakes)
              FilledButton.tonalIcon(
                key: const Key('review-button'),
                onPressed: _controller.repeatMistakes,
                icon: const Icon(Icons.replay),
                label: const Text('Повторить ошибки'),
              ),
            FilledButton.icon(
              key: const Key('new-session-button'),
              onPressed: _controller.startSession,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Новая сессия'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String value, String label) {
    return SizedBox(
      width: 180,
      child: Card(
        color: const Color(0xFF1A211D),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  String _promptFor(Exercise exercise) {
    return switch (exercise.type) {
      ExerciseType.firstPosition => 'Найди ноту в первой позиции',
      ExerciseType.onString =>
        'Найди ноту на ${exercise.stringNumber}-й струне',
      ExerciseType.allPositions => 'Найди все позиции ноты',
      ExerciseType.noteSeries => 'Отметь серию нот по порядку',
    };
  }

  String _subtitleFor(Exercise exercise) {
    return switch (exercise.type) {
      ExerciseType.firstPosition => 'Минимальный лад · диапазон 0–4',
      ExerciseType.onString =>
        '${Guitar.strings[exercise.stringNumber! - 1].openNote.localizedName} · один правильный ответ · 0–12 ладов',
      ExerciseType.allPositions =>
        '0–12 ладов · найдено ${_controller.foundPositions.length} из ${exercise.answers.length}',
      ExerciseType.noteSeries =>
        'Нота ${_controller.currentStepIndex + 1} из ${exercise.steps.length} · минимальный лад · диапазон ${exercise.minFret}–${exercise.maxFret}',
    };
  }
}
