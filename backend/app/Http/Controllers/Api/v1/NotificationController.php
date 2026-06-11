<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use App\Services\FcmService;
use App\Models\AppNotification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    protected $fcmService;

    public function __construct(FcmService $fcmService)
    {
        $this->fcmService = $fcmService;
    }

    /**
     * Get user's notifications.
     */
    public function index(Request $request)
    {
        $user = $request->user();
        
        $notifications = AppNotification::where('user_id', $user->id)
            ->orWhereNull('user_id')
            ->orderBy('created_at', 'desc')
            ->paginate(30);

        return response()->json($notifications);
    }

    /**
     * Mark a notification as read.
     */
    public function markAsRead(Request $request, $id)
    {
        $user = $request->user();
        
        $notification = AppNotification::where('id', $id)
            ->where(function($query) use ($user) {
                $query->where('user_id', $user->id)
                      ->orWhereNull('user_id');
            })->firstOrFail();

        $notification->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'Notification marked as read',
            'notification' => $notification
        ]);
    }

    /**
     * Mark all notifications as read.
     */
    public function markAllAsRead(Request $request)
    {
        $user = $request->user();

        AppNotification::where('user_id', $user->id)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json([
            'success' => true,
            'message' => 'All user notifications marked as read'
        ]);
    }

    /**
     * Register a device token.
     */
    public function registerToken(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'platform' => 'nullable|string|in:android,ios,web',
        ]);

        $user = $request->user();
        $platform = $request->input('platform', 'android');

        $deviceToken = $this->fcmService->registerToken($user, $request->token, $platform);

        return response()->json([
            'success' => true,
            'message' => 'Device token registered successfully',
            'device_token' => $deviceToken
        ]);
    }

    /**
     * Get user's preferences.
     */
    public function getPreferences(Request $request)
    {
        $user = $request->user();
        $preferences = $this->fcmService->getPreferences($user);
        return response()->json($preferences);
    }

    /**
     * Update user's preferences.
     */
    public function updatePreferences(Request $request)
    {
        $request->validate([
            'goals' => 'boolean',
            'match_start' => 'boolean',
            'match_end' => 'boolean',
            'news' => 'boolean',
            'promotions' => 'boolean',
        ]);

        $user = $request->user();
        $data = $request->only(['goals', 'match_start', 'match_end', 'news', 'promotions']);

        $preferences = $this->fcmService->updatePreferences($user, $data);

        return response()->json([
            'success' => true,
            'message' => 'Notification preferences updated successfully',
            'preferences' => $preferences
        ]);
    }
}
