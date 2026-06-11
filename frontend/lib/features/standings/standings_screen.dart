import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../auth/auth_provider.dart';
import '../auth/favorites_provider.dart';
import '../../core/localization/app_localizations.dart';

class StandingRowModel {
  final int teamId;
  final int rank;
  final String teamName;
  final String teamLogo;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsDiff;
  final int points;

  StandingRowModel({
    required this.teamId,
    required this.rank,
    required this.teamName,
    required this.teamLogo,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsDiff,
    required this.points,
  });

  factory StandingRowModel.fromJson(Map<String, dynamic> json) {
    return StandingRowModel(
      teamId: json['team_id'] ?? json['team']?['id'] ?? 0,
      rank: json['rank'] ?? 0,
      teamName: json['team']?['name'] ?? json['team_name'] ?? '',
      teamLogo: json['team']?['logo_url'] ?? '',
      played: json['played'] ?? 0,
      won: json['won'] ?? 0,
      drawn: json['drawn'] ?? 0,
      lost: json['lost'] ?? 0,
      goalsDiff: json['goals_diff'] ?? 0,
      points: json['points'] ?? 0,
    );
  }
}

final standingsListProvider = FutureProvider.family<List<StandingRowModel>, String>((ref, competition) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/standings', queryParameters: {'competition': competition});
    final List<dynamic> data = response.data['standings'] ?? [];
    return data.map((e) => StandingRowModel.fromJson(e)).toList();
  } catch (e) {
    // Provide design backups if network error
    if (competition == 'La Liga') {
      return [
        StandingRowModel(teamId: 1, rank: 1, teamName: 'Real Madrid', teamLogo: 'https://media.api-sports.io/football/teams/541.png', played: 31, won: 24, drawn: 6, lost: 1, goalsDiff: 47, points: 78),
        StandingRowModel(teamId: 2, rank: 2, teamName: 'FC Barcelona', teamLogo: 'https://media.api-sports.io/football/teams/529.png', played: 31, won: 21, drawn: 7, lost: 3, goalsDiff: 30, points: 70),
      ];
    } else if (competition == 'Premier League') {
      return [
        StandingRowModel(teamId: 3, rank: 1, teamName: 'Manchester City', teamLogo: 'https://media.api-sports.io/football/teams/50.png', played: 34, won: 25, drawn: 7, lost: 2, goalsDiff: 56, points: 82),
        StandingRowModel(teamId: 4, rank: 2, teamName: 'Liverpool FC', teamLogo: 'https://media.api-sports.io/football/teams/40.png', played: 34, won: 24, drawn: 8, lost: 2, goalsDiff: 50, points: 80),
      ];
    } else {
      return [
        StandingRowModel(teamId: 5, rank: 1, teamName: 'Al Ahly SC', teamLogo: 'https://media.api-sports.io/football/teams/1012.png', played: 22, won: 16, drawn: 6, lost: 0, goalsDiff: 33, points: 54),
        StandingRowModel(teamId: 6, rank: 2, teamName: 'Zamalek SC', teamLogo: 'https://media.api-sports.io/football/teams/1013.png', played: 23, won: 13, drawn: 6, lost: 4, goalsDiff: 19, points: 45),
      ];
    }
  }
});

class StandingsScreen extends ConsumerStatefulWidget {
  const StandingsScreen({super.key});

  @override
  ConsumerState<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends ConsumerState<StandingsScreen> {
  String _selectedCompetition = 'La Liga';

  String _getTranslatedCompName(String comp, AppLocalizations localizations) {
    if (comp == 'La Liga') return localizations.get('la_liga');
    if (comp == 'Premier League') return localizations.get('premier_league');
    if (comp == 'Egyptian Premier League') return localizations.get('egyptian_league');
    return comp;
  }

  @override
  Widget build(BuildContext context) {
    final standingsAsync = ref.watch(standingsListProvider(_selectedCompetition));
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.get('standings_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Horizontal Competition Selector Row
          _buildCompetitionSelector(localizations),
          
          const SizedBox(height: 12),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.darkSurface,
            child: Row(
              children: [
                const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary))),
                Expanded(child: Text(localizations.get('team'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary))),
                SizedBox(width: 32, child: Text(localizations.get('played'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                SizedBox(width: 32, child: Text(localizations.get('gd'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                SizedBox(width: 48, child: Text(localizations.get('points'), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
              ],
            ),
          ),

          // Standings List View
          Expanded(
            child: standingsAsync.when(
              data: (rows) => ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final isTopTier = row.rank <= 2; // Accent highlight for top ranks (e.g. Champions League seats)
                  final favoritesAsync = ref.watch(favoritesProvider);
                  final favorites = favoritesAsync.value ?? {};
                  final isFavorite = favorites.contains(row.teamId);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.borderGrey, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${row.rank}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isTopTier ? AppTheme.accentGreen : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Image.network(
                                row.teamLogo,
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.shield, size: 24, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Icon(
                                  isFavorite ? Icons.star : Icons.star_border,
                                  color: isFavorite ? AppTheme.accentAmber : AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final success = await ref
                                      .read(favoritesProvider.notifier)
                                      .toggleFavorite(row.teamId);
                                  if (!success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(localizations.get('login_required_filter')),
                                        backgroundColor: AppTheme.accentCrimson,
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                row.teamName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text('${row.played}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            row.goalsDiff > 0 ? '+${row.goalsDiff}' : '${row.goalsDiff}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: row.goalsDiff > 0 ? AppTheme.accentMint : AppTheme.accentCrimson,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${row.points}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentGreen),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.accentGreen),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitionSelector(AppLocalizations localizations) {
    final comps = ['La Liga', 'Premier League', 'Egyptian Premier League'];
    return Container(
      height: 60,
      color: AppTheme.darkSurfaceCard,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: comps.length,
        itemBuilder: (context, index) {
          final comp = comps[index];
          final isSelected = comp == _selectedCompetition;
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ChoiceChip(
              label: Text(_getTranslatedCompName(comp, localizations)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCompetition = comp;
                  });
                }
              },
              selectedColor: AppTheme.accentGreen,
              backgroundColor: AppTheme.darkSurface,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.darkBackground : AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }
}
