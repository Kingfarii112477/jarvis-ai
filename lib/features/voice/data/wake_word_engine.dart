import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pluggable "is the wake word being said right now" seam. The app ships
/// [EnergyThresholdWakeWordEngine] — a genuine, working implementation,
/// not a stub — but it only detects *that someone spoke loudly enough*,
/// not the specific word. For true keyword spotting ("Hey Jarvis" vs. any
/// other loud sound), swap the provider override in `main.dart` for an
/// implementation backed by an on-device model such as Picovoice Porcupine
/// or openWakeWord; both need a native plugin + a model/access key this
/// repo can't ship, which is why they aren't wired in by default.
abstract class WakeWordEngine {
  Future<bool> detect(List<int> pcmBytes, {required double sensitivity});
}

class EnergyThresholdWakeWordEngine implements WakeWordEngine {
  @override
  Future<bool> detect(List<int> pcmBytes, {required double sensitivity}) async {
    if (pcmBytes.length < 2) return false;
    var totalEnergy = 0.0;
    var sampleCount = 0;
    for (var i = 0; i < pcmBytes.length - 1; i += 2) {
      final sample = (pcmBytes[i] | (pcmBytes[i + 1] << 8)).toSigned(16);
      totalEnergy += sample * sample;
      sampleCount++;
    }
    if (sampleCount == 0) return false;
    final averageEnergy = totalEnergy / sampleCount;
    final threshold = (32768 * 32768) * sensitivity;
    return averageEnergy > threshold;
  }
}

final wakeWordEngineProvider = Provider<WakeWordEngine>((ref) => EnergyThresholdWakeWordEngine());
