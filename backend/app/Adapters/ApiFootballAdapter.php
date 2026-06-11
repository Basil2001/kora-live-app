<?php

namespace App\Adapters;

use App\Models\Team;
use App\Models\FootballMatch;
use App\Models\Standing;
use App\Models\MatchEvent;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Carbon;

class ApiFootballAdapter implements SportsApiContract
{
    protected string $baseUrl;
    protected string $apiKey;

    public function __construct()
    {
        $this->apiKey = config('services.api_football.key', '');
        $this->baseUrl = config('services.api_football.base_url', 'https://v3.football.api-sports.io');
    }

    // ──────────────────────────────────────────────────
    //  API Request Helper
    // ──────────────────────────────────────────────────

    protected function apiGet(string $endpoint, array $params = []): array
    {
        if (empty($this->apiKey)) {
            throw new \Exception('API-Football Key is not configured in services config.');
        }

        $response = Http::withHeaders([
            'x-rapidapi-key'  => $this->apiKey,
            'x-rapidapi-host' => parse_url($this->baseUrl, PHP_URL_HOST),
        ])->get("{$this->baseUrl}{$endpoint}", $params);

        if (!$response->successful()) {
            throw new \Exception("API-Football returned HTTP {$response->status()} for {$endpoint}");
        }

        return $response->json()['response'] ?? [];
    }

    // ──────────────────────────────────────────────────
    //  Sync Matches
    // ──────────────────────────────────────────────────

    public function syncMatchesByDate(string $date): array
    {
        $fixtures = $this->apiGet('/fixtures', ['date' => $date]);
        $synced = 0;

        foreach ($fixtures as $fixture) {
            $apiHomeTeam = $fixture['teams']['home'];
            $apiAwayTeam = $fixture['teams']['away'];

            $homeTeam = Team::updateOrCreate(['name' => $apiHomeTeam['name']], [
                'logo_url'   => $apiHomeTeam['logo'],
                'short_name' => substr($apiHomeTeam['name'], 0, 3),
            ]);

            $awayTeam = Team::updateOrCreate(['name' => $apiAwayTeam['name']], [
                'logo_url'   => $apiAwayTeam['logo'],
                'short_name' => substr($apiAwayTeam['name'], 0, 3),
            ]);

            $status = $this->mapFixtureStatus($fixture['fixture']['status']['short']);

            $m = FootballMatch::updateOrCreate([
                'home_team_id' => $homeTeam->id,
                'away_team_id' => $awayTeam->id,
                'start_time'   => Carbon::parse($fixture['fixture']['date']),
            ], [
                'status'           => $status,
                'score_home'       => $fixture['goals']['home'] ?? 0,
                'score_away'       => $fixture['goals']['away'] ?? 0,
                'current_minute'   => $fixture['fixture']['status']['elapsed'] ?? 0,
                'competition_name' => $fixture['league']['name'],
                'round'            => $fixture['league']['round'] ?? null,
                'referee'          => $fixture['fixture']['referee'] ?? null,
                'venue_name'       => $fixture['fixture']['venue']['name'] ?? null,
            ]);

            // Sync events for non-scheduled matches
            if ($status !== 'scheduled') {
                $this->syncMatchEvents($m, $fixture, $homeTeam, $awayTeam);
            }

            $synced++;
        }

        return [
            'status'         => 'success',
            'matches_synced' => $synced,
        ];
    }

    // ──────────────────────────────────────────────────
    //  Sync Standings
    // ──────────────────────────────────────────────────

