<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Sync today's matches every 5 minutes (live score updates)
        $schedule->command('football:sync')
            ->everyFiveMinutes()
            ->withoutOverlapping()
            ->appendOutputTo(storage_path('logs/football-sync.log'));

        // Sync all league standings every 6 hours
        $schedule->command('football:sync --standings')
            ->everySixHours()
            ->withoutOverlapping()
            ->appendOutputTo(storage_path('logs/football-sync.log'));
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
