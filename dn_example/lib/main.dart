import 'package:dartnative/dartnative.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'dartnative_plugin_registrant.dart';

void main() {
  // Platform bindings + plugins' FFI symbols. Keep as the first line.
  DartNativePluginRegistrant.registerAll();
  runApp(const App(home: SoLoudDemo()));
}

/// Smoke test for flutter_soloud on DartNative: engine init, a generated
/// tone, an MP3 asset (loadAsset → loadAssetBytes) and an Opus asset (the
/// Xiph libraries linked by the build hook).
class SoLoudDemo extends StatefulWidget {
  const SoLoudDemo({super.key});

  @override
  State<SoLoudDemo> createState() => _SoLoudDemoState();
}

class _SoLoudDemoState extends State<SoLoudDemo> {
  final _soloud = SoLoud.instance;
  final _log = <String>[];
  AudioSource? _tone;
  AudioSource? _explosion;
  AudioSource? _opus;

  void _add(String line) {
    debugPrint('[soloud_demo] $line');
    setState(() => _log.insert(0, line));
  }

  Future<void> _run(String label, Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      _add('$label failed: $e');
    }
  }

  Future<void> _init() => _run('init', () async {
    if (_soloud.isInitialized) {
      _add('already initialized');
      return;
    }
    await _soloud.init();
    _add('init ok');
  });

  Future<void> _playTone() => _run('tone', () async {
    _tone ??= await _soloud.loadWaveform(WaveForm.sin, true, 0.25, 1);
    _soloud.setWaveformFreq(_tone!, 440);
    final handle = _soloud.play(_tone!, volume: 0.4);
    _soloud.scheduleStop(handle, const Duration(milliseconds: 600));
    _add('tone 440 Hz playing');
  });

  Future<void> _playExplosion() => _run('mp3 asset', () async {
    _explosion ??= await _soloud.loadAsset('assets/audio/explosion.mp3');
    _soloud.play(_explosion!);
    _add('mp3 asset playing • ${_soloud.getLength(_explosion!)}');
  });

  Future<void> _playOpus() => _run('opus asset', () async {
    _opus ??= await _soloud.loadAsset(
      'assets/audio/sample-OPUS.opus',
      mode: LoadMode.disk,
    );
    final handle = _soloud.play(_opus!);
    _soloud.scheduleStop(handle, const Duration(seconds: 3));
    _add('opus asset playing (3 s) • ${_soloud.getLength(_opus!)}');
  });

  /// Keeps native code calling Dart for the next 8 s, so a hot restart
  /// (capital R) pressed meanwhile lands while callbacks are still firing: 200
  /// quiet voices whose native scheduleStop()s end one every 40 ms (each
  /// end fires the voice-ended callback), plus the visualization callback.
  Future<void> _stressCallbacks() => _run('callback stress', () async {
    _tone ??= await _soloud.loadWaveform(WaveForm.sin, true, 0.25, 1);
    _soloud.setWaveformFreq(_tone!, 440);
    for (var i = 0; i < 200; i++) {
      final handle = _soloud.play(_tone!, volume: 0.005);
      _soloud.scheduleStop(handle, Duration(milliseconds: 100 + i * 40));
    }
    _soloud.setVisualizationEnabled(true);
    _add('callback stress running (8 s): hot restart now');
  });

  Future<void> _deinit() => _run('deinit', () async {
    _soloud.deinit();
    _tone = _explosion = _opus = null;
    _add('deinit ok');
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_soloud on DartNative')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(onPressed: _init, child: const Text('Init')),
            const SizedBox(height: 8),
            FilledButton(onPressed: _playTone, child: const Text('Tone')),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _playExplosion,
              child: const Text('MP3 asset'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _playOpus,
              child: const Text('Opus asset'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _stressCallbacks,
              child: const Text('Callback stress'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _deinit, child: const Text('Deinit')),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [for (final line in _log) Text(line)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
