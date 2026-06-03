import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

import '../../domain/entities/chart_item.dart';
import '../../service/chart_service.dart';

class ChartProvider extends ChangeNotifier {
  ChartProvider(this._chartService);

  final ChartService _chartService;

  List<ChartItem> _recommendedSongs = [];
  List<ChartItem> _hotAlbums = [];
  List<ChartItem> _billboard200 = [];
  final Set<String> _loadingKeys = {};
  String? _error;

  List<ChartItem> get recommendedSongs => _recommendedSongs;
  List<ChartItem> get hotAlbums => _hotAlbums;
  List<ChartItem> get billboard200 => _billboard200;
  String? get error => _error;

  bool isLoading(String key) => _loadingKeys.contains(key);

  Future<void> loadCharts({bool force = false}) async {
    await Future.wait([
      loadRecommendedSongs(force: force),
      loadHotAlbums(force: force),
      loadBillboard200(force: force),
    ]);
  }

  Future<void> loadRecommendedSongs({bool force = false}) {
    return _load(
      ChartService.recommendedSongsKey,
      () => _chartService.getRecommendedSongs(force: force),
      (items) => _recommendedSongs = items,
    );
  }

  Future<void> loadHotAlbums({bool force = false}) {
    return _load(
      ChartService.hotAlbumsKey,
      () => _chartService.getHotAlbums(force: force),
      (items) => _hotAlbums = items,
    );
  }

  Future<void> loadBillboard200({bool force = false}) {
    return _load(
      ChartService.billboardAlbumsKey,
      () => _chartService.getBillboard200(force: force),
      (items) => _billboard200 = items,
    );
  }

  Future<List<ChartItem>> getAlbumSongs(ChartItem album) {
    return _chartService.getAppleAlbumSongs(album);
  }

  Future<void> _load(
    String key,
    Future<List<ChartItem>> Function() fetch,
    void Function(List<ChartItem>) apply,
  ) async {
    if (_loadingKeys.contains(key)) return;

    _loadingKeys.add(key);
    _error = null;
    notifyListeners();

    try {
      apply(await fetch());
    } catch (e) {
      _error = e.toString();
      dev.log('Failed to load chart $key: $e', name: 'ChartProvider');
    } finally {
      _loadingKeys.remove(key);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
