# Changelog

## Unreleased

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
