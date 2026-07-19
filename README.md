# Equalizer Pro

Equalizer Pro is a responsive Flutter audio workspace for web, mobile, and desktop. It combines local playback with a real-time cross-platform DSP pipeline, sound profiles, a live waveform, and a session library.

## What you can do

- Drag and drop MP3, WAV, OGG, or FLAC files into the player or Library.
- Pick one or multiple audio files with the system file picker.
- Play, pause, seek, skip, shuffle, and repeat tracks during the session.
- Process playback through a live 10-band parametric EQ and reorder its controls with their grip handles.
- Apply six built-in sound profiles or save a custom profile for the current session.
- Process audio with bass boost, spatial reverb, stereo width, output gain, dynamic normalization, warm saturation, and a safety limiter.
- Use the Studio, Presets, and Library tabs in desktop or mobile layouts.
- Keep EQ and effect settings saved locally between launches.

Imported audio stays on the device and is not uploaded. The session library is cleared when the app closes.

## Run locally

```powershell
flutter pub get
flutter run -d chrome
```

For the Windows desktop build:

```powershell
flutter run -d windows
```

## Validate and build

```powershell
flutter analyze
flutter test
flutter build web --release
flutter build windows --release
```

The release web bundle is written to `build/web/`. The native DSP engine supports iOS, Android, Windows, macOS, and Linux from the same controller.

## Build the unsigned iOS IPA

The `Build unsigned iOS IPA` GitHub Actions workflow validates the project on macOS, builds the release app without code signing, packages `Payload/Runner.app` into an IPA, calculates SHA-256, and uploads both files as a workflow artifact.

Run it from GitHub Actions with the default version inputs, or use:

```powershell
gh workflow run build-ios.yml -f build_name=1.1.0 -f build_number=2
```

## Implementation notes

The app uses `flutter_soloud` for low-latency playback, its 10-band parametric EQ and global DSP filters, and `audio_session` for mobile audio focus. It uses `desktop_drop` for drag-and-drop input, `file_picker` for browsing, `provider` for state, and `shared_preferences` for local settings. The live waveform comes from the audio engine's playback samples. No remote service is required and audio never leaves the device.
