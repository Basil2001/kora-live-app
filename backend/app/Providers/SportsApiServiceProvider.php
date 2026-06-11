<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Adapters\SportsApiContract;
use App\Adapters\MockSportsApiAdapter;
use App\Adapters\ApiFootballAdapter;
use App\Services\FootballApiService;

class SportsApiServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Register the API adapter (Mock vs Real based on key presence)
        $this->app->singleton(SportsApiContract::class, function ($app) {
            $key = config('services.api_football.key');
            
            if (empty($key)) {
                return new MockSportsApiAdapter();
            }

            return new ApiFootballAdapter();
        });

        // Register the high-level service that wraps the adapter with caching
        $this->app->singleton(FootballApiService::class, function ($app) {
            return new FootballApiService(
                $app->make(SportsApiContract::class)
            );
        });
    }

    public function boot(): void
    {
        //
    }
}
