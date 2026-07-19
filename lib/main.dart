// ===========================================================================
// CSE 489 — Assignment 2 (Flutter, single-file main.dart)
//
// Drawer sections:
//   A. Broadcast Receiver  (REAL Android BroadcastReceiver via platform
//                           channels — the Intent round-trips through the
//                           Android OS, it is NOT simulated in Dart)
//   B. Image Scale         (network image + pinch-to-zoom gesture)
//   C. Video               (in-app video playback, video_player package)
//   D. Audio               (in-app audio playback, audioplayers package)
//
// Requires the companion MainActivity.kt (platform side) — see SETUP_NOTES.
// ===========================================================================

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// ---------------------------------------------------------------------------
// Platform-channel names. These MUST match MainActivity.kt character-for-
// character, otherwise Dart and Kotlin will silently talk past each other.
// ---------------------------------------------------------------------------
const MethodChannel _methodChannel =
    MethodChannel('cse489.assignment2/methods');
const EventChannel _customBroadcastChannel =
    EventChannel('cse489.assignment2/custom_broadcast');
const EventChannel _batteryBroadcastChannel =
    EventChannel('cse489.assignment2/battery_broadcast');

void main() => runApp(const Assignment2App());

class Assignment2App extends StatelessWidget {
  const Assignment2App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CSE 489 Assignment 2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

// ===========================================================================
// HOME SHELL — Scaffold with the Navigation Drawer (assignment requirement)
// ===========================================================================
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const List<String> _titles = <String>[
    'Broadcast Receiver',
    'Image Scale',
    'Video',
    'Audio',
  ];

  static const List<IconData> _icons = <IconData>[
    Icons.podcasts,
    Icons.zoom_out_map,
    Icons.videocam,
    Icons.audiotrack,
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const BroadcastTypeScreen();
      case 1:
        return const ImageScaleScreen();
      case 2:
        return const VideoScreen();
      case 3:
        return const AudioScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'CSE 489\nAssignment 2',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            for (int i = 0; i < _titles.length; i++)
              ListTile(
                leading: Icon(_icons[i]),
                title: Text(_titles[i]),
                selected: _selectedIndex == i,
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context); // close the drawer
                },
              ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}

// ===========================================================================
// A. BROADCAST RECEIVER — Screen 1 of 3
// "Shows a spinner list where one can select the type of broadcast operation
//  wants to perform. There will be a button to proceed to the next activity."
// ===========================================================================
const String _kCustomOption = 'Custom broadcast receiver';
const String _kBatteryOption = 'System battery notification receiver';

class BroadcastTypeScreen extends StatefulWidget {
  const BroadcastTypeScreen({super.key});

  @override
  State<BroadcastTypeScreen> createState() => _BroadcastTypeScreenState();
}

class _BroadcastTypeScreenState extends State<BroadcastTypeScreen> {
  String _selected = _kCustomOption;

  void _proceed() {
    final Widget next = _selected == _kCustomOption
        ? const CustomInputScreen()
        : const BatteryScreen();
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Select a broadcast type',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            // The "spinner" — Flutter's equivalent is DropdownButton.
            DropdownButton<String>(
              value: _selected,
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(
                    value: _kCustomOption, child: Text(_kCustomOption)),
                DropdownMenuItem(
                    value: _kBatteryOption, child: Text(_kBatteryOption)),
              ],
              onChanged: (String? v) =>
                  setState(() => _selected = v ?? _kCustomOption),
            ),
            const SizedBox(height: 32),
            FilledButton(onPressed: _proceed, child: const Text('Proceed')),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// A. BROADCAST RECEIVER — Screen 2 (custom option)
// "This activity will take input from the user. The input will be a plain
//  text which will be passed to the next activity."
// ===========================================================================
class CustomInputScreen extends StatefulWidget {
  const CustomInputScreen({super.key});

  @override
  State<CustomInputScreen> createState() => _CustomInputScreenState();
}

class _CustomInputScreenState extends State<CustomInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _proceed() {
    final String text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please type a message first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CustomReceiverScreen(message: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Broadcast — Input')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Message to broadcast',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _proceed,
              child: const Text('Proceed to receiver'),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// A. BROADCAST RECEIVER — Screen 3 (custom option)
// "In this activity create the custom broadcast receiver which will receive
//  the text message given in the second activity."
//
// How it really works (no simulation):
//   1. Listening to the EventChannel triggers onListen() in MainActivity.kt,
//      which calls Android's registerReceiver() with a real BroadcastReceiver.
//   2. We then ask Kotlin (via MethodChannel) to sendBroadcast() an Intent
//      carrying the message. The Intent goes through the Android OS and is
//      delivered back to our registered receiver, which forwards the extra
//      String to this screen through the EventChannel sink.
//   3. Cancelling the stream subscription in dispose() triggers onCancel(),
//      which calls unregisterReceiver() — no leaked receivers.
// ===========================================================================
class CustomReceiverScreen extends StatefulWidget {
  const CustomReceiverScreen({super.key, required this.message});

  final String message;

  @override
  State<CustomReceiverScreen> createState() => _CustomReceiverScreenState();
}

class _CustomReceiverScreenState extends State<CustomReceiverScreen> {
  StreamSubscription<dynamic>? _subscription;
  String? _received;
  String _status = 'Registering BroadcastReceiver…';

  @override
  void initState() {
    super.initState();
    // Step 1 — register the real receiver on the Android side.
    _subscription =
        _customBroadcastChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (mounted) {
          setState(() {
            _received = event as String;
            _status = 'Broadcast received!';
          });
        }
      },
      onError: (Object e) {
        if (mounted) {
          setState(() => _status = 'Receiver error: $e');
        }
      },
    );
    // Step 2 — give the platform side a beat to finish registering,
    // then fire the actual Intent through the OS.
    Future<void>.delayed(const Duration(milliseconds: 400), _sendBroadcast);
  }

