<?php

namespace App\Filament\Widgets;

use App\Models\FootballMatch;
use App\Models\Team;
use App\Models\Article;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class DashboardStatsWidget extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $totalMatches = FootballMatch::count();
        $liveMatches = FootballMatch::where('status', 'live')->count();
        $totalTeams = Team::count();
        $totalArticles = Article::count();
        $publishedArticles = Article::where('status', 'published')->count();
        $totalUsers = User::count();
        $todayMatches = FootballMatch::whereDate('start_time', today())->count();

        return [
            Stat::make('Total Users', $totalUsers)
                ->description('Registered accounts')
                ->descriptionIcon('heroicon-m-users')
                ->color('primary')
                ->chart([7, 12, 8, 15, 20, 18, $totalUsers]),

            Stat::make('Live Matches', $liveMatches)
                ->description("$todayMatches matches today")
                ->descriptionIcon('heroicon-m-signal')
                ->color($liveMatches > 0 ? 'danger' : 'gray')
                ->chart([2, 4, 1, 3, $liveMatches]),

            Stat::make('Total Matches', $totalMatches)
                ->description('All time recorded')
                ->descriptionIcon('heroicon-m-calendar')
                ->color('success'),

            Stat::make('Teams', $totalTeams)
                ->description('Registered clubs')
                ->descriptionIcon('heroicon-m-flag')
                ->color('info'),

            Stat::make('Articles', $totalArticles)
                ->description("$publishedArticles published")
                ->descriptionIcon('heroicon-m-newspaper')
                ->color('warning'),
        ];
    }
}
