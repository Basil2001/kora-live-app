<?php

namespace App\Services;

use App\Adapters\SportsApiContract;
use App\Models\FootballMatch;
use App\Models\Standing;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Carbon;

/**
 * FootballApiService — High-level orchestrator for football data.
 *
 * Responsibilities:
 *  • Wraps the SportsApiContract adapter with Redis/File cache layer
 *  • Enforces rate-limiting (budget-friendly)
 *  • Provides smart refresh logic (stale-data vs. fresh-data)
 *  • Supplies helper methods for controllers
 */
class FootballApiService
{
    protected SportsApiContract $adapter;
    protected int $cacheTtl;

    public function __construct(SportsApiContract $adapter)
    {
        $this->adapter = $adapter;
        $this->cacheTtl = (int) config('services.api_football.cache_ttl', 300);
    }

    // ──────────────────────────────────────────────────
    //  Matches
    // ──────────────────────────────────────────────────

    /**
     * Get matches for a date. Uses cache-first strategy, syncs from API when stale.
     */
    public function getMatchesByDate(string $date, ?string $status = null): array
    {
        $cacheKey = "matches:{$date}";

        // Attempt to sync if no local data OR cache expired
        if (!Cache::has($cacheKey)) {
            $this->syncMatchesSafe($date);
            Cache::put($cacheKey, true, $this->cacheTtl);
        }

        $query = FootballMatch::with(['homeTeam', 'awayTeam'])
            ->whereDate('start_time', $date);

        if ($status) {
            $query->where('status', $status);
        }

        return $query->orderBy('start_time', 'asc')->get()->toArray();
    }

    /**
     * Get match details with events and highlights.
     */
    public function getMatchDetails(int $matchId): ?FootballMatch
    {
        $match = FootballMatch::with(['homeTeam', 'awayTeam', 'events', 'highlights'])
            ->find($matchId);

        // If match is live, try to refresh its data
        if ($match && $match->status === 'live') {
            $cacheKey = "match_live_refresh:{$matchId}";
            if (!Cache::has($cacheKey)) {
                $this->syncMatchesSafe($match->start_time->toDateString());
                Cache::put($cacheKey, true, 60); // Refresh live matches every 60s
                $match->refresh();
                $match->load(['homeTeam', 'awayTeam', 'events', 'highlights']);
            }
        }

        return $match;
    }

    /**
     * Get live matches (currently in play).
     */
    public function getLiveMatches(): array
    {
        $today = Carbon::today()->toDateString();

        // Ensure today's data is synced
        $this->getMatchesByDate($today);

        return FootballMatch::with(['homeTeam', 'awayTeam'])
            ->where('status', 'live')
            ->orderBy('start_time', 'asc')
            ->get()
            ->toArray();
    }

    // ──────────────────────────────────────────────────
    //  Standings
    // ──────────────────────────────────────────────────

    /**
     * Get standings for a competition with cache-first.
     */
    public function getStandings(string $competition): array
    {
        $cacheKey = "standings:" . md5($competition);

        if (!Cache::has($cacheKey)) {
            $this->syncStandingsSafe($competition);
            Cache::put($cacheKey, true, $this->cacheTtl * 2); // Standings change less often
        }

        return Standing::with('team')
            ->where('competition_name', $competition)
            ->orderBy('rank', 'asc')
            ->get()
            ->toArray();
    }

    /**
     * Get list of supported competitions.
     */
    public function getCompetitions(): array
    {
        return array_keys(config('services.football_leagues', []));
    }

    // ──────────────────────────────────────────────────
    //  Sync Helpers (Rate-Limit Aware)
    // ──────────────────────────────────────────────────

    /**
     * Rate-limited sync of matches. Prevents duplicate API calls within cooldown window.
     */
    protected function syncMatchesSafe(string $date): void
    {
        $rateLimitKey = "api_rate:sync_matches:{$date}";

        // Don't hit the API if we already synced recently (within 2 minutes)
        if (Cache::has($rateLimitKey)) {
            return;
        }

        try {
            $result = $this->adapter->syncMatchesByDate($date);
            Cache::put($rateLimitKey, true, 120); // 2 minute cooldown per date

            Log::info("Football API sync matches", [
                'date' => $date,
                'result' => $result,
            ]);
        } catch (\Exception $e) {
            Log::error("Football API sync matches failed", [
                'date' => $date,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Rate-limited sync of standings.
     */
    protected function syncStandingsSafe(string $competition): void
    {
        $rateLimitKey = "api_rate:sync_standings:" . md5($competition);

        if (Cache::has($rateLimitKey)) {
            return;
        }

        try {
            $result = $this->adapter->syncStandings($competition);
            Cache::put($rateLimitKey, true, 600); // 10 minute cooldown for standings

            Log::info("Football API sync standings", [
                'competition' => $competition,
                'result' => $result,
            ]);
        } catch (\Exception $e) {
            Log::error("Football API sync standings failed", [
                'competition' => $competition,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Force sync — bypasses rate limit (for artisan commands).
     */
    public function forceSync(string $date): array
    {
        try {
            $result = $this->adapter->syncMatchesByDate($date);
            Cache::put("matches:{$date}", true, $this->cacheTtl);
            return $result;
        } catch (\Exception $e) {
            Log::error("Force sync failed", ['date' => $date, 'error' => $e->getMessage()]);
            return ['status' => 'error', 'message' => $e->getMessage()];
        }
    }

    /**
     * Force sync standings — bypasses rate limit (for artisan commands).
     */
    public function forceSyncStandings(string $competition): array
    {
        try {
            $result = $this->adapter->syncStandings($competition);
            Cache::put("standings:" . md5($competition), true, $this->cacheTtl * 2);
            return $result;
        } catch (\Exception $e) {
            Log::error("Force sync standings failed", [
                'competition' => $competition,
                'error' => $e->getMessage(),
            ]);
            return ['status' => 'error', 'message' => $e->getMessage()];
        }
    }

    /**
     * Get API usage stats (for admin dashboard).
     */
    public function getApiStats(): array
    {
        return [
            'adapter' => get_class($this->adapter),
            'cache_ttl' => $this->cacheTtl,
            'has_api_key' => !empty(config('services.api_football.key')),
            'supported_leagues' => $this->getCompetitions(),
        ];
    }
}
