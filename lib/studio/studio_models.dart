import 'dart:typed_data';

import 'package:flutter/material.dart';

class EqualizerBand {
  const EqualizerBand({
    required this.id,
    required this.frequency,
    required this.gain,
  });

  final String id;
  final String frequency;
  final double gain;

  EqualizerBand copyWith({double? gain}) =>
      EqualizerBand(id: id, frequency: frequency, gain: gain ?? this.gain);
}

class EqualizerPreset {
  const EqualizerPreset({
    required this.name,
    required this.description,
    required this.icon,
    required this.gains,
    required this.accentValue,
    this.isCustom = false,
  });

  final String name;
  final String description;
  final IconData icon;
  final List<double> gains;
  final int accentValue;
  final bool isCustom;
}

class AudioTrack {
  const AudioTrack({
    required this.name,
    required this.extension,
    required this.size,
    required this.bytes,
  });

  final String name;
  final String extension;
  final int size;
  final Uint8List bytes;

  String get displaySize {
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / 1024).toStringAsFixed(0)} KB';
  }
}
