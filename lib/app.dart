import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/audio_repository.dart';
import 'domain/repositories/playlist_repository.dart';
import 'presentation/providers/player_provider.dart';
import 'presentation/providers/playlist_provider.dart';
import 'presentation/providers/download_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/chart_provider.dart';
import 'service/audio_handler.dart';
import 'presentation/screens/home_screen.dart';

class YTMusixApp extends StatelessWidget {
  final PlaylistRepository playlistRepository;
  final AudioRepository audioRepository;
  final DownloadProvider downloadProvider;
  final SettingsProvider settingsProvider;
  final MusicAudioHandler audioHandler;
  final ChartProvider chartProvider;

  const YTMusixApp({
    super.key,
    required this.playlistRepository,
    required this.audioRepository,
    required this.downloadProvider,
    required this.settingsProvider,
    required this.audioHandler,
    required this.chartProvider,
  });

  @override
  Widget build(BuildContext context) {
    final playlistProvider = PlaylistProvider(playlistRepository);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: playlistProvider),
        ChangeNotifierProvider(
          create: (_) => PlayerProvider(
            audioRepository,
            downloadProvider: downloadProvider,
            playlistProvider: playlistProvider,
            settingsProvider: settingsProvider,
          )..setAudioHandler(audioHandler),
        ),
        ChangeNotifierProvider.value(
          value: downloadProvider,
        ),
        ChangeNotifierProvider.value(
          value: chartProvider,
        ),
      ],
      child: MaterialApp(
        title: 'YTMusix Canary',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            // Keep background audio alive: at the root, send the app to the
            // background instead of finishing the activity (which would stop
            // the headless audio service via onTaskRemoved).
            if (!didPop) SystemNavigator.pop();
          },
          child: const HomeScreen(),
        ),
      ),
    );
  }
}
