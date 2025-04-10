import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart'; // <-- REPLACE flutter_sound with just_audio
import 'package:logger/logger.dart';

// If you keep the same enum states, you can do so:
enum AudioPlayerState {
  stopped,
  playing,
  paused,
  loading,
  error,
}

final logger = Logger();

// Simple provider for the player's current state
final playerStateProvider = StateProvider<AudioPlayerState>((ref) => AudioPlayerState.stopped);

// Current position provider
final positionProvider = StateProvider<Duration>((ref) => Duration.zero);

// Audio duration provider
final durationProvider = StateProvider<Duration>((ref) => Duration.zero);

// Volume provider (0.0 to 1.0)
final volumeProvider = StateProvider<double>((ref) => 1.0);

class JustAudioPlayer extends ConsumerStatefulWidget {
  final String audioPath;
  final String title;
  final VoidCallback? onDelete;

  const JustAudioPlayer({
    super.key,
    required this.audioPath,
    this.title = 'Audio Recording',
    this.onDelete,
  });

  @override
  ConsumerState<JustAudioPlayer> createState() => _JustAudioPlayerState();
}

class _JustAudioPlayerState extends ConsumerState<JustAudioPlayer> {
  /// Replace FlutterSoundPlayer with a JustAudio [AudioPlayer].
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;
  bool _fileExists = false;
  double _fileSize = 0;

  // We’ll set up listeners for position/duration/playerState
  late final _positionSub = _audioPlayer.positionStream.listen((pos) {
    ref.read(positionProvider.notifier).state = pos;
  });

  late final _durationSub = _audioPlayer.durationStream.listen((dur) {
    // durationStream can be null if no track is loaded
    if (dur != null) {
      ref.read(durationProvider.notifier).state = dur;
    }
  });