  Future<void> _sendBroadcast() async {
    if (!mounted) return;
    setState(() => _status = 'Broadcast sent — waiting for receiver…');
    try {
      await _methodChannel.invokeMethod<bool>(
        'sendCustomBroadcast',
        <String, String>{'message': widget.message},
      );
    } on PlatformException catch (e) {
      if (mounted) setState(() => _status = 'Failed to send: ${e.message}');
    }
  }

  @override
  void dispose() {
    // Step 3 — this unregisters the receiver on the Kotlin side.
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Broadcast — Receiver')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                _received == null ? Icons.hourglass_top : Icons.mark_email_read,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (_received != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        const Text('Received message:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_received!,
                            style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _sendBroadcast,
                icon: const Icon(Icons.replay),
                label: const Text('Send broadcast again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// A. BROADCAST RECEIVER — Screen 2 (battery option)
// "If the user selects the second option in the first activity then receives
//  the battery percentage broadcast."
//
// ACTION_BATTERY_CHANGED is a *sticky* system broadcast: as soon as the
// Kotlin side registers the receiver (triggered by listening to this
// EventChannel), Android immediately re-delivers the latest battery Intent,
// so a percentage appears right away and updates on every system broadcast.
// ===========================================================================
class BatteryScreen extends StatelessWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Battery Broadcast')),
      body: Center(
        child: StreamBuilder<dynamic>(
          stream: _batteryBroadcastChannel.receiveBroadcastStream(),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Waiting for ACTION_BATTERY_CHANGED…'),
                ],
              );
            }
            final int percent = snapshot.data as int;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.battery_charging_full,
                    size: 96, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('$percent%',
                    style: const TextStyle(
                        fontSize: 48, fontWeight: FontWeight.bold)),
                const Text('System battery percentage broadcast'),
                const SizedBox(height: 32),
                // Third "activity" exists but does nothing — as per the spec.
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const BatteryNothingScreen()),
                  ),
                  child: const Text('Proceed'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Screen 3 (battery option) — "do nothing here."
class BatteryNothingScreen extends StatelessWidget {
  const BatteryNothingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Third Activity')),
      body: const Center(
        child: Text(
          'Nothing to do here.\n(As specified for the battery option.)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ===========================================================================
// B. IMAGE SCALE
// "Load an image from the internet and scale it with a pinch gesture."
// InteractiveViewer handles the pinch/zoom + pan gestures natively.
// ===========================================================================
class ImageScaleScreen extends StatelessWidget {
  const ImageScaleScreen({super.key});

  static const String _imageUrl = 'https://picsum.photos/id/1015/1200/800';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Pinch to zoom, drag to pan'),
        ),
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: Image.network(
                _imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (BuildContext context, Object error,
                        StackTrace? stackTrace) =>
                    const Center(
                        child: Text('Failed to load image — check internet')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// C. VIDEO — "Play one video within app (media player)"
// ===========================================================================
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  static const String _videoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  late final VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(_videoUrl))
      ..addListener(_listener)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      }).catchError((Object e) {
        if (mounted) setState(() => _error = 'Could not load video: $e');
      });
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        VideoProgressIndicator(_controller, allowScrubbing: true),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton.filled(
              iconSize: 36,
              onPressed: _togglePlay,
              icon: Icon(_controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            ),
            const SizedBox(width: 12),
            IconButton.filledTonal(
              iconSize: 36,
              onPressed: () {
                _controller.seekTo(Duration.zero);
                _controller.pause();
                setState(() {});
              },
              icon: const Icon(Icons.stop),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// D. AUDIO — "Play one audio within app (media player)"
// ===========================================================================
class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  static const String _audioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];

  // Local state to prevent the slider from "jumping" while dragging.
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.onPlayerStateChanged.listen(
        (PlayerState s) {
          if (mounted) setState(() => _state = s);
        }));
    _subs.add(_player.onDurationChanged
        .listen((Duration d) {
          if (mounted) setState(() => _duration = d);
        }));
    _subs.add(_player.onPositionChanged
        .listen((Duration p) {
          if (mounted) setState(() => _position = p);
        }));
  }

  @override
  void dispose() {
    for (final StreamSubscription<dynamic> s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_state == PlayerState.paused) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(_audioUrl));
    }
  }

  String _fmt(Duration d) {
    final String m = d.inMinutes.toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bool playing = _state == PlayerState.playing;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.music_note,
                size: 96, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            const Text('SoundHelix — Song 1',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Slider(
              min: 0,
              max: _duration.inMilliseconds
                  .toDouble()
                  .clamp(1, double.infinity),
              value: _dragValue ??
                  _position.inMilliseconds
                      .toDouble()
                      .clamp(0, _duration.inMilliseconds.toDouble()),
              onChanged: (double v) {
                setState(() => _dragValue = v);
              },
              onChangeEnd: (double v) async {
                await _player.seek(Duration(milliseconds: v.toInt()));
                setState(() => _dragValue = null);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[Text(_fmt(_position)), Text(_fmt(_duration))],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton.filled(
                  iconSize: 40,
                  onPressed: playing ? _player.pause : _play,
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  iconSize: 40,
                  onPressed: () async {
                    await _player.stop();
                    setState(() => _position = Duration.zero);
                  },
                  icon: const Icon(Icons.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
