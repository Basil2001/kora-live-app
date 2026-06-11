<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\AppNotification;
use App\Models\NotificationPreference;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    /**
     * Register or update a device token for a user.
     */
    public function registerToken(User $user, string $token, string $platform = 'android'): DeviceToken
    {
        // Deactivate this token if it belongs to another user
        DeviceToken::where('token', $token)
            ->where('user_id', '!=', $user->id)
            ->update(['is_active' => false]);

        return DeviceToken::updateOrCreate(
            ['token' => $token],
            [
                'user_id' => $user->id,
                'platform' => $platform,
                'is_active' => true
            ]
        );
    }

    /**
     * Get user's notification preferences, or create defaults.
     */
    public function getPreferences(User $user): NotificationPreference
    {
        return NotificationPreference::firstOrCreate(
            ['user_id' => $user->id],
            [
                'goals' => true,
                'match_start' => true,
                'match_end' => true,
                'news' => true,
                'promotions' => false,
            ]
        );
    }

    /**
     * Update user's notification preferences.
     */
    public function updatePreferences(User $user, array $preferences): NotificationPreference
    {
        $pref = $this->getPreferences($user);
        $pref->update($preferences);
        return $pref;
    }

    /**
     * Send notification to a specific user.
     */
    public function sendToUser(User $user, string $title, string $body, string $type = 'system', array $data = []): ?AppNotification
    {
        // Check preferences
        $pref = $this->getPreferences($user);
        if (!$this->shouldSendNotification($pref, $type)) {
            Log::info("Notification not sent to user {$user->id} due to preference settings for type: {$type}");
            return null;
        }

        // 1. Save to in-app notification center
        $notification = AppNotification::create([
            'user_id' => $user->id,
            'title' => $title,
            'body' => $body,
            'type' => $type,
            'data' => $data,
            'is_read' => false,
            'sent_at' => now(),
        ]);

        // 2. Send Push Notification to active device tokens
        $tokens = $user->deviceTokens()->where('is_active', true)->pluck('token')->toArray();
        if (!empty($tokens)) {
            $this->sendPush($tokens, $title, $body, $data);
        }

        return $notification;
    }

    /**
     * Send notification to all users (broadcast/promo/system).
     */
    public function sendToAll(string $title, string $body, string $type = 'system', array $data = []): void
    {
        // Save to in-app notifications for all users (or create one record with user_id = null for global notifications)
        AppNotification::create([
            'user_id' => null, // null means global/all users
            'title' => $title,
            'body' => $body,
            'type' => $type,
            'data' => $data,
            'is_read' => false,
            'sent_at' => now(),
        ]);

        // Fetch all active tokens
        $tokens = DeviceToken::where('is_active', true)->pluck('token')->toArray();
        if (!empty($tokens)) {
            $this->sendPush($tokens, $title, $body, $data);
        }
    }

    /**
     * Helper to check if a notification type is allowed by preferences.
     */
    private function shouldSendNotification(NotificationPreference $pref, string $type): bool
    {
        return match ($type) {
            'goal' => $pref->goals,
            'match_start' => $pref->match_start,
            'match_end' => $pref->match_end,
            'news' => $pref->news,
            'promo' => $pref->promotions,
            default => true, // system/other notifications sent by default
        };
    }

    /**
     * Internal push delivery mechanism.
     */
    private function sendPush(array $tokens, string $title, string $body, array $data = []): void
    {
        $serverKey = config('services.fcm.key');

        Log::info("Sending push notification to " . count($tokens) . " devices. Title: '{$title}'");

        if (empty($serverKey)) {
            // FCM details not configured: simulate/log the push delivery
            Log::info("FCM Server Key not configured. Simulating delivery to tokens: " . implode(', ', $tokens));
            return;
        }

        // If server key exists, attempt legacy FCM HTTP endpoint or v1 if payload constructed correctly.
        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'registration_ids' => $tokens,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => 'default',
                ],
                'data' => $data,
                'priority' => 'high',
            ]);

            if ($response->failed()) {
                Log::error("FCM request failed: " . $response->body());
            } else {
                Log::info("FCM sent successfully: " . $response->body());
            }
        } catch (\Exception $e) {
            Log::error("Error sending FCM: " . $e->getMessage());
        }
    }
}
