import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/audio_player_service.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _songUrlCtrl = TextEditingController();
  final _chatCtrl = TextEditingController();
  AudioPlayerService? _audioService;

  @override
  void initState() {
    super.initState();
    // Wait for the room provider to get socket and details
    Future.delayed(Duration.zero, () {
      final roomProv = Provider.of<RoomProvider>(context, listen: false);
      if (roomProv.socket != null && roomProv.roomCode != null) {
        _audioService = AudioPlayerService(
          socket: roomProv.socket!,
          roomCode: roomProv.roomCode!,
          isHost: roomProv.isHost,
        );
      }
    });
  }

  @override
  void dispose() {
    _audioService?.dispose();
    super.dispose();
  }

  void _addSong() {
    final url = _songUrlCtrl.text.trim();
    if (url.isNotEmpty) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      final song = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'Song ${DateTime.now().second}', // Placeholder for title fetch
        'artist': 'Unknown Artist',
        'url': url,
        'addedBy': user?.username
      };
      Provider.of<RoomProvider>(context, listen: false).addSong(song);
      _songUrlCtrl.clear();
    }
  }

  void _sendMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isNotEmpty) {
      final roomProv = Provider.of<RoomProvider>(context, listen: false);
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      
      roomProv.socket?.emit('send_message', {
        'roomCode': roomProv.roomCode,
        'text': text,
        'username': user?.username,
        'avatar': user?.avatar
      });
      _chatCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProv = Provider.of<RoomProvider>(context);

    if (roomProv.roomCode == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${roomProv.roomCode}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              // Show participants sheet
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Audio Player Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.deepPurple.shade900,
            child: Column(
              children: [
                Text(
                  roomProv.currentSong != null 
                      ? '${roomProv.currentSong['title']} by ${roomProv.currentSong['artist']}'
                      : 'No song playing',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (roomProv.isHost)
                      IconButton(
                        icon: const Icon(Icons.play_arrow, size: 40),
                        onPressed: () => _audioService?.play(),
                      ),
                    if (roomProv.isHost)
                      IconButton(
                        icon: const Icon(Icons.pause, size: 40),
                        onPressed: () => _audioService?.pause(),
                      ),
                  ],
                ),
                // Add Song Field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _songUrlCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Paste MP3 URL',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_to_photos),
                      onPressed: _addSong,
                    )
                  ],
                )
              ],
            ),
          ),
          
          // Playlist & Chat Tab View (Simplified layout)
          Expanded(
            child: Row(
              children: [
                // Playlist
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade800))
                    ),
                    child: ListView.builder(
                      itemCount: roomProv.playlist.length,
                      itemBuilder: (context, index) {
                        final song = roomProv.playlist[index];
                        return ListTile(
                          title: Text(song['title']),
                          subtitle: Text('Added by ${song['addedBy']}'),
                          leading: const Icon(Icons.music_note),
                        );
                      },
                    ),
                  ),
                ),
                
                // Chat
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Expanded(
                        // Chat messages go here (Need a separate widget to listen to chat stream)
                        child: Center(child: Text('Chat messages area')),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatCtrl,
                                decoration: const InputDecoration(hintText: 'Say something...'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _sendMessage,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
