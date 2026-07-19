import 'package:equalizer_pro/main.dart';
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
  });
}
