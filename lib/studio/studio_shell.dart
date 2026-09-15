import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'studio_controller.dart';
import 'studio_pages.dart';
import 'studio_painters.dart';
import '../youtube/youtube_page.dart';

class StudioShell extends StatefulWidget {
  const StudioShell({super.key});

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  String? _displayedMessage;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    _showPendingMessage(controller);
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 980;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: AmbientBackgroundPainter()),
          ),
          SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (desktop) const _DesktopNavigation(),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(compact: !desktop),
                      Expanded(
                        child: IndexedStack(
                          index: controller.selectedTab,
                          children: const [
                            StudioPage(),
                            PresetsPage(),
                            LibraryPage(),
                            YoutubePage(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: desktop ? null : const _MobileNavigation(),
    );
  }

  void _showPendingMessage(StudioController controller) {
    if (controller.message == null || controller.message == _displayedMessage) {
      return;
    }
    _displayedMessage = controller.message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || controller.message == null) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: controller.messageIsError
              ? const Color(0xFF3C2025)
              : const Color(0xFF1B2520),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 84),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(
                controller.messageIsError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: controller.messageIsError
                    ? const Color(0xFFFF8B8B)
                    : const Color(0xFFC8FF3D),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(controller.message!)),
            ],
          ),
        ),
      );
      controller.clearMessage();
      _displayedMessage = null;
    });
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return Container(
      width: 94,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      decoration: BoxDecoration(
        color: const Color(0xE611161E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          const _BrandMark(compact: true),
          const SizedBox(height: 34),
          for (var i = 0; i < _destinations.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              child: _NavigationTile(
                destination: _destinations[i],
                selected: controller.selectedTab == i,
                onTap: () => controller.selectTab(i),
              ),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Settings are saved automatically',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _AboutDialog(),
            ),
            icon: const Icon(Icons.settings_outlined, size: 21),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    final titles = [
      'Sound studio',
      'Sound profiles',
      'Your library',
      'YouTube connect',
    ];
    final subtitles = [
      'Shape every detail of your sound.',
      'Start with a curve, then make it yours.',
      '${controller.tracks.length} tracks in this session.',
      'Open YouTube, copy a link, and play it here.',
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 18 : 32,
        18,
        compact ? 18 : 32,
        12,
      ),
      child: Row(
        children: [
          if (compact) ...[
            const _BrandMark(compact: true),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[controller.selectedTab],
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitles[controller.selectedTab],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            _EngineStatus(
              active: controller.equalizerEnabled,
              ready: controller.isEngineReady,
            ),
            const SizedBox(width: 10),
          ],
          IconButton.filledTonal(
            tooltip: 'Import audio',
            onPressed: controller.pickAudioFiles,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF202832),
            child: Text(
              'EQ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudioController>();
    return NavigationBar(
      height: 68,
      backgroundColor: const Color(0xF20D1219),
      indicatorColor: const Color(0x22C8FF3D),
      selectedIndex: controller.selectedTab,
      onDestinationSelected: controller.selectTab,
      destinations: [
        for (final destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          ),
      ],
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: destination.label,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 62,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFC8FF3D) : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: selected ? const Color(0xFF11170B) : Colors.white54,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                style: TextStyle(
                  color: selected ? const Color(0xFF11170B) : Colors.white54,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 46 : 150,
      height: 46,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFC8FF3D),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Color(0x33C8FF3D), blurRadius: 22, spreadRadius: 1),
        ],
      ),
      child: const CustomPaint(
        painter: SpectrumLogoPainter(color: Color(0xFF10150B)),
      ),
    );
  }
}

class _EngineStatus extends StatelessWidget {
  const _EngineStatus({required this.active, required this.ready});

  final bool active;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: ready && active
                  ? const Color(0xFFC8FF3D)
                  : ready
                  ? const Color(0xFFFFD86B)
                  : Colors.white30,
              shape: BoxShape.circle,
              boxShadow: ready && active
                  ? const [BoxShadow(color: Color(0x88C8FF3D), blurRadius: 8)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            !ready
                ? 'DSP STARTING'
                : active
                ? 'DSP LIVE'
                : 'EQ BYPASSED',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AboutDialog extends StatelessWidget {
  const _AboutDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF151B24),
      icon: const Icon(Icons.graphic_eq_rounded, color: Color(0xFFC8FF3D)),
      title: const Text('Equalizer Pro'),
      content: const Text(
        'Your equalizer and effect settings are saved automatically on this device. '
        'Imported tracks stay local and are cleared when the app closes.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Destination('Studio', Icons.tune_outlined, Icons.tune_rounded),
  _Destination(
    'Presets',
    Icons.auto_awesome_outlined,
    Icons.auto_awesome_rounded,
  ),
  _Destination(
    'Library',
    Icons.library_music_outlined,
    Icons.library_music_rounded,
  ),
  _Destination(
    'YouTube',
    Icons.smart_display_outlined,
    Icons.smart_display_rounded,
  ),
];
