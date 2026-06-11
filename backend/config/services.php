<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    /*
    |--------------------------------------------------------------------------
    | API-Football (RapidAPI) — Real-time football data
    |--------------------------------------------------------------------------
    |
    | Free tier: 100 requests/day.  Standard: 7500 requests/month.
    | Docs: https://www.api-football.com/documentation-v3
    |
    */
    'api_football' => [
        'key'      => env('API_FOOTBALL_KEY', ''),
        'base_url' => env('API_FOOTBALL_URL', 'https://v3.football.api-sports.io'),
        'cache_ttl' => env('API_FOOTBALL_CACHE_TTL', 300), // 5 minutes
    ],

    /*
    |--------------------------------------------------------------------------
    | Competition IDs — API-Football league identifiers
    |--------------------------------------------------------------------------
    */
    'football_leagues' => [
        'Premier League'          => 39,
        'La Liga'                 => 140,
        'Bundesliga'              => 78,
        'Serie A'                 => 135,
        'Ligue 1'                 => 61,
        'Egyptian Premier League' => 233,
        'Champions League'        => 2,
        'Saudi Pro League'        => 307,
    ],

    'fcm' => [
        'key' => env('FCM_SERVER_KEY', ''),
        'project_id' => env('FCM_PROJECT_ID', ''),
    ],

];
