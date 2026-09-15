import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../studio/studio_controller.dart';
import 'youtube_link.dart';

class YoutubePage extends StatefulWidget {
  const YoutubePage({super.key});

  @override
  State<YoutubePage> createState() => _YoutubePageState();
}

class _YoutubePageState extends State<YoutubePage> {
  final TextEditingController _linkController = TextEditingController();
  final List<YoutubeLink> _recentLinks = <YoutubeLink>[];

  YoutubePlayerController? _playerController;
  YoutubeLink? _activeLink;
  String? _errorMessage;
  bool _initialized = false;
  bool _openingBrowser = false;

  bool get _platformSupportsInlinePlayer =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final runtimeEnabled = context.read<StudioController>().audioEnabled;
    if (_platformSupportsInlinePlayer && runtimeEnabled) {
      _playerController = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          playsInline: true,
          privacyEnhancedMode: true,
          interfaceLanguage: 'th',
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkController.dispose();
    unawaited(_playerController?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 920;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 18, 8, wide ? 32 : 18, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BrowserLoginCard(
                opening: _openingBrowser,
                onOpenYoutube: () => _openExternal(
                  Uri.parse('https://www.youtube.com/feed/you'),
                ),
                onOpenMusic: () =>
                    _openExternal(Uri.parse('https://music.youtube.com/')),
              ),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildPlayerPanel()),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: _buildImportPanel()),
                  ],
                )
              else ...[
                _buildImportPanel(),
                const SizedBox(height: 16),
                _buildPlayerPanel(),
              ],
              if (_recentLinks.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildRecentPanel(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildImportPanel() {
    return _YoutubePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PanelHeading(
            icon: Icons.link_rounded,
            title: 'Paste a YouTube link',
            subtitle: 'Videos, Shorts, Live, YouTube Music, or youtu.be',
          ),
          const SizedBox(height: 18),
          TextField(
            key: const Key('youtube-link-field'),
            controller: _linkController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.go,
            autocorrect: false,
            onSubmitted: _loadLink,
            decoration: InputDecoration(
              hintText: 'https://youtu.be/…',
              prefixIcon: const Icon(Icons.ondemand_video_rounded),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              errorText: _errorMessage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('youtube-load-button'),
                  onPressed: () => _loadLink(_linkController.text),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Load video'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.content_paste_go_rounded),
                  label: const Text('Paste link'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _PrivacyNotice(),
        ],
      ),
    );
  }

  Widget _buildPlayerPanel() {
    final activeLink = _activeLink;
    final player = _playerController;
    return _YoutubePanel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (activeLink != null && player != null)
              YoutubePlayer(controller: player, aspectRatio: 16 / 9)
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _PlayerPlaceholder(
                  hasLink: activeLink != null,
                  inlineSupported: _platformSupportsInlinePlayer,
                  onOpen: activeLink == null
                      ? null
                      : () => _openExternal(Uri.parse(activeLink.canonicalUrl)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF0033),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeLink == null
                              ? 'YouTube player ready'
                              : 'Video ${activeLink.videoId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeLink?.canonicalUrl ??
                              'Paste a link to load a song or video.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activeLink != null)
                    IconButton.filledTonal(
                      tooltip: 'Open on YouTube',
                      onPressed: () =>
                          _openExternal(Uri.parse(activeLink.canonicalUrl)),
                      icon: const Icon(Icons.open_in_new_rounded),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPanel() {
    return _YoutubePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeading(
            icon: Icons.history_rounded,
            title: 'Recent links',
            subtitle: 'Kept only for this app session',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final link in _recentLinks)
                ActionChip(
                  avatar: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFFFF335B),
                    size: 18,
                  ),
                  label: Text(link.videoId),
                  onPressed: () {
                    _linkController.text = link.canonicalUrl;
                    _loadLink(link.canonicalUrl);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim() ?? '';
    if (!mounted) return;
    _linkController.text = value;
    _loadLink(value);
  }

  void _loadLink(String rawValue) {
    final link = YoutubeLink.tryParse(rawValue);
    if (link == null) {
      setState(() {
        _errorMessage = 'Enter a valid YouTube video link or 11-character ID.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _activeLink = link;
      _recentLinks.removeWhere((item) => item.videoId == link.videoId);
      _recentLinks.insert(0, link);
      if (_recentLinks.length > 8) _recentLinks.removeLast();
    });
    _linkController.text = link.canonicalUrl;
    unawaited(_playerController?.loadVideoById(videoId: link.videoId));
  }

  Future<void> _openExternal(Uri uri) async {
    if (_openingBrowser) return;
    setState(() => _openingBrowser = true);
    try {
      final opened = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && mounted) {
        setState(() => _errorMessage = 'Could not open the browser.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not open the browser.');
      }
    } finally {
      if (mounted) setState(() => _openingBrowser = false);
    }
  }
}

class _BrowserLoginCard extends StatelessWidget {
  const _BrowserLoginCard({
    required this.opening,
    required this.onOpenYoutube,
    required this.onOpenMusic,
  });

  final bool opening;
  final VoidCallback onOpenYoutube;
  final VoidCallback onOpenMusic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1018), Color(0xFF151923)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x44FF335B)),
      ),
      child: Wrap(
        runSpacing: 16,
        spacing: 20,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFF0033),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [
                BoxShadow(color: Color(0x55FF0033), blurRadius: 22),
              ],
            ),
            child: const Icon(
              Icons.smart_display_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Browse with your Google account',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  'YouTube opens in your trusted browser for Google sign-in. '
                  'Copy any song or video link, return here, then tap Paste link.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: opening ? null : onOpenMusic,
            icon: const Icon(Icons.music_note_rounded),
            label: const Text('YouTube Music'),
          ),
          FilledButton.icon(
            onPressed: opening ? null : onOpenYoutube,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF0033),
              foregroundColor: Colors.white,
            ),
            icon: opening
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded),
            label: const Text('Open YouTube / Google login'),
          ),
        ],
      ),
    );
  }
}

class _PlayerPlaceholder extends StatelessWidget {
  const _PlayerPlaceholder({
    required this.hasLink,
    required this.inlineSupported,
    required this.onOpen,
  });

  final bool hasLink;
  final bool inlineSupported;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF080B10),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasLink ? Icons.open_in_browser_rounded : Icons.link_rounded,
                color: const Color(0xFFFF335B),
                size: 44,
              ),
              const SizedBox(height: 14),
              Text(
                !hasLink
                    ? 'Paste a YouTube link to start'
                    : inlineSupported
                    ? 'Player preview is disabled in test mode'
                    : 'Inline YouTube is not available on this platform',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (hasLink && onOpen != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open in YouTube'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF111923),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF5FE7FF),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Equalizer Pro never asks for or stores your Google password. '
              'YouTube playback stays inside YouTube’s official player, so local '
              'SoLoud EQ/DSP is not applied to protected YouTube streams.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeading extends StatelessWidget {
  const _PanelHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: const Color(0x22C8FF3D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFC8FF3D), size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _YoutubePanel extends StatelessWidget {
  const _YoutubePanel({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xE611161E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}
