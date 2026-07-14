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

## Unreleased

- Home: category tabs (`New`, `Trend`, `Podcasts`, `Favourites`) now render content exclusive to that tab. The `Playlist` section (Added links + Recent tracks) and the user-playlist/recently-played fallback in the top-hits chart are hidden on category tabs, so no cross-contamination of datasets.
- Header: `Browse` title now has a right-aligned `Downloaded` pill (green down-arrow icon) that opens a bottom sheet listing downloaded tracks and lets you tap-to-play.
- Home: "New" feed results are now sorted by a ranking function (`PlaylistProvider.rankHomeFeedTracks`) that puts official tracks, music videos, lyric videos, and trusted authors (VEVO / Records / Official) above DJ mixes, megamixes, nonstop sets, mixtapes, and other long-form content. The original YouTube relevance order is used as a stable tie-breaker among tracks that score equally. Podcasts feed is unchanged.
- Home: chart shelves (Apple Music Ghana Hot 100 + Hot Albums) are now conditionally rendered. They are visible on initial app load and immediately hidden as soon as the user selects a tab or category. The hide is one-way — re-launching the app brings the shelves back.
- Player: removed the 3 s auto-hide timer for transport controls. Play / pause / skip / seekbar / lyrics / quick actions now stay persistently visible during playback. Tapping outside the controls still toggles visibility (manual dismiss / ambient mode).
- Home: Browse view gains a new **Playlist** section that aggregates user-added links (imported playlists and albums) and recently played tracks in two horizontal shelves. Saved playlists show the existing "Added" badge.
- Home: category tabs reordered — `Added, New, Trend, Podcasts, Favourites` (was `Recent, New, Trend, Podcasts, Favourites`). The "Added" tab shows the imported playlists from the link dialog.
- Player: tapping or dragging the seek bar on a loaded song now actually seeks (`onSeek` is wired back to `PlayerProvider.seekTo` after the auto-hide refactor accidentally overrode it).
- Link parser: `youtube_url_processor ^0.1.4` is now wired as a second-stage fallback so nocookie embeds, channel variants, and other shapes the primary regex set cannot match are still classified.
- YouTube link parser: recognises `youtube.com/live/<id>` URLs as `YoutubeLinkType.live` and routes them through the same video handler in the home link dialog.
- Rebrand: app display name is now `YTMusix Canary` everywhere. `AppConstants.appName`, `MaterialApp.title`, the playlist export header, the Android notification channel (`ytmusix_canary_music` / `YTMusix Canary Playback`), and the README title all use the canary name. Android `applicationId` / `namespace` / `android:label` are already `YTMusix Canary` (`com.ytmusix.ytmusix.canary`).
- Brand asset: `tool/icon.png` is now bundled as `assets/brand/icon.png` and rendered in-app via the new `BrandLogo` widget (used in the home AppBar, the home empty state, and the About screen hero). The hand-drawn `pixel_logo.dart` is removed.
- YouTube link parser: recognises `youtube.com/live/<videoId>` URLs as `YoutubeLinkType.live` and routes them through the same video handler in the home link dialog.
- Search: `searchAll` falls back to the standard `search()` (youtube_explode_dart) so the songs tab in the search screen actually returns results when the YouTube Music API is unavailable.
- Home: added two horizontal chart shelves — **Apple Music Ghana Hot 100** (songs) and **Apple Music Ghana Hot Albums** — driven by `ChartProvider`. Cards show rank badge, artwork, title, artist; tap uses `PlaylistProvider.searchSilently` (7-day cache) to find the YouTube track and play it.
- Player: real autoplay-after-queue instead of stopping. `PlayerProvider._fetchAutoplayRecommendations` now queries `AudioRepository.getRecommendations(seed, limit: 15)`, de-duplicates against the current queue, appends the new tracks, syncs the handler, and starts playback on the first new item. Falls back to the previous `stop()` behavior if recommendations are empty or fail.
- Player: auto-hide transport controls. The transport row, lyrics, and quick actions fade out after 3 s of inactivity and reappear on tap. The artwork, title/artist, and seek bar stay visible. A `Timer` cancels on `dispose`.
- Track sheet: new "Copy YouTube link" action copies `https://www.youtube.com/watch?v={id}` to the clipboard so the user can open the video in a browser while audio plays in-app (lightweight A/V switcher).
- Removed iOS and macOS host projects; the app is Android-only.
- Removed iOS configuration from `flutter_launcher_icons` and `flutter_native_splash`.
- Cleaned iOS references and the iOS Simulator build section from the README.
- Rebrand: Android package/namespace/label updated to `YTMusix Canary` (`com.ytmusix.ytmusix.canary`).
- New app icon: replaced the green play-triangle logo with a redesigned bird/mascot mark in `tool/icon.png`. Regenerated all Android launcher icons (`mipmap-*`) and native splash screens via `flutter_launcher_icons` and `flutter_native_splash`.
- Added `PlaylistProvider.searchSilently` with a normalized in-memory cache and 7-day SharedPreferences persistence (`silent_search_cache_v1`), so repeated silent searches reuse results without hitting the network.
- Added `Track.toJson` / `Track.fromJson` and a `single` getter on `CategorizedSearchResults` to support cached silent-search deserialization.
- Promoted `AudioRepository.getVideoUrl` and `AudioRepository.getRecommendations` to the domain interface (impls already existed).
- Cleaned up `PlayerProvider`: removed unused `DownloadProvider` / `SettingsProvider` constructor parameters, dropped their imports, and marked `_isAutoplaying` as `final`.
- Static analysis: `flutter analyze` reports no issues.
- Tests: 11/11 passing (`chart_service`, `player_provider`, `playlist_provider`).

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
