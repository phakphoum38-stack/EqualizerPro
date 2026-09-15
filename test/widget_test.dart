import 'package:equalizer_pro/main.dart';
import 'package:equalizer_pro/youtube/youtube_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the complete sound studio', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EqualizerPro(audioEnabled: false));
    await tester.pumpAndSettle();

    expect(find.text('Sound studio'), findsOneWidget);
    expect(find.text('10-band equalizer'), findsOneWidget);
    expect(find.text('Bass boost'), findsOneWidget);
    expect(find.text('Drop a track to begin'), findsOneWidget);
  });

  testWidgets('navigates between tabs and applies a preset', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EqualizerPro(audioEnabled: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Presets'));
    await tester.pumpAndSettle();
    expect(find.text('Sound profiles'), findsOneWidget);
    expect(find.text('Deep Bass'), findsOneWidget);

    await tester.tap(find.text('Deep Bass'));
    await tester.pumpAndSettle();
    expect(find.text('ACTIVE'), findsWidgets);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library'), findsOneWidget);
    expect(find.text('Your session is ready for music'), findsOneWidget);

    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube connect'), findsOneWidget);
    expect(find.text('Paste a YouTube link'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('youtube-link-field')),
      'https://youtu.be/M7lc1UVf-VE',
    );
    await tester.tap(find.byKey(const Key('youtube-load-button')));
    await tester.pumpAndSettle();
    expect(find.text('Video M7lc1UVf-VE'), findsOneWidget);
  });

  testWidgets('adapts navigation and content to a mobile viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const EqualizerPro(audioEnabled: false));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Sound studio'), findsOneWidget);

    await tester.tap(find.text('Presets'));
    await tester.pumpAndSettle();
    expect(find.text('Sound profiles'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your library'), findsOneWidget);

    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube connect'), findsOneWidget);
    expect(find.text('Open YouTube / Google login'), findsOneWidget);
  });

  test('parses common YouTube song and video links', () {
    final values = <String, String>{
      'https://www.youtube.com/watch?v=M7lc1UVf-VE': 'M7lc1UVf-VE',
      'https://music.youtube.com/watch?v=M7lc1UVf-VE&list=RDAMVM':
          'M7lc1UVf-VE',
      'https://youtu.be/M7lc1UVf-VE?t=5': 'M7lc1UVf-VE',
      'https://youtube.com/shorts/M7lc1UVf-VE': 'M7lc1UVf-VE',
      'youtube.com/live/M7lc1UVf-VE': 'M7lc1UVf-VE',
      'M7lc1UVf-VE': 'M7lc1UVf-VE',
    };

    for (final entry in values.entries) {
      expect(YoutubeLink.tryParse(entry.key)?.videoId, entry.value);
    }
    expect(YoutubeLink.tryParse('https://example.com/not-youtube'), isNull);
    expect(YoutubeLink.tryParse('not a video'), isNull);
  });
}
