import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/sermon.dart';

class AudioPlayerService {
  factory AudioPlayerService() => _instance;

  AudioPlayerService._internal();
  static final AudioPlayerService _instance = AudioPlayerService._internal();

  AudioPlayer? _player;
  List<Sermon> _playlist = [];
  int _currentIndex = -1;
  Sermon? _currentSermon;

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  Sermon? get currentSermon =>
      _currentIndex >= 0 && _currentIndex < _playlist.length
          ? _playlist[_currentIndex]
          : _currentSermon;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<bool> get playingStream => player.playingStream;

  Future<void> playSermon(Sermon sermon) async {
    if (_currentSermon?.id != sermon.id) {
      _currentSermon = sermon;
      await player.stop();

      try {
        final mediaItem = MediaItem(
          id: sermon.id,
          album: 'Sermons',
          title: sermon.title,
          artist: sermon.preacherName,
          artUri: Uri.parse(sermon.thumbnailUrl),
        );

        // Set the audio source with media item
        await player.setAudioSource(
          AudioSource.uri(
            Uri.parse(sermon.audioUrl),
            tag: mediaItem,
          ),
        );

        await player.play();
      } catch (e) {
        print('Error playing sermon: $e');
        rethrow;
      }
    } else {
      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    }
  }

  Future<void> playSermonFromPlaylist(
      Sermon sermon, List<Sermon> playlist) async {
    _playlist = playlist;
    _currentIndex = _playlist.indexOf(sermon);
    await playSermon(sermon);
  }

  Future<void> playNext() async {
    if (_playlist.isEmpty || _currentIndex == -1) return;

    _currentIndex = (_currentIndex + 1) % _playlist.length;
    await playSermon(_playlist[_currentIndex]);
  }

  Future<void> playPrevious() async {
    if (_playlist.isEmpty || _currentIndex == -1) return;

    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    await playSermon(_playlist[_currentIndex]);
  }

  Future<void> seekForward(Duration duration) async {
    final position = player.position;
    final newPosition = position + duration;
    await seek(newPosition);
  }

  Future<void> seekBackward(Duration duration) async {
    final position = player.position;
    final newPosition = position - duration;
    await seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  bool isPlaying(String sermonId) {
    return _currentSermon?.id == sermonId && player.playing;
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.play();
  }

  Future<void> stop() async {
    await player.stop();
    _currentSermon = null;
    _currentIndex = -1;
    _playlist = [];
  }

  Future<void> seek(Duration position) async {
    await player.seek(position);
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _currentSermon = null;
    _currentIndex = -1;
    _playlist = [];
  }

  bool get hasNext =>
      _playlist.isNotEmpty && _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _playlist.isNotEmpty && _currentIndex > 0;
}
