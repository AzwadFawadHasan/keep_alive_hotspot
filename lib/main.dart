import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,   // <--- MATCHES brightness above!
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro',
        ),

      home: const KeepAliveHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KeepAliveHome extends StatefulWidget {
  const KeepAliveHome({super.key});
  @override
  State<KeepAliveHome> createState() => _KeepAliveHomeState();
}

class LogEntry {
  final DateTime time;
  final String message;
  final bool success;
  LogEntry(this.time, this.message, this.success);
}

class _KeepAliveHomeState extends State<KeepAliveHome> {
  bool _isRunning = false;
  Timer? _timer;
  int _pingCount = 0;
  int _successCount = 0;
  int _failCount = 0;
  double _batteryWarningLevel = 15.0; // Just for info, real iOS battery API is private.
  late AudioPlayer _audioPlayer;
  int _intervalSec = 5;
  final List<int> _intervalChoices = [5, 10, 30, 60];
  List<LogEntry> _logs = [];
  FlutterLocalNotificationsPlugin? _notifications;
  DateTime? _startTime;
  bool _hotspotDetected = false;
  StreamSubscription? _connectivitySub;
  String _hotspotStatusMsg = "Detecting...";

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initNotifications();
    _detectHotspot();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _notifications!.initialize(initializationSettings);
  }

  Future<void> _showNotification(String msg) async {
    if (_notifications == null) return;
    await _notifications!.show(
      0,
      'Hotspot Keeper',
      msg,
      const NotificationDetails(
        android: AndroidNotificationDetails('keepalive', 'Keep Alive', importance: Importance.max),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _sendKeepAlivePing() async {
    String status;
    bool ok = false;
    try {
      final response = await http.get(Uri.parse('https://www.google.com/generate_204'));
      _pingCount++;
      if (response.statusCode == 204) {
        _successCount++;
        status = "Ping #$_pingCount Success (HTTP 204)";
        ok = true;
      } else {
        _failCount++;
        status = "Ping #$_pingCount: Unexpected HTTP ${response.statusCode}";
      }
    } catch (e) {
      _failCount++;
      status = "Ping #$_pingCount Failed: $e";
    }
    setState(() {
      _logs.add(LogEntry(DateTime.now(), status, ok));
      if (_logs.length > 1000) _logs.removeAt(0); // Limit log size
    });
  }

  Future<void> _startKeepAlive() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('silence.mp3'));
    _timer = Timer.periodic(Duration(seconds: _intervalSec), (timer) {
      _sendKeepAlivePing();
    });
    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _logs.add(LogEntry(DateTime.now(), "Keep-Alive started", true));
    });
    _showNotification("Hotspot Keep-Alive is running!");
  }

  void _stopKeepAlive() {
    _timer?.cancel();
    _audioPlayer.stop();
    setState(() {
      _isRunning = false;
      _logs.add(LogEntry(DateTime.now(), "Keep-Alive stopped", true));
    });
    _showNotification("Hotspot Keep-Alive stopped.");
  }

  // Best-effort hotspot "detection" on iOS
  Future<void> _detectHotspot() async {
    // There is no public API. We just check for WiFi and inform the user.
    // If you want, use connectivity_plus to watch for network changes.
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      if (connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.ethernet) {
        _hotspotDetected = true; // Not 100% accurate
        _hotspotStatusMsg = "WiFi/Ethernet connected (enable iOS Hotspot for best results)";
      } else {
        _hotspotDetected = false;
        _hotspotStatusMsg = "No WiFi/Ethernet detected (enable Personal Hotspot)";
      }
    });
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      _detectHotspot();
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${d.inHours}:${twoDigits(d.inMinutes % 60)}:${twoDigits(d.inSeconds % 60)}";
  }

  double _successRate() {
    if (_pingCount == 0) return 0;
    return (_successCount / _pingCount) * 100;
  }

  // Log export and sharing
  Future<void> _exportLogs() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/hotspot_keeper_logs.txt";
    final file = File(path);
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln(
          "${log.time.toIso8601String()} [${log.success ? 'OK' : 'FAIL'}] ${log.message}");
    }
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(path)], text: "Hotspot Keeper Logs");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Duration uptime =
        _isRunning && _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Keeper', style: TextStyle(letterSpacing: 1.2)),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.blueAccent.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _logs.isNotEmpty ? _exportLogs : null,
            tooltip: "Export Logs",
          )
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _hotspotCard(theme),
            const SizedBox(height: 16),
            _statusCard(theme, uptime),
            const SizedBox(height: 16),
            _intervalSelector(theme),
            const SizedBox(height: 16),
            _batteryWarningCard(),
            const SizedBox(height: 16),
            _controlButton(theme),
            const SizedBox(height: 16),
            _logView(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _hotspotCard(ThemeData theme) => Card(
        color: _hotspotDetected ? Colors.green.shade800 : Colors.red.shade800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              Icon(_hotspotDetected ? Icons.wifi : Icons.signal_wifi_off, size: 38, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _hotspotDetected ? "Hotspot Detected" : "Hotspot Not Detected",
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              Text(_hotspotStatusMsg, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      );

  Widget _statusCard(ThemeData theme, Duration uptime) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        color: Colors.blueGrey.shade900,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(_isRunning ? Icons.check_circle : Icons.cancel,
                      color: _isRunning ? Colors.greenAccent : Colors.redAccent, size: 30),
                  const SizedBox(width: 12),
                  Text(_isRunning ? "Keep-Alive Active" : "Stopped",
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isRunning ? Colors.greenAccent : Colors.redAccent)),
                  const Spacer(),
                  if (_isRunning)
                    Text("Uptime: ${_formatDuration(uptime)}",
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Pings: $_pingCount", style: theme.textTheme.bodyLarge),
                        Text("Success: $_successCount", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.greenAccent)),
                        Text("Fails: $_failCount", style: theme.textTheme.bodyLarge?.copyWith(color: Colors.redAccent)),
                        Text("Success Rate: ${_successRate().toStringAsFixed(1)}%", style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (_isRunning)
                    Icon(Icons.sync, color: Colors.blueAccent, size: 28),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _intervalSelector(ThemeData theme) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: Colors.blue.shade900.withOpacity(0.85),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 18.0),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.white70),
              const SizedBox(width: 12),
              Text("Ping Interval:", style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _intervalSec,
                items: _intervalChoices
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text("${s}s"),
                        ))
                    .toList(),
                onChanged: !_isRunning
                    ? (v) {
                        if (v != null) setState(() => _intervalSec = v);
                      }
                    : null,
                dropdownColor: Colors.blue.shade800,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Text("(Shorter = More reliable, more battery use)", style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      );

  Widget _batteryWarningCard() => Card(
        color: Colors.orange.shade900.withOpacity(0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: const [
              Icon(Icons.battery_alert, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "⚠️ Battery Usage Warning\n"
                  "Keep-Alive uses background audio and frequent network requests, which can increase battery drain. "
                  "Stop the service when not needed.",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _controlButton(ThemeData theme) => Center(
        child: ElevatedButton.icon(
          icon: Icon(_isRunning ? Icons.stop_circle : Icons.play_circle_fill, size: 32),
          label: Text(_isRunning ? "Stop Keep-Alive" : "Start Keep-Alive", style: const TextStyle(fontSize: 18)),
          onPressed: _isRunning ? _stopKeepAlive : _startKeepAlive,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRunning ? Colors.redAccent : Colors.greenAccent.shade400,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 4,
            shadowColor: Colors.black54,
          ),
        ),
      );

  Widget _logView() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: Colors.black.withOpacity(0.93),
        child: SizedBox(
          height: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    "Ping & Status Log",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white70, letterSpacing: 1),
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: _logs.isEmpty
                    ? const Center(child: Text("No log entries yet.", style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, i) {
                          final log = _logs[_logs.length - 1 - i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            child: Text(
                              "[${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}] ${log.message}",
                              style: TextStyle(
                                color: log.success ? Colors.greenAccent : Colors.redAccent,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
              ),
              TextButton.icon(
                onPressed: _logs.isNotEmpty ? _exportLogs : null,
                icon: const Icon(Icons.share, size: 18),
                label: const Text("Export Logs", style: TextStyle(fontSize: 15)),
              )
            ],
          ),
        ),
      );
}
