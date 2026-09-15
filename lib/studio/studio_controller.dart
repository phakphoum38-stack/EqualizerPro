import 'dart:async';
import 'dart:math' as math;

import 'package:audio_session/audio_session.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'studio_models.dart';

class StudioController extends ChangeNotifier {
  StudioController({required this.audioEnabled});

  static const _frequencies = <String>[
    '32',
    '64',
    '125',
    '250',
    '500',
    '1K',
    '2K',
    '4K',
    '8K',
    '16K',
  ];

  static const _supportedExtensions = <String>{'mp3', 'wav', 'ogg', 'flac'};

  final bool audioEnabled;
  SoLoud? _engineInstance;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  StreamSubscription<StreamSoundEvent>? _soundEventSubscription;
  Timer? _meterTimer;
  AudioSource? _source;
  SoundHandle? _handle;
  AudioData? _audioData;
  bool _disposed = false;

  SoLoud get _engine => _engineInstance ??= SoLoud.instance;

  List<EqualizerBand> bands = List.generate(
    _frequencies.length,
    (index) => EqualizerBand(
      id: 'band-$index',
      frequency: _frequencies[index],
      gain: _starterCurve[index],
    ),
  );

  final List<AudioTrack> tracks = [];
  final List<EqualizerPreset> customPresets = [];

  int selectedTab = 0;
  int? currentTrackIndex;
  bool isPlaying = false;
  bool isLoadingTrack = false;
  bool isDraggingFile = false;
  bool equalizerEnabled = true;
  bool isEngineReady = false;
  bool favorite = false;
  bool shuffle = false;
  bool repeat = false;
  double bassBoost = 0.42;
  double spatialAudio = 0.34;
  double stereoWidth = 0.68;
  double outputGain = 0.76;
  bool normalize = true;
  bool warmSaturation = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  List<double> waveSamples = const [];
  String activePresetName = 'Signature';
  String? message;
  bool messageIsError = false;

  static const List<double> _starterCurve = [
    3.2,
    4.5,
    2.1,
    -0.7,
    -1.8,
    0.4,
    2.8,
    4.2,
    3.1,
    1.5,
  ];

  static const List<EqualizerPreset> builtInPresets = [
    EqualizerPreset(
      name: 'Signature',
      description: 'Wide, detailed and punchy',
      icon: Icons.auto_awesome_rounded,
      gains: _starterCurve,
      accentValue: 0xFFC8FF3D,
    ),
    EqualizerPreset(
      name: 'Deep Bass',
      description: 'Weight without the mud',
      icon: Icons.speaker_group_rounded,
      gains: [6.0, 5.7, 4.1, 2.2, 0.2, -0.8, -0.5, 0.3, 1.0, 0.8],
      accentValue: 0xFFFF8B5D,
    ),
    EqualizerPreset(
      name: 'Vocal Focus',
      description: 'Clear speech and lyrics',
      icon: Icons.mic_rounded,
      gains: [-2.4, -1.9, -1.0, 0.8, 2.8, 4.8, 5.1, 3.0, 1.2, 0.0],
      accentValue: 0xFF5FE7FF,
    ),
    EqualizerPreset(
      name: 'Night Drive',
      description: 'Smooth, dark and immersive',
      icon: Icons.nightlight_round,
      gains: [4.1, 3.8, 2.5, 0.5, -1.6, -0.8, 1.1, 2.4, 1.2, -1.0],
      accentValue: 0xFFB28CFF,
    ),
    EqualizerPreset(
      name: 'Studio Flat',
      description: 'Honest reference response',
      icon: Icons.linear_scale_rounded,
      gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      accentValue: 0xFFE8EDF3,
    ),
    EqualizerPreset(
      name: 'Air & Detail',
      description: 'Open, bright high-end',
      icon: Icons.air_rounded,
      gains: [-1.0, -0.8, -0.4, 0.0, 0.7, 1.6, 2.5, 4.0, 5.4, 6.0],
      accentValue: 0xFFFFD86B,
    ),
  ];

