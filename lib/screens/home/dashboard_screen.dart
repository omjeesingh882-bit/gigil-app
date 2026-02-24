import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _roomCodeCtrl = TextEditingController();

  void _createRoom() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<RoomProvider>(context, listen: false).createRoom(user);
      Navigator.pushNamed(context, '/room');
    }
  }

  void _joinRoom() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final code = _roomCodeCtrl.text.trim().toUpperCase();
    if (user != null && code.isNotEmpty) {
      Provider.of<RoomProvider>(context, listen: false).joinRoom(code, user);
      Navigator.pushNamed(context, '/room');
    }
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, ${user?.username ?? "User"}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create a New Room'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: _createRoom,
            ),
            const SizedBox(height: 48),
            const Text('Or join an existing room:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roomCodeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Room Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _joinRoom,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                  child: const Text('Join'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
