# Changelog

## Unreleased

- Removed iOS and macOS host projects; the app is Android-only.
- Removed iOS configuration from `flutter_launcher_icons` and `flutter_native_splash`.
- Cleaned iOS references and the iOS Simulator build section from the README.

## 1.4.3

- Added YouTube link parser with switch-based URL type detection for videos, playlists, shorts, and music links.
- Single video and shorts links now play audio immediately instead of opening a playlist view.
- Added channel link detection with clear unsupported feedback.
- Fixed DatabaseException on fresh installs where the `tracks` table was missing the `albumId` and `artistId` columns (DB version bumped to 8 with idempotent migration).

## 1.4.2

- Fixed bottom layout overflow on the Now Playing FAB widget.
- Corrected repeat and shuffle control integration on the Now Playing screen.
- Resolved seekbar duration filling issues.

## 1.4.1

- Fixed background audio playback and track auto-play progression on Android.
- Introduced a toggleable 7-second crossfade feature on the Now Playing screen.

## 1.4.0

- Added favorite collection support (playlists and albums).
- Fully rebuilt iOS background playback auto-advance and dynamic island integration.
- Resolved layout overflow bugs and optimized the Now Playing FAB with dynamic sizing.

## 1.3.0

- Added floating player controls with play/pause and progress seekbar border to FAB.
- Removed mini-player layout.
- Optimized audio quality settings defaults.
- Added geo-restrictions bypass.
- Resolved playlist duration mapping.
- Fixed search playlist navigation and adjusted artist page layouts.

## 1.2.0

- Added Apple Music chart shelves with scoped Top 100 songs, album detail playback, recommendation autoplay, cached chart/search lookups, a custom video player, and refreshed About details.

## 1.1.0

- Improved playlist browsing, downloads, favourites, queue tools, and playback controls.

## 1.0.0

- Initial Android release for streaming public YouTube playlists, videos, and mixes.
