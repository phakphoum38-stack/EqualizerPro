class YoutubeLink {
  const YoutubeLink({required this.videoId, required this.originalValue});

  final String videoId;
  final String originalValue;

  String get canonicalUrl => 'https://www.youtube.com/watch?v=$videoId';

  static final RegExp _videoIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

  static YoutubeLink? tryParse(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    if (_videoIdPattern.hasMatch(value)) {
      return YoutubeLink(videoId: value, originalValue: value);
    }

    final normalized = value.contains('://') ? value : 'https://$value';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return null;

    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    String? candidate;

    if (host == 'youtu.be') {
      candidate = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    } else if (host == 'youtube.com' ||
        host == 'm.youtube.com' ||
        host == 'music.youtube.com' ||
        host == 'youtube-nocookie.com') {
      candidate = uri.queryParameters['v'];
      if (candidate == null && uri.pathSegments.length >= 2) {
        final section = uri.pathSegments.first.toLowerCase();
        if (section == 'shorts' ||
            section == 'embed' ||
            section == 'live' ||
            section == 'v') {
          candidate = uri.pathSegments[1];
        }
      }
    }

    if (candidate == null || !_videoIdPattern.hasMatch(candidate)) {
      return null;
    }
    return YoutubeLink(videoId: candidate, originalValue: value);
  }
}
