# Changelog

## 1.5.2

- In-app updates: the About screen now checks GitHub for a newer release and can download the APK and launch the system installer directly (full in-app update; the APK is shared via a `FileProvider` and installed with `REQUEST_INSTALL_PACKAGES`). A startup prompt offers the same when a new version is available, remembered per version so it is not shown again once dismissed.
- Offline screen: downloaded tracks without artwork now use the app icon (`assets/brand/icon.png`) as their thumbnail instead of a generic music-note placeholder.
- Home: the "Recent plays" section on the home tab now populates from your recently played tracks (it was previously left empty).
- About: the in-app changelog now shows up to 5 recent entries (was 3).

## 1.5.0

- Auto-download: every track you play is now saved in the background for offline listening, at the same audio quality you are playing it. Live streams are detected (`Track.isLive`) and never auto-downloaded.
- Auto-download: when a playlist starts playing, the whole playlist is downloaded in the background so it becomes available offline.
- Renamed the downloaded-music section from "Downloaded" to **Offline**, and the download action subtitle from "Cache this track" / "Cache for offline playback" to **"Download offline"**.
- Added an audio/video switch on the player screen: toggle to watch the music video (full video surface via `video_player`) with seamless position handoff between audio and video; the video auto-pauses background audio.
- Sound quality: default playback/download quality is now **High**, and the player screen adds an in-player audio quality selector plus a quality badge.
- Added a **YouTube Music Top 100 Ghana** chart shelf on the home Browse screen (YouTube-search sourced), alongside the existing Apple Music Ghana shelves.
- Changelog: the in-app About screen now shows only the 3 most recent updates.

## 1.5.1

- Adopted the Offline (Downloads) screen and download method from ytmusix-flowos: a full-screen Offline view with a play/shuffle header, favourites, per-track delete and clear-all. A reusable `TrackTile` widget was added to support it.
- Adopted flowos' Settings page, including a new **Auto DJ** screen: choose how the queue continues when it ends (Off, Library Shuffle, Similar Songs, Same Artist, Same Genre, Smart Mix) with a configurable continuation count and top-up threshold. Auto DJ is now wired into playback (`PlayerProvider.next` / `playTrack`) so the queue extends automatically near the end (or at the end when not on repeat). Default mode is Off, so playback stops at the end of the queue by default — pick "Similar Songs" to restore continuous autoplay.
- Fixed a bug where the device back gesture at the root stopped playback: the root route is now wrapped in `PopScope(canPop: false)` that sends the app to the background (`SystemNavigator.pop`) instead of finishing the activity, keeping the headless audio service alive.
- Storage: "Clear all cached downloads" now removes every downloaded track (including individually downloaded tracks) via `DownloadProvider.deleteAllDownloadedTracks`, not just playlist-associated ones.
- Static analysis: `flutter analyze` reports no issues.

## 1.5.3

- Fix: downloaded songs no longer fail with a "source error" — playback now loads the locally downloaded file directly (`PlayerProvider.playTrack` prefers `DownloadProvider.getLocalFilePath`) before falling back to a freshly resolved stream URL, so offline tracks play reliably.
- Fix: the Now Playing screen now fits small viewports — the layout uses a `LayoutBuilder` with a `ConstrainedBox(minHeight)` and `spaceBetween` so controls never overflow; it still scrolls when content is taller than the screen.
- Theme: adopted the flowos color scheme with a pure-black background (`0xFF000000`); surfaces and cards use `0xFF121212` / `0xFF181818`. Primary stays Spotify-green `0xFF1DB954`.
- Home redesign: decluttered the Browse screen into Apple Music Top 100, YouTube Ghana Top 100, **Suggested for you** (top picks from the New feed, shown before Recent), **Recent plays**, and **Your Library** (added links). Category tabs are now `New`, `Trending`, `Podcast`, `Favorites`.

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
