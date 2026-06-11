import 'package:hive_flutter/hive_flutter.dart';

/// A service that handles local caching using Hive.
/// Implements a cache-first strategy with configurable TTL.
class CacheService {
  static const String _matchesCacheBox = 'matches_cache';
  static const String _newsCacheBox = 'news_cache';
  static const String _standingsCacheBox = 'standings_cache';
  static const String _metaCacheBox = 'cache_meta';

  // Default TTL: 15 minutes for live data
  static const Duration defaultTTL = Duration(minutes: 15);
  static const Duration longTTL = Duration(hours: 6);

  /// Initialize all Hive boxes
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_matchesCacheBox);
    await Hive.openBox(_newsCacheBox);
    await Hive.openBox(_standingsCacheBox);
    await Hive.openBox(_metaCacheBox);
  }

  // ─── Matches Cache ──────────────────────────────

  static Future<void> cacheMatches(String date, List<dynamic> data) async {
    final box = Hive.box(_matchesCacheBox);
    await box.put(date, data);
    await _setTimestamp('matches_$date');
  }

  static List<dynamic>? getCachedMatches(String date) {
    final box = Hive.box(_matchesCacheBox);
    if (!_isValid('matches_$date', defaultTTL)) return null;
    final data = box.get(date);
    return data != null ? List<dynamic>.from(data) : null;
  }

  // ─── News Cache ─────────────────────────────────

  static Future<void> cacheArticles(List<dynamic> data) async {
    final box = Hive.box(_newsCacheBox);
    await box.put('articles', data);
    await _setTimestamp('news_articles');
  }

  static List<dynamic>? getCachedArticles() {
    final box = Hive.box(_newsCacheBox);
    if (!_isValid('news_articles', longTTL)) return null;
    final data = box.get('articles');
    return data != null ? List<dynamic>.from(data) : null;
  }

  // ─── Standings Cache ────────────────────────────

  static Future<void> cacheStandings(String key, List<dynamic> data) async {
    final box = Hive.box(_standingsCacheBox);
    await box.put(key, data);
    await _setTimestamp('standings_$key');
  }

  static List<dynamic>? getCachedStandings(String key) {
    final box = Hive.box(_standingsCacheBox);
    if (!_isValid('standings_$key', longTTL)) return null;
    final data = box.get(key);
    return data != null ? List<dynamic>.from(data) : null;
  }

  // ─── Generic Cache ──────────────────────────────

  static Future<void> cacheData(String boxName, String key, dynamic data) async {
    final box = Hive.box(boxName);
    await box.put(key, data);
    await _setTimestamp('${boxName}_$key');
  }

  static dynamic getCachedData(String boxName, String key, {Duration? ttl}) {
    final box = Hive.box(boxName);
    if (!_isValid('${boxName}_$key', ttl ?? defaultTTL)) return null;
    return box.get(key);
  }

  // ─── TTL Management ─────────────────────────────

  static Future<void> _setTimestamp(String key) async {
    final box = Hive.box(_metaCacheBox);
    await box.put(key, DateTime.now().millisecondsSinceEpoch);
  }

  static bool _isValid(String key, Duration ttl) {
    final box = Hive.box(_metaCacheBox);
    final timestamp = box.get(key);
    if (timestamp == null) return false;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedAt) < ttl;
  }

  /// Clear all cached data
  static Future<void> clearAll() async {
    await Hive.box(_matchesCacheBox).clear();
    await Hive.box(_newsCacheBox).clear();
    await Hive.box(_standingsCacheBox).clear();
    await Hive.box(_metaCacheBox).clear();
  }

  /// Clear specific box
  static Future<void> clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
    }
  }
}
