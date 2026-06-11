<?php

namespace App\Adapters;

use App\Models\Team;
use App\Models\FootballMatch;
use App\Models\Standing;
use App\Models\MatchEvent;
use Illuminate\Support\Carbon;

class MockSportsApiAdapter implements SportsApiContract
{
    public function syncMatchesByDate(string $date): array
    {
        // 1. Ensure we have mock teams in the database
        $teamsData = [
            ['name' => 'Real Madrid', 'short_name' => 'RMA', 'logo_url' => 'https://media.api-sports.io/football/teams/541.png', 'venue_name' => 'Santiago Bernabéu'],
            ['name' => 'FC Barcelona', 'short_name' => 'BAR', 'logo_url' => 'https://media.api-sports.io/football/teams/529.png', 'venue_name' => 'Camp Nou'],
            ['name' => 'Manchester City', 'short_name' => 'MCI', 'logo_url' => 'https://media.api-sports.io/football/teams/50.png', 'venue_name' => 'Etihad Stadium'],
            ['name' => 'Liverpool FC', 'short_name' => 'LIV', 'logo_url' => 'https://media.api-sports.io/football/teams/40.png', 'venue_name' => 'Anfield'],
            ['name' => 'Al Ahly SC', 'short_name' => 'AHL', 'logo_url' => 'https://media.api-sports.io/football/teams/1012.png', 'venue_name' => 'Cairo International Stadium'],
            ['name' => 'Zamalek SC', 'short_name' => 'ZAM', 'logo_url' => 'https://media.api-sports.io/football/teams/1013.png', 'venue_name' => 'Cairo International Stadium'],
        ];

        $teams = [];
        foreach ($teamsData as $data) {
            $teams[] = Team::updateOrCreate(['name' => $data['name']], $data);
        }

        // 2. Generate simulated matches for this date
        $syncedMatches = [];
        
        // Match 1: El Clásico (Live Match)
        $matchTime1 = Carbon::parse($date)->setTime(18, 0, 0);
        $m1 = FootballMatch::updateOrCreate([
            'home_team_id' => $teams[0]->id,
            'away_team_id' => $teams[1]->id,
            'start_time' => $matchTime1,
        ], [
            'status' => 'live',
            'score_home' => 2,
            'score_away' => 1,
            'current_minute' => 64,
            'competition_name' => 'La Liga',
            'round' => 'Round 32',
            'referee' => 'Jesús Gil Manzano',
            'venue_name' => 'Santiago Bernabéu',
        ]);

        // Generate events for Match 1
        MatchEvent::updateOrCreate([
            'match_id' => $m1->id,
            'minute' => 15,
            'type' => 'goal',
        ], [
            'team_id' => $teams[0]->id,
            'player_name' => 'Vinícius Júnior',
            'detail_player_name' => 'Jude Bellingham',
            'detail' => 'Normal Goal',
        ]);

        MatchEvent::updateOrCreate([
            'match_id' => $m1->id,
            'minute' => 38,
            'type' => 'goal',
        ], [
            'team_id' => $teams[1]->id,
            'player_name' => 'Robert Lewandowski',
            'detail_player_name' => 'Pedri',
            'detail' => 'Header',
        ]);

        MatchEvent::updateOrCreate([
            'match_id' => $m1->id,
            'minute' => 55,
            'type' => 'goal',
        ], [
            'team_id' => $teams[0]->id,
            'player_name' => 'Kylian Mbappé',
            'detail_player_name' => 'Federico Valverde',
            'detail' => 'Normal Goal',
        ]);

        MatchEvent::updateOrCreate([
            'match_id' => $m1->id,
            'minute' => 60,
            'type' => 'card',
        ], [
            'team_id' => $teams[1]->id,
            'player_name' => 'Gavi',
            'detail' => 'Yellow Card',
        ]);

        // Match 2: English Premier League Blockbuster (Scheduled)
        $matchTime2 = Carbon::parse($date)->setTime(20, 45, 0);
        $m2 = FootballMatch::updateOrCreate([
            'home_team_id' => $teams[2]->id,
            'away_team_id' => $teams[3]->id,
            'start_time' => $matchTime2,
        ], [
            'status' => 'scheduled',
            'score_home' => 0,
            'score_away' => 0,
            'current_minute' => 0,
            'competition_name' => 'Premier League',
            'round' => 'Round 35',
            'referee' => 'Anthony Taylor',
            'venue_name' => 'Etihad Stadium',
        ]);

        // Match 3: Cairo Derby (Finished Match)
        $matchTime3 = Carbon::parse($date)->setTime(15, 0, 0);
        $m3 = FootballMatch::updateOrCreate([
            'home_team_id' => $teams[4]->id,
            'away_team_id' => $teams[5]->id,
            'start_time' => $matchTime3,
        ], [
            'status' => 'finished',
            'score_home' => 2,
            'score_away' => 0,
            'current_minute' => 90,
            'competition_name' => 'Egyptian Premier League',
            'round' => 'Round 10',
            'referee' => 'Mustafa Ghorbal',
            'venue_name' => 'Cairo International Stadium',
        ]);

        // Generate events for Match 3
        MatchEvent::updateOrCreate([
            'match_id' => $m3->id,
            'minute' => 42,
            'type' => 'goal',
        ], [
            'team_id' => $teams[4]->id,
            'player_name' => 'Hussein El Shahat',
            'detail_player_name' => 'Emam Ashour',
            'detail' => 'Normal Goal',
        ]);

        MatchEvent::updateOrCreate([
            'match_id' => $m3->id,
            'minute' => 88,
            'type' => 'goal',
        ], [
            'team_id' => $teams[4]->id,
            'player_name' => 'Wessam Abou Ali',
            'detail' => 'Penalty',
        ]);

        return [
            'status' => 'success',
            'matches_synced' => 3,
        ];
    }

