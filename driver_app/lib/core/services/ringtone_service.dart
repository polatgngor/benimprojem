import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

part 'ringtone_service.g.dart';

@Riverpod(keepAlive: true)
RingtoneService ringtoneService(Ref ref) {
  return RingtoneService();
}

class RingtoneService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  RingtoneService() {
    _initAudioContext();
  }

  Future<void> _initAudioContext() async {
    try {
      await _audioPlayer.setAudioContext(AudioContext(
        android: AudioContextAndroid(
           isSpeakerphoneOn: true,
           stayAwake: true,
           contentType: AndroidContentType.music,
           usageType: AndroidUsageType.alarm,
           audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
           category: AVAudioSessionCategory.playback,
           options: {
             AVAudioSessionOptions.duckOthers, 
             AVAudioSessionOptions.mixWithOthers,
             AVAudioSessionOptions.defaultToSpeaker // Ensure speaker on iOS
           }, 
        ),
      ));
    } catch (e) {
      debugPrint('Error init audio context: $e');
    }
  }

  Future<void> playRingtone() async {
    if (_isPlaying) return;

    try {
      // Stop previous if any
      await _audioPlayer.stop();
      _isPlaying = true; 

      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Play
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
      
      debugPrint('🔔 RINGTONE STARTED (Loop Mode) 🔔');
    } catch (e) {
      _isPlaying = false;
      debugPrint('❌ Error playing ringtone: $e');
    }
  }

  Future<void> stopRingtone() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.stop); 
        _isPlaying = false;
        debugPrint('🔕 Ringtone Stopped');
      }
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }
}