  AudioTrack? get currentTrack => currentTrackIndex == null
      ? null
      : tracks.elementAtOrNull(currentTrackIndex!);

  List<EqualizerPreset> get allPresets => [...builtInPresets, ...customPresets];

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0, 1);
  }

  Future<void> initialize() async {
    await _restoreSettings();
    if (!audioEnabled || _disposed) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
      await _engine.init(
        automaticCleanup: true,
        bufferSize: 1024,
        channels: Channels.stereo,
        lowLatency: false,
      );
      _engine
        ..setGlobalVolume(outputGain)
        ..setVisualizationEnabled(true)
        ..setFftSmoothing(0.72);
      _audioData = AudioData(GetSamplesKind.wave);
      _configureDsp();
      _listenForAudioInterruptions(session);
      _startMeter();
      isEngineReady = true;
      notifyListeners();
    } catch (error) {
      isEngineReady = false;
      _setMessage(
        'DSP audio engine is unavailable on this device: $error',
        true,
      );
    }
  }

  void _listenForAudioInterruptions(AudioSession session) {
    _subscriptions.add(
      session.becomingNoisyEventStream.listen((_) {
        final handle = _validHandle;
        if (handle != null && isPlaying) {
          _engine.setPause(handle, true);
          isPlaying = false;
          notifyListeners();
        }
      }),
    );
    _subscriptions.add(
      session.interruptionEventStream.listen((event) {
        if (!isEngineReady) return;
        if (event.begin) {
          if (event.type == AudioInterruptionType.duck) {
            _engine.fadeGlobalVolume(
              outputGain * 0.2,
              const Duration(milliseconds: 250),
            );
          } else {
            final handle = _validHandle;
            if (handle != null) _engine.setPause(handle, true);
            isPlaying = false;
            notifyListeners();
          }
        } else if (event.type == AudioInterruptionType.duck) {
          _engine.fadeGlobalVolume(
            outputGain,
            const Duration(milliseconds: 250),
          );
        }
      }),
    );
  }

  void _startMeter() {
    _meterTimer?.cancel();
    _meterTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_disposed || !isEngineReady) return;
      final handle = _validHandle;
      if (handle != null) {
        position = _engine.getPosition(handle);
      }
      try {
        _audioData?.updateSamples();
        waveSamples =
            _audioData
                ?.getAudioData(alwaysReturnData: false)
                .map((sample) => sample.toDouble())
                .toList(growable: false) ??
            waveSamples;
      } on Exception {
        // Visualization is secondary to playback; keep the last valid frame.
      }
      notifyListeners();
    });
  }

  SoundHandle? get _validHandle {
    final handle = _handle;
    if (handle == null || !isEngineReady) return null;
    try {
      return _engine.getIsValidVoiceHandle(handle) ? handle : null;
    } on Exception {
      return null;
    }
  }

  void _configureDsp() {
    final equalizer = _engine.filters.parametricEqFilter;
    if (!equalizer.isActive) equalizer.activate();
    equalizer
      ..stftWindowSize.value = 2048
      ..numBands.value = bands.length.toDouble()
      ..wet.value = equalizerEnabled ? 1 : 0;
    _applyEqualizerBands();

    final bass = _engine.filters.bassBoostFilter;
    if (!bass.isActive) bass.activate();
    bass
      ..wet.value = bassBoost
      ..boost.value = 1 + bassBoost * 6;

    final space = _engine.filters.freeverbFilter;
    if (!space.isActive) space.activate();
    space
      ..wet.value = spatialAudio * 0.42
      ..roomSize.value = 0.2 + spatialAudio * 0.75
      ..damp.value = 0.28 + spatialAudio * 0.5
      ..width.value = stereoWidth;

    final warmth = _engine.filters.waveShaperFilter;
    if (!warmth.isActive) warmth.activate();
    warmth
      ..wet.value = warmSaturation ? 0.32 : 0
      ..amount.value = warmSaturation ? 0.18 : 0;

    final compressor = _engine.filters.compressorFilter;
    if (!compressor.isActive) compressor.activate();
    compressor
      ..wet.value = normalize ? 0.86 : 0
      ..threshold.value = -18
      ..makeupGain.value = 3
      ..kneeWidth.value = 6
      ..ratio.value = 3
      ..attackTime.value = 12
      ..releaseTime.value = 180;

    final limiter = _engine.filters.limiterFilter;
    if (!limiter.isActive) limiter.activate();
    limiter
      ..wet.value = 1
      ..threshold.value = -2
      ..outputCeiling.value = -0.6
      ..kneeWidth.value = 2
      ..attackTime.value = 1
      ..releaseTime.value = 100;
  }

  void _applyEqualizerBands() {
    if (!isEngineReady && !_engine.isInitialized) return;
    final equalizer = _engine.filters.parametricEqFilter;
    for (final band in bands) {
      final engineIndex = _bandIndex(band);
      equalizer.bandGain(engineIndex).value = math
          .pow(10, band.gain / 20)
          .toDouble()
          .clamp(0, 4);
    }
  }

  int _bandIndex(EqualizerBand band) =>
      int.tryParse(band.id.split('-').last) ?? 0;

  List<double> _gainsInFrequencyOrder() => List.generate(
    bands.length,
    (index) => bands.firstWhere((band) => _bandIndex(band) == index).gain,
  );

  Future<void> _restoreSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final savedGains = preferences.getStringList('eq.gains');
    if (savedGains?.length == bands.length) {
      bands = [
        for (var i = 0; i < bands.length; i++)
          bands[i].copyWith(
            gain: double.tryParse(savedGains![i]) ?? bands[i].gain,
          ),
      ];
    }
    bassBoost = preferences.getDouble('effect.bass') ?? bassBoost;
    spatialAudio = preferences.getDouble('effect.spatial') ?? spatialAudio;
    stereoWidth = preferences.getDouble('effect.width') ?? stereoWidth;
    outputGain = preferences.getDouble('effect.output') ?? outputGain;
    normalize = preferences.getBool('effect.normalize') ?? normalize;
    warmSaturation = preferences.getBool('effect.warm') ?? warmSaturation;
    equalizerEnabled = preferences.getBool('eq.enabled') ?? equalizerEnabled;
    activePresetName = preferences.getString('eq.preset') ?? activePresetName;
    notifyListeners();
  }

  Future<void> _persistSettings() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      'eq.gains',
      _gainsInFrequencyOrder().map((gain) => gain.toStringAsFixed(2)).toList(),
    );
    await preferences.setDouble('effect.bass', bassBoost);
    await preferences.setDouble('effect.spatial', spatialAudio);
    await preferences.setDouble('effect.width', stereoWidth);
    await preferences.setDouble('effect.output', outputGain);
    await preferences.setBool('effect.normalize', normalize);
    await preferences.setBool('effect.warm', warmSaturation);
    await preferences.setBool('eq.enabled', equalizerEnabled);
    await preferences.setString('eq.preset', activePresetName);
  }

  void selectTab(int index) {
    selectedTab = index;
    notifyListeners();
  }

  void setDraggingFile(bool value) {
    isDraggingFile = value;
    notifyListeners();
  }

  Future<void> pickAudioFiles({bool multiple = false}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _supportedExtensions.toList(),
        allowMultiple: multiple,
        withData: true,
      );
      if (result == null) return;
      for (final file in result.files) {
        final bytes = file.bytes ?? await file.xFile.readAsBytes();
        await addAudioBytes(file.name, bytes);
      }
    } catch (error) {
      _setMessage('Could not open the selected file: $error', true);
    }
  }

  Future<void> addDroppedFiles(List<DropItem> files) async {
    isDraggingFile = false;
    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        await addAudioBytes(file.name, bytes);
      } catch (error) {
        _setMessage('Could not read ${file.name}: $error', true);
      }
    }
  }

  Future<void> addAudioBytes(String fileName, Uint8List bytes) async {
    final extension = fileName.split('.').last.toLowerCase();
    if (!_supportedExtensions.contains(extension)) {
      _setMessage('Unsupported file. Try MP3, WAV, OGG or FLAC.', true);
      return;
    }
    if (bytes.isEmpty) {
      _setMessage('$fileName is empty.', true);
      return;
    }
    final cleanName = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    tracks.add(
      AudioTrack(
        name: cleanName,
        extension: extension.toUpperCase(),
        size: bytes.length,
        bytes: bytes,
      ),
    );
    await playTrack(tracks.length - 1, autoPlay: false);
    _setMessage('${tracks.last.name} added with live DSP enabled.');
  }

  Future<void> playTrack(int index, {bool autoPlay = true}) async {
    if (index < 0 || index >= tracks.length) return;
    currentTrackIndex = index;
    position = Duration.zero;
    duration = Duration.zero;
    waveSamples = const [];
    isLoadingTrack = true;
    notifyListeners();
    if (!isEngineReady) {
      isLoadingTrack = false;
      _setMessage('The DSP audio engine is not ready on this device.', true);
      return;
    }
    try {
      await _releaseCurrentSource();
      final track = tracks[index];
      _source = await _engine.loadMem(
        'session-$index-${track.name}.${track.extension.toLowerCase()}',
        track.bytes,
        mode: LoadMode.memory,
      );
      duration = _engine.getLength(_source!);
      _handle = _engine.play(_source!, paused: !autoPlay, looping: repeat);
      _soundEventSubscription = _source!.soundEvents.listen((event) {
        if (event.event == SoundEventType.handleIsNoMoreValid &&
            event.handle == _handle) {
          isPlaying = false;
          position = duration;
          _handle = null;
          notifyListeners();
          unawaited(_handleTrackCompleted());
        }
      });
      isPlaying = autoPlay;
    } catch (error) {
      isPlaying = false;
      _setMessage('This audio file could not be decoded: $error', true);
    } finally {
      isLoadingTrack = false;
      notifyListeners();
    }
  }

  Future<void> _releaseCurrentSource() async {
    await _soundEventSubscription?.cancel();
    _soundEventSubscription = null;
    final handle = _validHandle;
    if (handle != null) await _engine.stop(handle);
    _handle = null;
    final source = _source;
    _source = null;
    if (source != null && _engine.isInitialized) {
      await _engine.disposeSource(source);
    }
  }

  Future<void> togglePlayback() async {
    if (currentTrack == null) {
      _setMessage('Drop an audio file here first.');
      return;
    }
    if (!isEngineReady) {
      _setMessage('The DSP audio engine is not ready on this device.', true);
      return;
    }
    try {
      var handle = _validHandle;
      if (handle == null) {
        await playTrack(currentTrackIndex!);
        return;
      }
      final shouldPause = !_engine.getPause(handle);
      _engine.setPause(handle, shouldPause);
      isPlaying = !shouldPause;
      notifyListeners();
    } catch (error) {
      _setMessage('Playback failed: $error', true);
    }
  }

  Future<void> seek(double value) async {
    final handle = _validHandle;
    if (handle == null || duration == Duration.zero) return;
    _engine.seek(
      handle,
      Duration(milliseconds: (duration.inMilliseconds * value).round()),
    );
    position = _engine.getPosition(handle);
    notifyListeners();
  }

  Future<void> skip(int direction) async {
    if (tracks.isEmpty) return;
    var next = (currentTrackIndex ?? 0) + direction;
    if (repeat || shuffle) {
      next = shuffle
          ? math.Random().nextInt(tracks.length)
          : (next + tracks.length) % tracks.length;
    } else {
      next = next.clamp(0, tracks.length - 1);
    }
    await playTrack(next);
  }

  Future<void> _handleTrackCompleted() async {
    if (_disposed || currentTrackIndex == null) return;
    if (repeat) {
      await playTrack(currentTrackIndex!);
    } else if (currentTrackIndex! < tracks.length - 1) {
      await skip(1);
    }
  }

  void updateBand(int index, double value) {
    bands[index] = bands[index].copyWith(gain: value);
    activePresetName = 'Custom mix';
    _runDsp(_applyEqualizerBands);
    notifyListeners();
    unawaited(_persistSettings());
  }

  void reorderBand(int oldIndex, int newIndex) {
    final band = bands.removeAt(oldIndex);
    bands.insert(newIndex, band);
    activePresetName = 'Custom order';
    notifyListeners();
  }

  void applyPreset(EqualizerPreset preset) {
    bands = [
      for (final band in bands)
        band.copyWith(gain: preset.gains[_bandIndex(band)]),
    ];
    activePresetName = preset.name;
    _runDsp(_applyEqualizerBands);
    notifyListeners();
    unawaited(_persistSettings());
    _setMessage('${preset.name} preset is processing live audio.');
  }

  void resetEqualizer() {
    applyPreset(builtInPresets.first);
  }

  void saveCustomPreset(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    customPresets.add(
      EqualizerPreset(
        name: cleanName,
        description: 'Your custom DSP profile',
        icon: Icons.tune_rounded,
        gains: _gainsInFrequencyOrder(),
        accentValue: 0xFFC8FF3D,
        isCustom: true,
      ),
    );
    activePresetName = cleanName;
    notifyListeners();
    _setMessage('$cleanName saved for this session.');
  }

  void toggleEqualizer() {
    equalizerEnabled = !equalizerEnabled;
    _runDsp(() {
      _engine.filters.parametricEqFilter.wet.value = equalizerEnabled ? 1 : 0;
    });
    notifyListeners();
    unawaited(_persistSettings());
  }

  void toggleFavorite() {
    favorite = !favorite;
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    repeat = !repeat;
    final handle = _validHandle;
    if (handle != null) _engine.setLooping(handle, repeat);
    notifyListeners();
  }

  void setBassBoost(double value) {
    bassBoost = value;
    _runDsp(() {
      final filter = _engine.filters.bassBoostFilter;
      filter
        ..wet.value = value
        ..boost.value = 1 + value * 6;
    });
    notifyListeners();
    unawaited(_persistSettings());
  }

  void setSpatialAudio(double value) {
    spatialAudio = value;
    _runDsp(() {
      final filter = _engine.filters.freeverbFilter;
      filter
        ..wet.value = value * 0.42
        ..roomSize.value = 0.2 + value * 0.75
        ..damp.value = 0.28 + value * 0.5;
    });
    notifyListeners();
    unawaited(_persistSettings());
  }

  void setStereoWidth(double value) {
    stereoWidth = value;
    _runDsp(() {
      _engine.filters.freeverbFilter.width.value = value;
    });
    notifyListeners();
    unawaited(_persistSettings());
  }

  void setOutputGain(double value) {
    outputGain = value;
    _runDsp(() => _engine.setGlobalVolume(value));
    notifyListeners();
    unawaited(_persistSettings());
  }

  void toggleNormalize() {
    normalize = !normalize;
    _runDsp(() {
      _engine.filters.compressorFilter.wet.value = normalize ? 0.86 : 0;
    });
    notifyListeners();
    unawaited(_persistSettings());
  }

  void toggleWarmSaturation() {
    warmSaturation = !warmSaturation;
    _runDsp(() {
      final filter = _engine.filters.waveShaperFilter;
      filter
        ..wet.value = warmSaturation ? 0.32 : 0
        ..amount.value = warmSaturation ? 0.18 : 0;
    });
    notifyListeners();
    unawaited(_persistSettings());
  }

  void _runDsp(VoidCallback operation) {
    if (!isEngineReady || !_engine.isInitialized) return;
    try {
      operation();
    } catch (error) {
      _setMessage('DSP update failed: $error', true);
    }
  }

  void clearMessage() {
    message = null;
    notifyListeners();
  }

  void _setMessage(String value, [bool isError = false]) {
    message = value;
    messageIsError = isError;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _meterTimer?.cancel();
    unawaited(_soundEventSubscription?.cancel());
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _audioData?.dispose();
    final engine = _engineInstance;
    if (engine?.isInitialized ?? false) engine!.deinit();
    super.dispose();
  }
}
