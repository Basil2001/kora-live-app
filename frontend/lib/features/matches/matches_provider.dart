import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/websocket_service.dart';
import '../auth/auth_provider.dart';

// Match details model mockup structure for UI components mapping
class MatchModel {
  final int id;
  final int homeTeamId;
  final String homeTeam;
  final String homeLogo;
  final int awayTeamId;
  final String awayTeam;
  final String awayLogo;
  final int scoreHome;
  final int scoreAway;
  final String status;
  final int currentMinute;
  final String startTime;
  final String competition;
  final List<dynamic> events;

  MatchModel({
    required this.id,
    required this.homeTeamId,
    required this.homeTeam,
    required this.homeLogo,
    required this.awayTeamId,
    required this.awayTeam,
    required this.awayLogo,
    required this.scoreHome,
    required this.scoreAway,
    required this.status,
    required this.currentMinute,
    required this.startTime,
    required this.competition,
    this.events = const [],
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? 0,
      homeTeamId: json['home_team_id'] ?? json['home_team']?['id'] ?? 0,
      homeTeam: json['home_team']?['name'] ?? json['home_team_name'] ?? 'Home',
      homeLogo: json['home_team']?['logo_url'] ?? '',
      awayTeamId: json['away_team_id'] ?? json['away_team']?['id'] ?? 0,
      awayTeam: json['away_team']?['name'] ?? json['away_team_name'] ?? 'Away',
      awayLogo: json['away_team']?['logo_url'] ?? '',
      scoreHome: json['score_home'] ?? 0,
      scoreAway: json['score_away'] ?? 0,
      status: json['status'] ?? 'scheduled',
      currentMinute: json['current_minute'] ?? 0,
      startTime: json['start_time'] ?? '',
      competition: json['competition_name'] ?? 'League',
      events: json['events'] ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'home_team_id': homeTeamId,
    'home_team': {'id': homeTeamId, 'name': homeTeam, 'logo_url': homeLogo},
    'away_team_id': awayTeamId,
    'away_team': {'id': awayTeamId, 'name': awayTeam, 'logo_url': awayLogo},
    'score_home': scoreHome,
    'score_away': scoreAway,
    'status': status,
    'current_minute': currentMinute,
    'start_time': startTime,
    'competition_name': competition,
    'events': events,
  };
}

class MatchesNotifier extends StateNotifier<AsyncValue<List<MatchModel>>> {
  final ApiClient _apiClient;
  final WebSocketService _wsService;

  MatchesNotifier(this._apiClient, this._wsService) : super(const AsyncValue.loading()) {
    _wsService.eventStream.listen((payload) {
      if (payload['event'] == 'App\\Events\\MatchUpdated') {
        _handleMatchUpdate(payload['data']);
      }
    });
  }

  void _handleMatchUpdate(Map<String, dynamic> data) {
    state.whenData((matches) {
      final updatedMatch = MatchModel.fromJson(data);
      final index = matches.indexWhere((m) => m.id == updatedMatch.id);
      if (index != -1) {
        final newList = List<MatchModel>.from(matches);
        newList[index] = updatedMatch;
        state = AsyncValue.data(newList);
      }
    });
  }

