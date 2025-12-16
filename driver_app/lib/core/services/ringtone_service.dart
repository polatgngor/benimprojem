import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ringtoneServiceProvider = Provider<RingtoneService>((ref) {
  return RingtoneService();
});

class RingtoneService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  Future<void> playRingtone() async {
    if (_isPlaying) return;

    try {
      // Set release mode to loop so it plays continuously until stopped
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // Play from assets
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
      _isPlaying = true;
    } catch (e) {
      print('Error playing ringtone: $e');
    }
  }

  Future<void> stopRingtone() async {
    if (!_isPlaying) return;

    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping ringtone: $e');
    }
  }
}
