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
- Open YouTube or YouTube Music in the trusted system browser, sign in with Google, then paste a video, Short, Live, or Music link into the YouTube tab.
- Play supported YouTube links inline on Android, iOS, macOS, and web, with an external-browser fallback on Windows and Linux.
- Keep EQ and effect settings saved locally between launches.

Imported audio stays on the device and is not uploaded. The session library is cleared when the app closes.

## YouTube and Google sign-in

Open the **YouTube** tab and choose **Open YouTube / Google login**. Google authentication takes place in the trusted system browser; Equalizer Pro never asks for or stores a Google password. Copy a song or video URL, return to Equalizer Pro, and choose **Paste link** to load it.

The embedded player uses YouTube's official IFrame Player API. YouTube media remains inside YouTube's protected player, so the local SoLoud EQ and DSP chain only processes imported MP3, WAV, OGG, and FLAC files. Reading private playlists directly inside the app would additionally require a project-specific Google OAuth client and YouTube Data API consent configuration.

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

## Build every platform on GitHub

The `Build all platforms` GitHub Actions workflow validates formatting, analysis, and tests first. It then builds Android APK/AAB, an unsigned iOS IPA, Web, Windows, Linux, and macOS releases in parallel. Every platform is packaged with a SHA-256 checksum and uploaded as a workflow artifact for 30 days.

Run it from GitHub Actions with the default version inputs, or use:

```powershell
gh workflow run build-ios.yml -f build_name=1.2.0 -f build_number=3
```

| Artifact | Contents |
| --- | --- |
| `equalizer-pro-android-1.2.0-3` | APK, AAB, and `SHA256SUMS.txt` |
| `equalizer-pro-ios-1.2.0-3` | Unsigned IPA and SHA-256 |
| `equalizer-pro-web-1.2.0-3` | Deployable Web ZIP and SHA-256 |
| `equalizer-pro-windows-1.2.0-3` | Windows release ZIP and SHA-256 |
| `equalizer-pro-linux-1.2.0-3` | Linux release tarball and SHA-256 |
| `equalizer-pro-macos-1.2.0-3` | macOS app ZIP and SHA-256 |

## Implementation notes

The app uses `flutter_soloud` for low-latency playback, its 10-band parametric EQ and global DSP filters, and `audio_session` for mobile audio focus. It uses `desktop_drop` for drag-and-drop input, `file_picker` for browsing, `provider` for state, and `shared_preferences` for local settings. The live waveform comes from the audio engine's playback samples. No remote service is required and audio never leaves the device.