  late final _playerStateSub = _audioPlayer.playerStateStream.listen((playerState) {
    // Just Audio tracks combined “processing state” & “playing” in one object
    // We'll interpret it to set our provider's state
    if (playerState.processingState == ProcessingState.idle) {
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.stopped;
    } else if (playerState.processingState == ProcessingState.loading ||
               playerState.processingState == ProcessingState.buffering) {
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.loading;
    } else if (playerState.playing) {
      // If “playing” is true, then we are playing
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.playing;
    } else {
      // If not playing but loaded, let's consider it paused
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.paused;
    }

    // If we detect completed
    if (playerState.processingState == ProcessingState.completed) {
      // Playback finished naturally
      logger.d('Playback finished');
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.stopped;
      ref.read(positionProvider.notifier).state = Duration.zero;
      // Stop the player to reset it
      _audioPlayer.stop();
    }
  });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFile());
  }

  Future<void> _checkFile() async {
    if (!mounted) return;
    ref.read(playerStateProvider.notifier).state = AudioPlayerState.loading;

    try {
      logger.d('Checking audio file at path: ${widget.audioPath}');

      final file = File(widget.audioPath);
      final exists = await file.exists();

      if (exists) {
        final size = await file.length();
        logger.d('File exists, size = ${size / 1024} KB');

        setState(() {
          _fileExists = true;
          _fileSize = size / 1024;
        });

        // Check for minimal size threshold
        if (size < 100) {
          logger.w('Audio file is too small: ${_fileSize.toStringAsFixed(1)} KB');
          ref.read(playerStateProvider.notifier).state = AudioPlayerState.error;
          return;
        }

        // Load file into JustAudio
        await _initPlayer(widget.audioPath);
        ref.read(playerStateProvider.notifier).state = AudioPlayerState.stopped;
      } else {
        logger.e('Audio file not found at path: ${widget.audioPath}');
        ref.read(playerStateProvider.notifier).state = AudioPlayerState.error;
      }
    } catch (e, st) {
      logger.e('Error checking audio file: $e', error: e, stackTrace: st);
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.error;
    }
  }

  Future<void> _initPlayer(String path) async {
    try {
      // If already playing something, stop
      await _audioPlayer.stop();

      // Set volume from our provider
      final currentVolume = ref.read(volumeProvider);
      await _audioPlayer.setVolume(currentVolume);

      // Load the file
      // This automatically sets duration if successful
      await _audioPlayer.setFilePath(path);

      _isInitialized = true;
      logger.d('JustAudio: Player initialized with file $path');
    } catch (e, st) {
      logger.e('Error initializing JustAudio player: $e', error: e, stackTrace: st);
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.error;
    }
  }

  Future<void> _playAudio() async {
    if (!_isInitialized || !_fileExists) {
      logger.d('Not initialized or file missing - re-checking file');
      await _checkFile();
      if (!_isInitialized || !_fileExists) {
        logger.e('Still not initialized or file missing');
        return;
      }
    }
    try {
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.loading;
      logger.d('Starting playback of file: ${widget.audioPath}');

      // Make sure volume is up to date
      final currentVolume = ref.read(volumeProvider);
      await _audioPlayer.setVolume(currentVolume);

      // Play
      await _audioPlayer.play();
      // The subscription stream will set the state to .playing

      logger.d('JustAudio: playback started');
    } catch (e, st) {
      logger.e('Error playing audio: $e', error: e, stackTrace: st);
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.error;
    }
  }

  Future<void> _pauseAudio() async {
    if (!_isInitialized || !_fileExists) return;

    try {
      await _audioPlayer.pause();
      // The subscription stream will set the state to .paused
      logger.d('JustAudio: playback paused');
    } catch (e, st) {
      logger.e('Error pausing audio: $e', error: e, stackTrace: st);
    }
  }

  Future<void> _resumeAudio() async {
    if (!_isInitialized || !_fileExists) return;

    try {
      await _audioPlayer.play();
      // The subscription stream will set .playing
      logger.d('JustAudio: playback resumed');
    } catch (e, st) {
      logger.e('Error resuming audio: $e', error: e, stackTrace: st);
    }
  }

  Future<void> _stopAudio() async {
    if (!_isInitialized || !_fileExists) return;

    try {
      await _audioPlayer.stop();
      ref.read(playerStateProvider.notifier).state = AudioPlayerState.stopped;
      ref.read(positionProvider.notifier).state = Duration.zero;
      logger.d('JustAudio: playback stopped');
    } catch (e, st) {
      logger.e('Error stopping audio: $e', error: e, stackTrace: st);
    }
  }

  Future<void> _seekTo(Duration position) async {
    if (!_isInitialized || !_fileExists) return;

    try {
      await _audioPlayer.seek(position);
      ref.read(positionProvider.notifier).state = position;
      logger.d('JustAudio: Seeked to position: ${position.inSeconds}s');
    } catch (e, st) {
      logger.e('Error seeking audio: $e', error: e, stackTrace: st);
    }
  }

  void _setVolume(double volume) async {
    // Even if not playing, we can set volume
    try {
      await _audioPlayer.setVolume(volume);
      ref.read(volumeProvider.notifier).state = volume;
      logger.d('JustAudio: Set volume to: $volume');
    } catch (e, st) {
      logger.e('Error setting volume: $e', error: e, stackTrace: st);
    }
  }

  Future<void> _tryAgain() async {
    ref.read(playerStateProvider.notifier).state = AudioPlayerState.loading;
    // Re-check
    await _audioPlayer.stop();
    _isInitialized = false;
    await _checkFile();
  }

  Future<void> _confirmDelete() async {
    if (widget.onDelete == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text(
          'Are you sure you want to delete this audio recording? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onDelete?.call();
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Cancel streams
    _positionSub.cancel();
    _durationSub.cancel();
    _playerStateSub.cancel();
    // Dispose of the player
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerStateProvider);
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);
    final volume = ref.watch(volumeProvider);

    if (playerState == AudioPlayerState.error) {
      return _buildErrorCard();
    }

    if (playerState == AudioPlayerState.loading) {
      return _buildLoadingCard();
    }

    if (!_fileExists) {
      return _buildFileMissingCard();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${_fileSize.toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: _confirmDelete,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Audio waveform visualization
            // (fake static/active waveforms)
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: playerState == AudioPlayerState.playing
                  ? _buildActiveWaveform()
                  : _buildStaticWaveform(),
            ),

            const SizedBox(height: 16),

            // Playback position and duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position)),
                Text(_formatDuration(duration)),
              ],
            ),

            // Seek slider
            Slider(
              value: position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds.toDouble() == 0
                  ? 1
                  : duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                _seekTo(Duration(milliseconds: value.round()));
              },
              activeColor: Theme.of(context).primaryColor,
            ),

            // Player controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Volume control
                IconButton(
                  icon: Icon(
                    volume > 0.5
                        ? Icons.volume_up
                        : (volume > 0 ? Icons.volume_down : Icons.volume_off),
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Adjust Volume'),
                        content: StatefulBuilder(
                          builder: (builderContext, setLocalState) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.volume_down),
                                  Expanded(
                                    child: Slider(
                                      value: volume,
                                      min: 0.0,
                                      max: 1.0,
                                      onChanged: (val) {
                                        setLocalState(() {
                                          _setVolume(val);
                                        });
                                      },
                                    ),
                                  ),
                                  const Icon(Icons.volume_up),
                                ],
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('CLOSE'),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Skip backward button
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final newPos = (position - const Duration(seconds: 10));
                    _seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),

                // Play/Pause button
                IconButton(
                  icon: Icon(
                    playerState == AudioPlayerState.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    if (playerState == AudioPlayerState.stopped) {
                      _playAudio();
                    } else if (playerState == AudioPlayerState.playing) {
                      _pauseAudio();
                    } else if (playerState == AudioPlayerState.paused) {
                      _resumeAudio();
                    }
                  },
                ),

                // Skip forward button
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    final newPos = position + const Duration(seconds: 10);
                    if (newPos < duration) {
                      _seekTo(newPos);
                    } else {
                      _seekTo(duration);
                    }
                  },
                ),

                const Spacer(),

                // Stop button
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined),
                  onPressed:
                      playerState != AudioPlayerState.stopped ? _stopAudio : null,
                  color: playerState != AudioPlayerState.stopped
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticWaveform() {
    final color = Theme.of(context).primaryColor.withAlpha(77);
    return CustomPaint(
      painter: WaveformPainter(
        waveformData: List.generate(50, (index) => 0.1 + 0.8 * index % 5 / 4),
        color: color,
      ),
    );
  }

  Widget _buildActiveWaveform() {
    return CustomPaint(
      painter: WaveformPainter(
        waveformData: List.generate(
          50,
          (index) => 0.1 + 0.8 * (index + DateTime.now().millisecond) % 10 / 9,
        ),
        color: Theme.of(context).primaryColor,
      ),
      willChange: true,
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Error playing audio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'File may be corrupted or in an unsupported format '
              '(${_fileSize.toStringAsFixed(1)} KB)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _tryAgain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading audio player...'),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMissingCard() {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Audio file not found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'The audio recording could not be found at the expected location',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _tryAgain,
            ),
          ],
        ),
      ),
    );
  }
}

// You can reuse your existing WaveformPainter
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;

  WaveformPainter({
    required this.waveformData,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final segmentWidth = width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * segmentWidth;
      final amplitude = waveformData[i];
      final barHeight = height * amplitude;
      final startY = (height - barHeight) / 2;
      final endY = startY + barHeight;

      canvas.drawLine(
        Offset(x + segmentWidth / 2, startY),
        Offset(x + segmentWidth / 2, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.waveformData != waveformData;
  }
}
