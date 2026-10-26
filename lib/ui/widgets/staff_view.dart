import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/music_note.dart';

class StaffView extends StatelessWidget {
  const StaffView({
    super.key,
    this.note,
    this.notes = const [],
    this.currentIndex = 0,
    this.height = 190,
  }) : assert(note != null || notes.length > 0);

  final MusicNote? note;
  final List<MusicNote> notes;
  final int currentIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    final displayedNotes = notes.isEmpty ? [note!] : notes;
    return Semantics(
      label: displayedNotes.length == 1
          ? 'Нота на нотном стане'
          : 'Серия из ${displayedNotes.length} нот на нотном стане',
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          painter: StaffPainter(
            notes: displayedNotes,
            currentIndex: currentIndex,
          ),
        ),
      ),
    );
  }
}

class StaffPainter extends CustomPainter {
  const StaffPainter({required this.notes, this.currentIndex = 0})
    : assert(notes.length > 0);

  final List<MusicNote> notes;
  final int currentIndex;

  static const _bottomLineIndex = 4 * 7 + 2;

  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = Color(0xFF9EACA4);
    const verticalMargin = 24.0;
    final indices = notes.map((note) => note.diatonicIndex).toList();
    final range = indices.reduce(math.max) - indices.reduce(math.min);
    final baseSpacing = (size.height / 12).clamp(12.0, 18.0);
    final spacing = range == 0
        ? baseSpacing
        : math.min(baseSpacing, (size.height - verticalMargin * 2) * 2 / range);
    final relativeYs = indices
        .map((index) => -(index - _bottomLineIndex) * spacing / 2)
        .toList();
    final minBottom = verticalMargin - relativeYs.reduce(math.min);
    final maxBottom =
        size.height - verticalMargin - relativeYs.reduce(math.max);
    var bottomLineY = size.height * 0.64;
    bottomLineY = minBottom <= maxBottom
        ? bottomLineY.clamp(minBottom, maxBottom)
        : (minBottom + maxBottom) / 2;
    final topLineY = bottomLineY - spacing * 4;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2;

    for (var line = 0; line < 5; line++) {
      final y = topLineY + line * spacing;
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), linePaint);
    }
    _drawClef(canvas, bottomLineY - spacing, spacing, lineColor);

    for (var index = 0; index < notes.length; index++) {
      final noteX = _noteX(size.width, index);
      final noteY = bottomLineY + relativeYs[index];
      final noteColor = switch (index.compareTo(currentIndex)) {
        < 0 => const Color(0xFF76C893),
        0 => const Color(0xFFFFD166),
        _ => const Color(0xFFF1F5F2),
      };
      if (index == currentIndex && notes.length > 1) {
        canvas.drawCircle(
          Offset(noteX, noteY),
          spacing * 1.2,
          Paint()..color = const Color(0x22FFD166),
        );
      }
      _drawNote(
        canvas,
        note: notes[index],
        noteX: noteX,
        noteY: noteY,
        bottomLineY: bottomLineY,
        topLineY: topLineY,
        spacing: spacing,
        linePaint: linePaint,
        noteColor: noteColor,
      );
      if (notes.length > 1) {
        _drawStepLabel(canvas, index, noteX, size.height - 16, noteColor);
      }
    }
  }

  double _noteX(double width, int index) {
    if (notes.length == 1) {
      return width * 0.59;
    }
    final left = math.max(130.0, width * 0.18);
    final right = width - 45;
    return left + (right - left) * index / (notes.length - 1);
  }

  void _drawNote(
    Canvas canvas, {
    required MusicNote note,
    required double noteX,
    required double noteY,
    required double bottomLineY,
    required double topLineY,
    required double spacing,
    required Paint linePaint,
    required Color noteColor,
  }) {
    _drawLedgerLines(
      canvas,
      noteX: noteX,
      noteY: noteY,
      bottomLineY: bottomLineY,
      topLineY: topLineY,
      spacing: spacing,
      paint: linePaint,
    );
    if (note.accidental != Accidental.natural) {
      final glyph = note.accidental == Accidental.sharp ? 0xE262 : 0xE260;
      _drawGlyph(
        canvas,
        glyph,
        Offset(noteX - spacing * 2.2, noteY),
        spacing * 4,
        noteColor,
      );
    }

    final stemUp = note.diatonicIndex < 4 * 7 + 6;
    final stemX = noteX + (stemUp ? spacing * 0.52 : -spacing * 0.52);
    canvas.drawLine(
      Offset(stemX, noteY),
      Offset(stemX, noteY + (stemUp ? -3.5 : 3.5) * spacing),
      Paint()
        ..color = noteColor
        ..strokeWidth = 1.8,
    );
    canvas.save();
    canvas.translate(noteX, noteY);
    canvas.rotate(-0.28);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: spacing * 1.25,
        height: spacing * 0.82,
      ),
      Paint()..color = noteColor,
    );
    canvas.restore();
  }

  void _drawStepLabel(
    Canvas canvas,
    int index,
    double x,
    double y,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: index == currentIndex
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(x - painter.width / 2, y - painter.height / 2),
    );
  }

  void _drawLedgerLines(
    Canvas canvas, {
    required double noteX,
    required double noteY,
    required double bottomLineY,
    required double topLineY,
    required double spacing,
    required Paint paint,
  }) {
    final halfSpace = spacing / 2;
    if (noteY > bottomLineY + halfSpace) {
      var y = bottomLineY + spacing;
      while (y <= noteY + halfSpace) {
        canvas.drawLine(
          Offset(noteX - spacing, y),
          Offset(noteX + spacing, y),
          paint,
        );
        y += spacing;
      }
    } else if (noteY < topLineY - halfSpace) {
      var y = topLineY - spacing;
      while (y >= noteY - halfSpace) {
        canvas.drawLine(
          Offset(noteX - spacing, y),
          Offset(noteX + spacing, y),
          paint,
        );
        y -= spacing;
      }
    }
  }

  void _drawClef(Canvas canvas, double baselineY, double spacing, Color color) {
    _drawGlyph(
      canvas,
      0xE050,
      Offset(spacing * 3.2, baselineY),
      spacing * 4,
      color,
    );
  }

  void _drawGlyph(
    Canvas canvas,
    int codePoint,
    Offset baselineOrigin,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codePoint),
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(
      canvas,
      Offset(baselineOrigin.dx, baselineOrigin.dy - baseline),
    );
  }

  @override
  bool shouldRepaint(StaffPainter oldDelegate) =>
      oldDelegate.notes != notes || oldDelegate.currentIndex != currentIndex;
}
