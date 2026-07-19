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

## Supported platforms

| Platform | GitHub artifact | Package | Playback notes |
| --- | --- | --- | --- |
| Android | `equalizer-pro-android-<version>-<build>` | APK and AAB | Local DSP and inline YouTube player |
| iOS | `equalizer-pro-ios-<version>-<build>` | Unsigned IPA | Local DSP and inline YouTube player |
| Web | `equalizer-pro-web-<version>-<build>` | Static site ZIP | Browser audio and inline YouTube player |
| Windows | `equalizer-pro-windows-<version>-<build>` | Portable ZIP | Local DSP; YouTube opens in the browser |
| Linux | `equalizer-pro-linux-<version>-<build>` | Portable TAR.GZ | Local DSP; YouTube opens in the browser |
| macOS | `equalizer-pro-macos-<version>-<build>` | App ZIP | Local DSP and inline YouTube player |

The current automated build version is `1.2.0+3`. Keep all files from a desktop artifact together because the executable depends on the bundled Flutter, audio, and codec libraries.

## Download GitHub builds

1. Open [Build all platforms](https://github.com/phakphoum38-stack/EqualizerPro/actions/workflows/build-ios.yml).
2. Select a successful workflow run.
3. Scroll to **Artifacts** and download the package for your platform. GitHub may require you to sign in.
4. Extract the downloaded artifact ZIP. The platform package and its SHA-256 checksum are inside.

Artifacts are retained for 30 days. Verify a downloaded package before installing it:

```powershell
# Windows PowerShell
Get-FileHash .\equalizer-pro-windows-1.2.0-3.zip -Algorithm SHA256
```

```bash
# macOS or Linux
shasum -a 256 equalizer-pro-macos-1.2.0-3.zip
sha256sum equalizer-pro-linux-1.2.0-3.tar.gz
```

Compare the result with the included `.sha256` or `SHA256SUMS.txt` file.

## Android

The Android artifact contains an APK for direct testing and an AAB for store distribution.

To install the APK with Android Debug Bridge:

```bash
adb install -r equalizer-pro-1.2.0-3.apk
```

You can also copy the APK to an Android device, allow installation from the selected file-manager source, and open it. An AAB cannot be installed directly; upload it through Google Play Console or process it with `bundletool`.

Build Android locally:

```bash
flutter pub get
flutter build apk --release
flutter build appbundle --release
```

Outputs are written to `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/release/`. The current project uses debug signing for release-mode test packages. Configure a private production keystore and a unique application ID before publishing to Google Play.

## iOS

The iOS artifact contains an unsigned IPA. It cannot be installed directly on a standard iPhone or distributed through TestFlight until it is signed with an Apple certificate and provisioning profile.

Build the unsigned app on macOS with Xcode installed:

```bash
flutter pub get
flutter build ios --release --no-codesign
```

The `.app` is written to `build/ios/iphoneos/Runner.app`. The GitHub workflow packages this directory as `Payload/Runner.app` inside the IPA. For device or App Store distribution, open `ios/Runner.xcworkspace` in Xcode, set your development team and bundle identifier, then create a signed archive. The deployment target is iOS 13.0.

## Web

Extract the Web artifact and serve its contents through HTTP. Do not open `index.html` directly with a `file://` URL.

```bash
python -m http.server 8080 --directory path/to/extracted-web
```

Then open `http://localhost:8080`. The same static files can be deployed to GitHub Pages, Cloudflare Pages, Netlify, Firebase Hosting, or another static host. Use HTTPS in production so browser media and clipboard features work reliably.

Build Web locally:

```bash
flutter pub get
flutter build web --release --no-wasm-dry-run
```

The deployable site is written to `build/web/`.

## Windows

Extract the Windows ZIP completely and run `equalizer_pro.exe`. Do not move only the executable out of its folder; the `data` directory and bundled DLL files are required. Windows SmartScreen may warn because the package is not code-signed.

Build Windows locally from Windows with Visual Studio Desktop development with C++ installed:

```powershell
flutter pub get
flutter build windows --release
```

The portable application is written to `build\windows\x64\runner\Release\`.

## Linux

Install the GTK 3 and ALSA runtime libraries, extract the TAR.GZ, and launch the bundled executable:

```bash
sudo apt-get update
sudo apt-get install -y libasound2 libgtk-3-0
tar -xzf equalizer-pro-linux-1.2.0-3.tar.gz
chmod +x bundle/equalizer_pro
./bundle/equalizer_pro
```

Package names can vary between Linux distributions. Build locally on Debian or Ubuntu with:

```bash
sudo apt-get install -y clang cmake libasound2-dev libgtk-3-dev ninja-build pkg-config
flutter pub get
flutter build linux --release
```

The portable bundle is written to `build/linux/x64/release/bundle/`.

## macOS

Extract the macOS ZIP and move **Equalizer Pro.app** to `/Applications`. The package is not signed or notarized, so macOS may block its first launch. Open **System Settings > Privacy & Security** and choose **Open Anyway** only after verifying the checksum.

Build macOS locally with Xcode installed:

```bash
flutter config --enable-swift-package-manager
flutter pub get
flutter build macos --release
```

The app bundle is written under `build/macos/Build/Products/Release/`. Configure Developer ID signing and notarization before public distribution. The deployment target is macOS 10.15.

## Run from source

Install Flutter `3.44.4` or a compatible stable release, then check the environment and project:

```bash
flutter doctor -v
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

Run on a connected or enabled target with `flutter run -d <device>`, for example `chrome`, `windows`, `linux`, `macos`, an Android device ID, or an iOS device ID.

## Build every platform on GitHub

The `Build all platforms` GitHub Actions workflow validates formatting, analysis, and tests first. It then builds all six platform releases in parallel, calculates SHA-256 checksums, and uploads the packages as workflow artifacts.

Run it from GitHub Actions with the default version inputs, or use:

```powershell
gh workflow run build-ios.yml -f build_name=1.2.0 -f build_number=3
```

## Implementation notes

The app uses `flutter_soloud` for low-latency playback, its 10-band parametric EQ and global DSP filters, and `audio_session` for mobile audio focus. It uses `desktop_drop` for drag-and-drop input, `file_picker` for browsing, `provider` for state, and `shared_preferences` for local settings. The live waveform comes from the audio engine's playback samples. No remote service is required and audio never leaves the device.
