import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final IO.Socket socket;
  final String roomCode;
  final bool isHost;
  
  Timer? _syncTimer;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;

  AudioPlayerService({
    required this.socket,
    required this.roomCode,
    required this.isHost,
  }) {
    _initSocketListeners();
    if (isHost) {
      _startHostSync();
    }
  }

  void _initSocketListeners() {
    socket.on('song_changed', (song) async {
      await _player.setUrl(song['url']);
      if (isHost) {
        _player.play();
      }
    });

    socket.on('sync_update', (data) async {
      if (isHost) return; // Host dictates, doesn't listen to sync
      
      final hostPositionMs = data['position'] as int;
      final timestamp = data['timestamp'] as int;
      final hostIsPlaying = data['isPlaying'] as bool;
      
      // Calculate offset based on latency
      final latency = DateTime.now().millisecondsSinceEpoch - timestamp;
      final adjustedHostPos = hostPositionMs + latency;
      
      final currentPos = _player.position.inMilliseconds;
      final diff = (currentPos - adjustedHostPos).abs();

      // If difference is greater than 200ms, seek to correct position
      if (diff > 200) {
        await _player.seek(Duration(milliseconds: adjustedHostPos));
      }

      if (hostIsPlaying && !_player.playing) {
        _player.play();
      } else if (!hostIsPlaying && _player.playing) {
        _player.pause();
      }
    });
  }

  void _startHostSync() {
    // Broadcast position every 1 second
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_player.playing) {
        socket.emit('sync_playback', {
          'roomCode': roomCode,
          'position': _player.position.inMilliseconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isPlaying': _player.playing,
        });
      }
    });

    // Broadcast play/pause state changes instantly
    _playerStateSub = _player.playerStateStream.listen((state) {
      socket.emit('sync_playback', {
        'roomCode': roomCode,
        'position': _player.position.inMilliseconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isPlaying': state.playing,
      });
    });
  }

  Future<void> play() async => await _player.play();
  Future<void> pause() async => await _player.pause();
  Future<void> seek(Duration position) async => await _player.seek(position);

  AudioPlayer get player => _player;

  void dispose() {
    _syncTimer?.cancel();
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _player.dispose();
  }
}
