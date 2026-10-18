import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:archive/archive.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

enum TtsModel {
  northernMale('model.onnx', 'Northern English Male (int8)', 0),
  amyLow('model-amy.onnx', 'US Amy Low (female)', 0),
  libritts('model-libritts.onnx', 'US LibriTTS Medium (multi-speaker)', 0);

  final String fileName;
  final String displayName;
  final int defaultSid;
  const TtsModel(this.fileName, this.displayName, this.defaultSid);
}

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  sherpa_onnx.OfflineTts? _tts;
  TtsModel? _currentModel;
  late final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  bool _initializing = false;
  String? _modelDir;

  Future<String> _getModelDir() async {
    if (_modelDir != null) return _modelDir!;
    final dir = await getApplicationSupportDirectory();
    _modelDir = '${dir.path}/tts-model';
    await Directory(_modelDir!).create(recursive: true);
    return _modelDir!;
  }

  Future<void> init({TtsModel model = TtsModel.amyLow}) async {
    if (_initialized && _currentModel == model) return;
    if (_initializing) return;

    // If switching models, dispose old one
    if (_tts != null) {
      _tts!.free();
      _tts = null;
      _initialized = false;
    }

    _initializing = true;

    try {
      final modelDir = await _getModelDir();

      // Copy model file if not present
      final modelFile = File('$modelDir/${model.fileName}');
      if (!await modelFile.exists()) {
        await _copyAsset('assets/tts-model/${model.fileName}', modelFile.path);
      }

      final tokensFile = File('$modelDir/tokens.txt');
      if (!await tokensFile.exists()) {
        await _copyAsset('assets/tts-model/tokens.txt', tokensFile.path);
      }

      // Extract espeak-ng-data from zip if not present
      final espeakDir = Directory('$modelDir/espeak-ng-data');
      if (!await espeakDir.exists()) {
        await _extractEspeakZip(modelDir);
      }

      // Initialize sherpa-onnx
      sherpa_onnx.initBindings();

      final vits = sherpa_onnx.OfflineTtsVitsModelConfig(
        model: modelFile.path,
        tokens: tokensFile.path,
        dataDir: espeakDir.path,
      );

      final modelConfig = sherpa_onnx.OfflineTtsModelConfig(
        vits: vits,
        numThreads: 2,
        debug: false,
        provider: 'cpu',
      );

      final config = sherpa_onnx.OfflineTtsConfig(
        model: modelConfig,
        maxNumSenetences: 1,
      );

      _tts = sherpa_onnx.OfflineTts(config);
      _currentModel = model;
      _initialized = true;
      debugPrint('TTS initialized: ${model.displayName}, sample rate: ${_tts!.sampleRate}');
    } catch (e, st) {
      _initializing = false;
      debugPrint('TTS init error: $e');
      debugPrint('TTS init stack: $st');
      rethrow;
    }
    _initializing = false;
  }

  Future<void> _copyAsset(String assetPath, String destPath) async {
    final data = await rootBundle.load(assetPath);
    await File(destPath).writeAsBytes(data.buffer.asUint8List());
  }

  Future<void> _extractEspeakZip(String destDir) async {
    final zipData = await rootBundle.load('assets/tts-model/espeak-ng-data.zip');
    final bytes = zipData.buffer.asUint8List();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final path = '$destDir/${file.name}';
      if (file.isFile) {
        final outFile = File(path);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        await Directory(path).create(recursive: true);
      }
    }
  }

  Future<void> speak(String text, {double? rate, int? sid}) async {
    if (!_initialized) {
      await init();
    }

    if (_tts == null) return;

    await _player.stop();

    final speed = rate != null ? (0.45 / rate) : 1.0;
    final speakerId = sid ?? _currentModel?.defaultSid ?? 0;
    debugPrint('TTS generating: "$text" speed=$speed sid=$speakerId');
    final audio = _tts!.generate(text: text, sid: speakerId, speed: speed);
    debugPrint('TTS generated: ${audio.samples.length} samples at ${audio.sampleRate}Hz');

    if (audio.samples.isEmpty) return;

    // Convert to mono WAV
    final wavBytes = _pcmToWav(audio.samples, audio.sampleRate);

    // Write to temp file and play
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/tts_output.wav');
    await tempFile.writeAsBytes(wavBytes);

    await _player.setFilePath(tempFile.path);
    await _player.play();
  }

  /// Convert mono Float32 PCM to mono WAV
  List<int> _pcmToWav(Float32List samples, int sampleRate) {
    final int16Samples = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      double s = samples[i];
      if (s > 1.0) s = 1.0;
      if (s < -1.0) s = -1.0;
      int16Samples[i] = (s * 32767).round();
    }

    final dataByteLength = int16Samples.length * 2;
    final header = ByteData(44);
    // RIFF
    header.setUint8(0, 0x52); header.setUint8(1, 0x49);
    header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    header.setUint32(4, 36 + dataByteLength, Endian.little);
    header.setUint8(8, 0x57); header.setUint8(9, 0x41);
    header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    // fmt
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D);
    header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);  // PCM
    header.setUint16(22, 1, Endian.little);  // mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    header.setUint16(32, 2, Endian.little);  // block align
    header.setUint16(34, 16, Endian.little); // bits per sample
    // data
    header.setUint8(36, 0x64); header.setUint8(37, 0x61);
    header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    header.setUint32(40, dataByteLength, Endian.little);

    final result = <int>[];
    result.addAll(header.buffer.asUint8List());
    result.addAll(int16Samples.buffer.asUint8List());
    return result;
  }

  int get sampleRate => _tts?.sampleRate ?? 22050;
  TtsModel? get currentModel => _currentModel;

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> setLanguage(String lang) async {}

  Future<void> setRate(double rate) async {}
}