    public function syncStandings(string $competitionName): array
    {
        $teams = Team::all();
        if ($teams->isEmpty()) {
            return ['status' => 'empty', 'message' => 'No teams available to build standings'];
        }

        $ranks = [
            'La Liga' => [
                ['name' => 'Real Madrid', 'points' => 78, 'played' => 31, 'won' => 24, 'drawn' => 6, 'lost' => 1, 'gf' => 67, 'ga' => 20],
                ['name' => 'FC Barcelona', 'points' => 70, 'played' => 31, 'won' => 21, 'drawn' => 7, 'lost' => 3, 'gf' => 62, 'ga' => 32],
            ],
            'Premier League' => [
                ['name' => 'Manchester City', 'points' => 82, 'played' => 34, 'won' => 25, 'drawn' => 7, 'lost' => 2, 'gf' => 88, 'ga' => 32],
                ['name' => 'Liverpool FC', 'points' => 80, 'played' => 34, 'won' => 24, 'drawn' => 8, 'lost' => 2, 'gf' => 85, 'ga' => 35],
            ],
            'Egyptian Premier League' => [
                ['name' => 'Al Ahly SC', 'points' => 54, 'played' => 22, 'won' => 16, 'drawn' => 6, 'lost' => 0, 'gf' => 45, 'ga' => 12],
                ['name' => 'Zamalek SC', 'points' => 45, 'played' => 23, 'won' => 13, 'drawn' => 6, 'lost' => 4, 'gf' => 38, 'ga' => 19],
            ]
        ];

        $targetRanks = $ranks[$competitionName] ?? [
            ['name' => 'Real Madrid', 'points' => 10, 'played' => 4, 'won' => 3, 'drawn' => 1, 'lost' => 0, 'gf' => 8, 'ga' => 2],
            ['name' => 'FC Barcelona', 'points' => 9, 'played' => 4, 'won' => 3, 'drawn' => 0, 'lost' => 1, 'gf' => 9, 'ga' => 4],
        ];

        foreach ($targetRanks as $index => $item) {
            $team = Team::where('name', $item['name'])->first();
            if ($team) {
                Standing::updateOrCreate([
                    'team_id' => $team->id,
                    'competition_name' => $competitionName,
                ], [
                    'rank' => $index + 1,
                    'played' => $item['played'],
                    'won' => $item['won'],
                    'drawn' => $item['drawn'],
                    'lost' => $item['lost'],
                    'goals_for' => $item['gf'],
                    'goals_against' => $item['ga'],
                    'goals_diff' => $item['gf'] - $item['ga'],
                    'points' => $item['points'],
                ]);
            }
        }

        return ['status' => 'success', 'competition' => $competitionName];
    }

    public function syncTeamDetails(int $teamId): array
    {
        return ['status' => 'success', 'team_id' => $teamId];
    }
}
