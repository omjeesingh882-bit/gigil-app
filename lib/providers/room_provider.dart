import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/user.dart';
import 'dart:async';

class RoomProvider with ChangeNotifier {
  IO.Socket? _socket;
  String? _roomCode;
  List<User> _users = [];
  List<dynamic> _playlist = [];
  List<Map<String, dynamic>> _messages = [];
  dynamic _currentSong;
  bool _isHost = false;
  String? _hostId;

  String? get roomCode => _roomCode;
  List<User> get users => _users;
  List<dynamic> get playlist => _playlist;
  List<Map<String, dynamic>> get messages => _messages;
  dynamic get currentSong => _currentSong;
  bool get isHost => _isHost;

  final String serverUrl = 'https://gigil-backend.onrender.com'; // Production server

  void connect(User user) {
    _socket = IO.io(serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to Socket.IO');
    });

    _socket!.on('room_created', (data) {
      _roomCode = data['roomCode'];
      _isHost = true;
      _updateRoomData(data['room']);
    });

    _socket!.on('room_joined', (data) {
      _roomCode = data['roomCode'];
      _isHost = false;
      _updateRoomData(data['room']);
    });

    _socket!.on('user_joined', (data) {
      _users.add(User.fromJson(data));
      notifyListeners();
    });

    _socket!.on('user_left', (data) {
      _users.removeWhere((u) => u.id == data['id']);
      notifyListeners();
    });

    _socket!.on('playlist_updated', (data) {
      _playlist = data;
      notifyListeners();
    });

    _socket!.on('song_changed', (data) {
      _currentSong = data;
      // Audio player logic will listen to this
      notifyListeners();
    });

    _socket!.on('new_message', (data) {
      _messages.add({
        'text': data['text'],
        'username': data['username'],
        'timestamp': data['timestamp']
      });
      notifyListeners();
    });
  }

  void _updateRoomData(dynamic room) {
    _users = (room['users'] as List).map((u) => User.fromJson(u)).toList();
    _playlist = room['playlist'];
    _currentSong = room['currentSong'];
    _hostId = room['hostId'];
    notifyListeners();
  }

  void createRoom(User user) {
    if (_socket == null) connect(user);
    _socket!.emit('create_room', {
      'username': user.username,
      'avatar': user.avatar
    });
  }

  void joinRoom(String code, User user) {
    if (_socket == null) connect(user);
    _socket!.emit('join_room', {
      'roomCode': code,
      'username': user.username,
      'avatar': user.avatar
    });
  }

  void addSong(dynamic song) {
    if (_socket != null && _roomCode != null) {
      _socket!.emit('add_song', {
        'roomCode': _roomCode,
        'song': song
      });
    }
  }

  // Exposed for Audio Sync logic
  IO.Socket? get socket => _socket;

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }
}
