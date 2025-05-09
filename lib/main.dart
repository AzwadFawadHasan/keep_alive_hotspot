import 'dart:async'; // For Timer
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For HTTP requests
import 'package:audioplayers/audioplayers.dart'; // For playing audio


void main() {
  runApp(const KeepAliveApp());
}

class KeepAliveApp extends StatelessWidget {
  const KeepAliveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hotspot Keeper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const KeepAliveHome(),
    );
  }
}

class KeepAliveHome extends StatefulWidget {
  const KeepAliveHome({super.key});

  @override
  State<KeepAliveHome> createState() => _KeepAliveHomeState();
}

class _KeepAliveHomeState extends State<KeepAliveHome> {
  Timer? _timer; // Timer to schedule periodic requests
  String _status = "Waiting to start...";
  int _pingCount = 0;
  late AudioPlayer _audioPlayer; // Declare the audio player


  // This function sends a lightweight HTTP GET request
  Future<void> _sendKeepAlivePing() async {
    setState(() {
      _status = "Pinging...";
    });
    try {
      // This URL returns a 204 No Content response, very lightweight
      final response = await http.get(Uri.parse('https://www.google.com/generate_204'));
       setState(() {
        _pingCount++;
        _status = "Ping #$_pingCount: Success (HTTP ${response.statusCode})";
      });
    } catch (e) {
      setState(() {
        _status = "Ping failed: $e";
      });
    }
  }

  // Start the timer when the widget is initialized
  @override
  void initState() {
    super.initState();
    // Initialize the audio player
    _audioPlayer = AudioPlayer();

    // Play the silent audio file in a loop
    _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop the audio
    _audioPlayer.play(AssetSource('silence.mp3')); // Play the asset
    // Send a ping every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendKeepAlivePing();
    });
  }

  // Cancel the timer when the widget is disposed
  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose(); // Release audio resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hotspot Keeper')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hotspot Keep-Alive is running!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: const TextStyle(fontSize: 16, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Total pings: $_pingCount',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