    public function syncStandings(string $competitionName): array
    {
        $leagueId = config("services.football_leagues.{$competitionName}");

        if (!$leagueId) {
            throw new \Exception("Unknown competition: {$competitionName}. Add its ID to services.football_leagues config.");
        }

        $season = (int) Carbon::now()->format('Y');
        // Football seasons span two years; if we're before August use previous year
        if (Carbon::now()->month < 8) {
            $season--;
        }

        $data = $this->apiGet('/standings', [
            'league' => $leagueId,
            'season' => $season,
        ]);

        if (empty($data)) {
            return ['status' => 'empty', 'message' => 'No standings data returned'];
        }

        $league = $data[0]['league'] ?? [];
        $standingsGroups = $league['standings'] ?? [];
        $synced = 0;

        foreach ($standingsGroups as $group) {
            foreach ($group as $entry) {
                $team = Team::updateOrCreate(['name' => $entry['team']['name']], [
                    'logo_url'   => $entry['team']['logo'],
                    'short_name' => substr($entry['team']['name'], 0, 3),
                ]);

                Standing::updateOrCreate([
                    'team_id'          => $team->id,
                    'competition_name' => $competitionName,
                ], [
                    'rank'          => $entry['rank'],
                    'played'        => $entry['all']['played'] ?? 0,
                    'won'           => $entry['all']['win'] ?? 0,
                    'drawn'         => $entry['all']['draw'] ?? 0,
                    'lost'          => $entry['all']['lose'] ?? 0,
                    'goals_for'     => $entry['all']['goals']['for'] ?? 0,
                    'goals_against' => $entry['all']['goals']['against'] ?? 0,
                    'goals_diff'    => $entry['goalsDiff'] ?? 0,
                    'points'        => $entry['points'] ?? 0,
                ]);

                $synced++;
            }
        }

        return [
            'status'          => 'success',
            'competition'     => $competitionName,
            'teams_synced'    => $synced,
        ];
    }

    // ──────────────────────────────────────────────────
    //  Sync Team Details
    // ──────────────────────────────────────────────────

    public function syncTeamDetails(int $teamId): array
    {
        $team = Team::findOrFail($teamId);

        // Try to find the API-Football team ID by name
        $searchResults = $this->apiGet('/teams', ['search' => $team->name]);

        if (empty($searchResults)) {
            return ['status' => 'not_found', 'message' => "Team '{$team->name}' not found on API-Football"];
        }

        $apiTeam = $searchResults[0]['team'];
        $venue = $searchResults[0]['venue'] ?? [];

        $team->update([
            'logo_url'    => $apiTeam['logo'] ?? $team->logo_url,
            'short_name'  => $apiTeam['code'] ?? $team->short_name,
            'venue_name'  => $venue['name'] ?? $team->venue_name,
            'venue_city'  => $venue['city'] ?? $team->venue_city,
            'founded'     => $apiTeam['founded'] ?? $team->founded,
        ]);

        return [
            'status'    => 'success',
            'team_id'   => $team->id,
            'team_name' => $team->name,
        ];
    }

    // ──────────────────────────────────────────────────
    //  Private Helpers
    // ──────────────────────────────────────────────────

    protected function mapFixtureStatus(string $shortStatus): string
    {
        $map = [
            'TBD' => 'scheduled',
            'NS'  => 'scheduled',
            '1H'  => 'live',
            'HT'  => 'live',
            '2H'  => 'live',
            'ET'  => 'live',
            'BT'  => 'live',
            'P'   => 'live',
            'SUSP'=> 'live',
            'INT' => 'live',
            'LIVE'=> 'live',
            'FT'  => 'finished',
            'AET' => 'finished',
            'PEN' => 'finished',
            'PST' => 'postponed',
            'CANC'=> 'cancelled',
            'ABD' => 'cancelled',
            'AWD' => 'finished',
            'WO'  => 'finished',
        ];

        return $map[$shortStatus] ?? 'scheduled';
    }

    protected function syncMatchEvents(FootballMatch $match, array $fixture, Team $homeTeam, Team $awayTeam): void
    {
        $events = $fixture['events'] ?? [];

        foreach ($events as $event) {
            $eventTeam = ($event['team']['name'] ?? '') === $homeTeam->name
                ? $homeTeam
                : $awayTeam;

            $eventType = match ($event['type'] ?? '') {
                'Goal'  => 'goal',
                'Card'  => 'card',
                'subst' => 'substitution',
                'Var'   => 'var',
                default => 'other',
            };

            MatchEvent::updateOrCreate([
                'match_id'    => $match->id,
                'minute'      => $event['time']['elapsed'] ?? 0,
                'type'        => $eventType,
                'player_name' => $event['player']['name'] ?? 'Unknown',
            ], [
                'team_id'            => $eventTeam->id,
                'extra_minute'       => $event['time']['extra'] ?? null,
                'detail_player_name' => $event['assist']['name'] ?? null,
                'detail'             => $event['detail'] ?? null,
            ]);
        }
    }
}
