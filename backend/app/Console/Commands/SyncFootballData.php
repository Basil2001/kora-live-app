<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Services\FootballApiService;
use Illuminate\Support\Carbon;

/**
 * Artisan command to sync football data from the external API.
 *
 * Usage:
 *   php artisan football:sync                  → Sync today's matches
 *   php artisan football:sync --date=2026-06-04 → Sync specific date
 *   php artisan football:sync --standings       → Sync all league standings
 *   php artisan football:sync --league="La Liga" → Sync specific league standings
 */
class SyncFootballData extends Command
{
    protected $signature = 'football:sync
        {--date= : Date to sync matches for (YYYY-MM-DD, defaults to today)}
        {--standings : Sync standings for all configured leagues}
        {--league= : Sync standings for a specific league name}
        {--days=1 : Number of days to sync (starting from --date)}';

    protected $description = 'Sync football matches and standings from the external API';

    public function handle(FootballApiService $service): int
    {
        $this->info('🏟️  Kora Live — Football Data Sync');
        $this->newLine();

        // ── Sync Matches ──
        $startDate = $this->option('date')
            ? Carbon::parse($this->option('date'))
            : Carbon::today();
        $days = (int) $this->option('days');

        $this->info("📅 Syncing matches for {$days} day(s) starting from {$startDate->toDateString()}...");

        $totalMatches = 0;
        for ($i = 0; $i < $days; $i++) {
            $date = $startDate->copy()->addDays($i)->toDateString();
            $this->line("   → {$date}...");

            $result = $service->forceSync($date);
            $count = $result['matches_synced'] ?? 0;
            $totalMatches += $count;

            $this->line("     ✅ {$count} matches synced");
        }

        $this->newLine();
        $this->info("⚽ Total matches synced: {$totalMatches}");

        // ── Sync Standings ──
        if ($this->option('standings') || $this->option('league')) {
            $this->newLine();

            $leagues = $this->option('league')
                ? [$this->option('league')]
                : $service->getCompetitions();

            $this->info("📊 Syncing standings for " . count($leagues) . " league(s)...");

            foreach ($leagues as $league) {
                $this->line("   → {$league}...");
                $result = $service->forceSyncStandings($league);

                $teamsCount = $result['teams_synced'] ?? 0;
                $status = $result['status'] ?? 'unknown';

                if ($status === 'success') {
                    $this->line("     ✅ {$teamsCount} teams synced");
                } else {
                    $msg = $result['message'] ?? 'Failed';
                    $this->warn("     ⚠️  {$msg}");
                }
            }
        }

        $this->newLine();

        // ── API Stats ──
        $stats = $service->getApiStats();
        $this->table(
            ['Property', 'Value'],
            [
                ['Adapter', class_basename($stats['adapter'])],
                ['Has API Key', $stats['has_api_key'] ? '✅ Yes' : '❌ No (using mock)'],
                ['Cache TTL', $stats['cache_ttl'] . 's'],
                ['Leagues', count($stats['supported_leagues'])],
            ]
        );

        $this->info('🎉 Sync complete!');
        return Command::SUCCESS;
    }
}
