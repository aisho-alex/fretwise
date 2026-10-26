import 'package:audioplayers/audioplayers.dart';

import '../domain/models/music_note.dart';

abstract interface class NotePlayer {
  Future<void> playNote(MusicNote note);
  void dispose();
}

final class AssetNotePlayer implements NotePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> playNote(MusicNote note) async {
    await _player.stop();
    await _player.play(AssetSource('audio/note_${note.midi}.wav'));
  }

  @override
  void dispose() {
    _player.dispose();
  }
}