  Future<void> fetchMatches(String date) async {
    // 1. Try loading from cache first
    final cached = CacheService.getCachedMatches(date);
    if (cached != null) {
      final cachedList = cached.map((e) => MatchModel.fromJson(Map<String, dynamic>.from(e))).toList();
      state = AsyncValue.data(cachedList);
    } else {
      state = const AsyncValue.loading();
    }

    // 2. Try to fetch fresh data from API
    try {
      final response = await _apiClient.get('/matches', queryParameters: {'date': date});
      final List<dynamic> matchJsonList = response.data['matches'] ?? [];
      final list = matchJsonList.map((e) => MatchModel.fromJson(e)).toList();
      state = AsyncValue.data(list);

      // 3. Cache the fresh data
      await CacheService.cacheMatches(date, matchJsonList);
    } catch (e) {
      // If we already have cached data, keep it. Otherwise use mock fallback.
      if (cached != null) return;
      final mockList = [
        MatchModel(
          id: 1,
          homeTeamId: 1,
          homeTeam: 'Real Madrid',
          homeLogo: 'https://media.api-sports.io/football/teams/541.png',
          awayTeamId: 2,
          awayTeam: 'FC Barcelona',
          awayLogo: 'https://media.api-sports.io/football/teams/529.png',
          scoreHome: 2,
          scoreAway: 1,
          status: 'live',
          currentMinute: 64,
          startTime: '18:00',
          competition: 'La Liga',
        ),
        MatchModel(
          id: 2,
          homeTeamId: 3,
          homeTeam: 'Manchester City',
          homeLogo: 'https://media.api-sports.io/football/teams/50.png',
          awayTeamId: 4,
          awayTeam: 'Liverpool FC',
          awayLogo: 'https://media.api-sports.io/football/teams/40.png',
          scoreHome: 0,
          scoreAway: 0,
          status: 'scheduled',
          currentMinute: 0,
          startTime: '20:45',
          competition: 'Premier League',
        ),
        MatchModel(
          id: 3,
          homeTeamId: 5,
          homeTeam: 'Al Ahly SC',
          homeLogo: 'https://media.api-sports.io/football/teams/1012.png',
          awayTeamId: 6,
          awayTeam: 'Zamalek SC',
          awayLogo: 'https://media.api-sports.io/football/teams/1013.png',
          scoreHome: 2,
          scoreAway: 0,
          status: 'finished',
          currentMinute: 90,
          startTime: '15:00',
          competition: 'Egyptian Premier League',
        ),
      ];
      state = AsyncValue.data(mockList);
    }
  }
}

final matchesProvider = StateNotifierProvider<MatchesNotifier, AsyncValue<List<MatchModel>>>((ref) {
  final client = ref.watch(apiClientProvider);
  final ws = ref.watch(websocketServiceProvider);
  return MatchesNotifier(client, ws)..fetchMatches(DateTime.now().toIso8601String().split('T')[0]);
});

final matchDetailsProvider = FutureProvider.family<MatchModel, int>((ref, id) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/matches/$id');
    return MatchModel.fromJson(response.data);
  } catch (e) {
    // Provide details with simulated event timeline
    return MatchModel(
      id: id,
      homeTeamId: id == 3 ? 5 : 1,
      homeTeam: id == 3 ? 'Al Ahly SC' : 'Real Madrid',
      homeLogo: id == 3 
          ? 'https://media.api-sports.io/football/teams/1012.png'
          : 'https://media.api-sports.io/football/teams/541.png',
      awayTeamId: id == 3 ? 6 : 2,
      awayTeam: id == 3 ? 'Zamalek SC' : 'FC Barcelona',
      awayLogo: id == 3 
          ? 'https://media.api-sports.io/football/teams/1013.png'
          : 'https://media.api-sports.io/football/teams/529.png',
      scoreHome: id == 3 ? 2 : 2,
      scoreAway: id == 3 ? 0 : 1,
      status: id == 3 ? 'finished' : 'live',
      currentMinute: id == 3 ? 90 : 64,
      startTime: '18:00',
      competition: id == 3 ? 'Egyptian Premier League' : 'La Liga',
      events: [
        {
          'minute': 15,
          'type': 'goal',
          'player_name': 'Vinícius Júnior',
          'detail_player_name': 'Jude Bellingham',
          'team_name': 'Real Madrid'
        },
        {
          'minute': 38,
          'type': 'goal',
          'player_name': 'Robert Lewandowski',
          'detail_player_name': 'Pedri',
          'team_name': 'FC Barcelona'
        },
        {
          'minute': 55,
          'type': 'goal',
          'player_name': 'Kylian Mbappé',
          'detail_player_name': 'Federico Valverde',
          'team_name': 'Real Madrid'
        },
        {
          'minute': 60,
          'type': 'card',
          'player_name': 'Gavi',
          'detail': 'Yellow Card',
          'team_name': 'FC Barcelona'
        }
      ],
    );
  }
});
