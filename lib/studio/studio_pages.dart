import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'studio_controller.dart';
import 'studio_models.dart';
import 'studio_painters.dart';

class StudioPage extends StatelessWidget {
  const StudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 12, wide ? 32 : 18, 108),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1480),
              child: Column(
                children: [
                  if (wide)
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 8, child: PlayerPanel()),
                        SizedBox(width: 16),
                        Expanded(flex: 4, child: EffectsPanel()),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        PlayerPanel(compact: true),
                        SizedBox(height: 14),
                        EffectsPanel(),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const EqualizerPanel(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    final track = controller.currentTrack;
    return DropTarget(
      onDragEntered: (_) => controller.setDraggingFile(true),
      onDragExited: (_) => controller.setDraggingFile(false),
      onDragDone: (details) => controller.addDroppedFiles(details.files),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: controller.isDraggingFile
              ? const [
                  BoxShadow(
                    color: Color(0x55C8FF3D),
                    blurRadius: 34,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: GlassPanel(
          padding: EdgeInsets.all(compact ? 18 : 24),
          highlighted: controller.isDraggingFile,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: controller.isDraggingFile
                ? const _DropOverlay(key: ValueKey('drop'))
                : Column(
                    key: const ValueKey('player'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const _SectionEyebrow(label: 'NOW PLAYING'),
                          const Spacer(),
                          IconButton(
                            tooltip: controller.favorite
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            onPressed: controller.toggleFavorite,
                            icon: Icon(
                              controller.favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: controller.favorite
                                  ? const Color(0xFFFF7F91)
                                  : Colors.white54,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Add audio',
                            onPressed: controller.pickAudioFiles,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 12 : 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _AlbumArtwork(active: track != null),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track?.name ?? 'Drop a track to begin',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontSize: compact ? 19 : 24),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  track == null
                                      ? 'Your music stays private on this device'
                                      : '${track.extension} • ${track.displaySize} • Local session',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 20 : 28),
                      SizedBox(
                        height: compact ? 72 : 92,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: WaveformPainter(
                            progress: controller.progress,
                            gains: controller.bands
                                .map((band) => band.gain)
                                .toList(),
                            samples: controller.waveSamples,
                            active: track != null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 13,
                          ),
                        ),
                        child: Slider(
                          value: controller.progress,
                          onChanged: track == null ? null : controller.seek,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          children: [
                            Text(
                              formatDuration(controller.position),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              formatDuration(controller.duration),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 12 : 18),
                      _PlaybackControls(compact: compact),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _DropOverlay extends StatelessWidget {
  const _DropOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 430,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFC8FF3D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF12170D),
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Release to add your track',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'MP3, WAV, OGG or FLAC • Live DSP',
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumArtwork extends StatelessWidget {
  const _AlbumArtwork({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC8FF3D), Color(0xFF4BBF98)],
              )
            : const LinearGradient(
                colors: [Color(0xFF252D37), Color(0xFF171D25)],
              ),
        boxShadow: active
            ? const [BoxShadow(color: Color(0x33C8FF3D), blurRadius: 24)]
            : null,
      ),
      child: Icon(
        active ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
        color: active ? const Color(0xFF10170B) : Colors.white30,
        size: 36,
      ),
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleIconButton(
          tooltip: 'Shuffle',
          icon: Icons.shuffle_rounded,
          selected: controller.shuffle,
          onTap: controller.toggleShuffle,
        ),
        SizedBox(width: compact ? 4 : 14),
        IconButton(
          tooltip: 'Previous track',
          onPressed: controller.tracks.isEmpty
              ? null
              : () => controller.skip(-1),
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 30,
        ),
        SizedBox(width: compact ? 6 : 12),
        SizedBox(
          width: 62,
          height: 62,
          child: FilledButton(
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: const Color(0xFFC8FF3D),
              foregroundColor: const Color(0xFF11170B),
            ),
            onPressed: controller.isLoadingTrack
                ? null
                : controller.togglePlayback,
            child: controller.isLoadingTrack
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(
                    controller.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 34,
                  ),
          ),
        ),
        SizedBox(width: compact ? 6 : 12),
        IconButton(
          tooltip: 'Next track',
          onPressed: controller.tracks.isEmpty
              ? null
              : () => controller.skip(1),
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 30,
        ),
        SizedBox(width: compact ? 4 : 14),
        _ToggleIconButton(
          tooltip: 'Repeat',
          icon: Icons.repeat_rounded,
          selected: controller.repeat,
          onTap: controller.toggleRepeat,
        ),
      ],
    );
  }
}

class EffectsPanel extends StatelessWidget {
  const EffectsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionEyebrow(label: 'SOUND EFFECTS'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x185FE7FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  'DSP LIVE',
                  style: TextStyle(
                    color: Color(0xFF5FE7FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          EffectSlider(
            icon: Icons.speaker_group_outlined,
            label: 'Bass boost',
            value: controller.bassBoost,
            onChanged: controller.setBassBoost,
            color: const Color(0xFFFF8B5D),
          ),
          const SizedBox(height: 18),
          EffectSlider(
            icon: Icons.surround_sound_outlined,
            label: 'Spatial audio',
            value: controller.spatialAudio,
            onChanged: controller.setSpatialAudio,
            color: const Color(0xFF5FE7FF),
          ),
          const SizedBox(height: 18),
          EffectSlider(
            icon: Icons.compare_arrows_rounded,
            label: 'Stereo width',
            value: controller.stereoWidth,
            onChanged: controller.setStereoWidth,
            color: const Color(0xFFB28CFF),
          ),
          const SizedBox(height: 18),
          EffectSlider(
            icon: Icons.volume_up_outlined,
            label: 'Output level',
            value: controller.outputGain,
            onChanged: controller.setOutputGain,
            color: const Color(0xFFC8FF3D),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 8),
          EffectSwitch(
            label: 'Auto normalize',
            subtitle: 'Keep loudness consistent',
            value: controller.normalize,
            onChanged: (_) => controller.toggleNormalize(),
          ),
          EffectSwitch(
            label: 'Warm saturation',
            subtitle: 'Add subtle analog color',
            value: controller.warmSaturation,
            onChanged: (_) => controller.toggleWarmSaturation(),
          ),
        ],
      ),
    );
  }
}

class EqualizerPanel extends StatelessWidget {
  const EqualizerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: controller.equalizerEnabled
                          ? 'Bypass equalizer'
                          : 'Enable equalizer',
                      onPressed: controller.toggleEqualizer,
                      icon: Icon(
                        Icons.power_settings_new_rounded,
                        color: controller.equalizerEnabled
                            ? const Color(0xFFC8FF3D)
                            : Colors.white38,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '10-band equalizer',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            controller.activePresetName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFC8FF3D),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'Drag a slider to shape sound • Hold the grip to reorder bands',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: controller.resetEqualizer,
                icon: const Icon(Icons.restart_alt_rounded, size: 17),
                label: const Text('Reset'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showSavePresetDialog(context),
                icon: const Icon(Icons.bookmark_add_outlined, size: 17),
                label: const Text('Save preset'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: controller.equalizerEnabled ? 1 : 0.35,
            child: IgnorePointer(
              ignoring: !controller.equalizerEnabled,
              child: SizedBox(
                height: 270,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  itemCount: controller.bands.length,
                  onReorderItem: controller.reorderBand,
                  proxyDecorator: (child, index, animation) => AnimatedBuilder(
                    animation: animation,
                    builder: (context, _) => Transform.scale(
                      scale: 1 + animation.value * 0.045,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 12 * animation.value,
                        shadowColor: const Color(0x66C8FF3D),
                        child: child,
                      ),
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final band = controller.bands[index];
                    return SizedBox(
                      key: ValueKey(band.id),
                      width: 88,
                      child: EqualizerBandControl(
                        index: index,
                        band: band,
                        onChanged: (value) =>
                            controller.updateBand(index, value),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSavePresetDialog(BuildContext context) async {
    final textController = TextEditingController();
    final studio = context.read<StudioController>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151B24),
        title: const Text('Save sound profile'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. My headphones',
            labelText: 'Preset name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (result != null) studio.saveCustomPreset(result);
  }
}

class PresetsPage extends StatelessWidget {
  const PresetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 10),
          sliver: SliverToBoxAdapter(
            child: GlassPanel(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth >= 700;
                  final copy = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _SectionEyebrow(label: 'CURATED SOUND'),
                      const SizedBox(height: 12),
                      Text(
                        'One tap to a better starting point.',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose a profile, then return to Studio to fine-tune every band.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.48),
                        ),
                      ),
                    ],
                  );
                  final art = Container(
                    width: horizontal ? 250 : double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [Color(0x22C8FF3D), Color(0x115FE7FF)],
                      ),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: CustomPaint(
                      painter: PresetCurvePainter(
                        gains: controller.bands
                            .map((band) => band.gain)
                            .toList(),
                        color: const Color(0xFFC8FF3D),
                      ),
                    ),
                  );
                  return horizontal
                      ? Row(
                          children: [
                            Expanded(child: copy),
                            const SizedBox(width: 22),
                            art,
                          ],
                        )
                      : Column(
                          children: [copy, const SizedBox(height: 18), art],
                        );
                },
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 108),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              mainAxisExtent: 220,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  PresetCard(preset: controller.allPresets[index]),
              childCount: controller.allPresets.length,
            ),
          ),
        ),
      ],
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return DropTarget(
      onDragEntered: (_) => controller.setDraggingFile(true),
      onDragExited: (_) => controller.setDraggingFile(false),
      onDragDone: (details) => controller.addDroppedFiles(details.files),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 108),
        children: [
          _LibraryDropZone(active: controller.isDraggingFile),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Session tracks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 10),
                  CountBadge(count: controller.tracks.length),
                ],
              ),
              TextButton.icon(
                onPressed: () => controller.pickAudioFiles(multiple: true),
                icon: const Icon(Icons.playlist_add_rounded),
                label: const Text('Add multiple'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (controller.tracks.isEmpty)
            const _EmptyLibrary()
          else
            GlassPanel(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (var i = 0; i < controller.tracks.length; i++)
                    _TrackTile(index: i, track: controller.tracks[i]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LibraryDropZone extends StatelessWidget {
  const _LibraryDropZone({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StudioController>();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 190,
      decoration: BoxDecoration(
        color: active ? const Color(0x18C8FF3D) : const Color(0x88111720),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: active
              ? const Color(0xFFC8FF3D)
              : Colors.white.withValues(alpha: 0.08),
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => controller.pickAudioFiles(multiple: true),
        borderRadius: BorderRadius.circular(26),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active
                    ? Icons.file_download_rounded
                    : Icons.cloud_upload_outlined,
                color: active ? const Color(0xFFC8FF3D) : Colors.white54,
                size: 38,
              ),
              const SizedBox(height: 12),
              Text(
                active
                    ? 'Release to import'
                    : 'Drag audio here or click to browse',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              const Text(
                'MP3 • WAV • OGG • FLAC • PROCESSED LOCALLY',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(vertical: 58, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.queue_music_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text('Your session is ready for music'),
            const SizedBox(height: 5),
            const Text(
              'Imported tracks appear here and never leave your device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.index, required this.track});

  final int index;
  final AudioTrack track;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    final selected = controller.currentTrackIndex == index;
    return InkWell(
      onTap: () => controller.playTrack(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0x10C8FF3D) : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.045)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFC8FF3D)
                    : const Color(0xFF202833),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                selected && controller.isPlaying
                    ? Icons.graphic_eq_rounded
                    : Icons.music_note_rounded,
                color: selected ? const Color(0xFF10170B) : Colors.white54,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${track.extension} • ${track.displaySize}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFFC8FF3D),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            IconButton(
              tooltip: selected && controller.isPlaying ? 'Pause' : 'Play',
              onPressed: selected
                  ? controller.togglePlayback
                  : () => controller.playTrack(index),
              icon: Icon(
                selected && controller.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EqualizerBandControl extends StatelessWidget {
  const EqualizerBandControl({
    super.key,
    required this.index,
    required this.band,
    required this.onChanged,
  });

  final int index;
  final EqualizerBand band;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: Colors.white.withValues(alpha: 0.2),
                size: 18,
              ),
            ),
          ),
        ),
        Text(
          gainLabel(band.gain),
          style: TextStyle(
            color: band.gain.abs() < 0.05
                ? Colors.white38
                : const Color(0xFFC8FF3D),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              min: -12,
              max: 12,
              divisions: 48,
              value: band.gain,
              label: '${gainLabel(band.gain)} dB',
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          band.frequency,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        const Text('Hz', style: TextStyle(color: Colors.white30, fontSize: 9)),
      ],
    );
  }
}

class PresetCard extends StatefulWidget {
  const PresetCard({super.key, required this.preset});

  final EqualizerPreset preset;

  @override
  State<PresetCard> createState() => _PresetCardState();
}

class _PresetCardState extends State<PresetCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    final active = controller.activePresetName == widget.preset.name;
    final accent = Color(widget.preset.accentValue);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, hovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.09)
              : const Color(0xDD111720),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active || hovering
                ? accent.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.07),
          ),
          boxShadow: hovering
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.1),
                    blurRadius: 28,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: () => controller.applyPreset(widget.preset),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 39,
                      height: 39,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(widget.preset.icon, color: accent, size: 20),
                    ),
                    const Spacer(),
                    if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Color(0xFF11170B),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.preset.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.preset.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
                const Spacer(),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: PresetCurvePainter(
                      gains: widget.preset.gains,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EffectSlider extends StatelessWidget {
  const EffectSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Text(label, style: const TextStyle(fontSize: 12.5)),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class EffectSwitch extends StatelessWidget {
  const EffectSwitch({
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label, style: const TextStyle(fontSize: 12.5)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white30, fontSize: 10.5),
        ),
        value: value,
        activeThumbColor: const Color(0xFFC8FF3D),
        onChanged: onChanged,
      ),
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xE611171F),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFC8FF3D)
              : Colors.white.withValues(alpha: 0.07),
          width: highlighted ? 1.8 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFC8FF3D),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }
}

class _ToggleIconButton extends StatelessWidget {
  const _ToggleIconButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon),
      color: selected ? const Color(0xFFC8FF3D) : Colors.white38,
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

String gainLabel(double value) {
  if (value.abs() < 0.05) return '0.0';
  return '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}';
}

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}
