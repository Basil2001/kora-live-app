<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\v1\AuthController;
use App\Http\Controllers\Api\v1\MatchController;
use App\Http\Controllers\Api\v1\StandingsController;
use App\Http\Controllers\Api\v1\NewsController;
use App\Http\Controllers\Api\v1\FavoriteController;
use App\Http\Controllers\Api\v1\NotificationController;
use App\Http\Controllers\Api\CommentController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::prefix('v1')->group(function () {
    // Guest/Auth Routes
    Route::post('/auth/register', [AuthController::class, 'register']);
    Route::post('/auth/login', [AuthController::class, 'login']);

    // Public Football Data Routes
    Route::get('/matches', [MatchController::class, 'index']);
    Route::get('/matches/live', [MatchController::class, 'live']);
    Route::get('/matches/{id}', [MatchController::class, 'show']);
    Route::get('/standings', [StandingsController::class, 'index']);
    Route::get('/competitions', [MatchController::class, 'competitions']);
    
    // Public News and Media Routes
    Route::get('/news', [NewsController::class, 'index']);
    Route::get('/news/{slug}', [NewsController::class, 'showBySlug']);
    Route::get('/highlights', [NewsController::class, 'highlights']);

    // Public Comments (read only)
    Route::get('/matches/{matchId}/comments', [CommentController::class, 'index']);

    // Protected Routes (Require Bearer Token)
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::get('/profile', [AuthController::class, 'profile']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::put('/profile/password', [AuthController::class, 'changePassword']);
        
        // Secured streaming link endpoint
        Route::get('/matches/{id}/stream', [MatchController::class, 'streamInfo']);

        // Favorite Teams
        Route::get('/favorites', [FavoriteController::class, 'index']);
        Route::post('/favorites/toggle', [FavoriteController::class, 'toggle']);

        // Notifications
        Route::get('/notifications', [NotificationController::class, 'index']);
        Route::post('/notifications/read/{id}', [NotificationController::class, 'markAsRead']);
        Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::post('/notifications/tokens', [NotificationController::class, 'registerToken']);
        Route::get('/notifications/preferences', [NotificationController::class, 'getPreferences']);
        Route::put('/notifications/preferences', [NotificationController::class, 'updatePreferences']);

        // Comments (write)
        Route::post('/matches/{matchId}/comments', [CommentController::class, 'store']);
        Route::delete('/matches/{matchId}/comments/{commentId}', [CommentController::class, 'destroy']);
        Route::post('/matches/{matchId}/comments/{commentId}/like', [CommentController::class, 'like']);
    });
});

