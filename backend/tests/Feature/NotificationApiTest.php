<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\AppNotification;
use App\Models\DeviceToken;
use App\Models\NotificationPreference;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_access_notifications_endpoints()
    {
        $this->getJson('/api/v1/notifications')->assertStatus(401);
        $this->postJson('/api/v1/notifications/read/1')->assertStatus(401);
        $this->postJson('/api/v1/notifications/read-all')->assertStatus(401);
        $this->postJson('/api/v1/notifications/tokens', ['token' => 'abc'])->assertStatus(401);
        $this->getJson('/api/v1/notifications/preferences')->assertStatus(401);
        $this->putJson('/api/v1/notifications/preferences', ['goals' => false])->assertStatus(401);
    }

    public function test_user_can_retrieve_notifications()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        // Create a notification specifically for user
        $n1 = AppNotification::create([
            'user_id' => $user->id,
            'title' => 'Match starting soon',
            'body' => 'Real Madrid vs Barcelona kick off in 10 minutes.',
            'type' => 'match_start',
            'is_read' => false,
            'sent_at' => now(),
        ]);

        // Create a global notification
        $n2 = AppNotification::create([
            'user_id' => null,
            'title' => 'System Update',
            'body' => 'Welcome to Kora Live app.',
            'type' => 'system',
            'is_read' => false,
            'sent_at' => now(),
        ]);

        // Create notification for another user
        $otherUser = User::create([
            'name' => 'Other Doe',
            'email' => 'other@example.com',
            'password' => bcrypt('password123'),
        ]);
        AppNotification::create([
            'user_id' => $otherUser->id,
            'title' => 'Other alert',
            'body' => 'Should not see this.',
            'type' => 'goal',
            'is_read' => false,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/notifications');

        $response->assertStatus(200);
        $response->assertJsonCount(2, 'data'); // Should only see user and global ones
    }

    public function test_user_can_mark_notification_as_read()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);
        $notification = AppNotification::create([
            'user_id' => $user->id,
            'title' => 'Goal alert',
            'body' => 'Goal by Mo Salah!',
            'type' => 'goal',
            'is_read' => false,
        ]);

        $this->actingAs($user, 'sanctum')
            ->postJson("/api/v1/notifications/read/{$notification->id}")
            ->assertStatus(200);

        $this->assertTrue($notification->fresh()->is_read);
    }

    public function test_user_can_register_device_token()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/notifications/tokens', [
                'token' => 'fcm-dummy-token-123',
                'platform' => 'android',
            ])
            ->assertStatus(200);

        $this->assertDatabaseHas('device_tokens', [
            'user_id' => $user->id,
            'token' => 'fcm-dummy-token-123',
            'platform' => 'android',
            'is_active' => true,
        ]);
    }

    public function test_user_can_retrieve_and_update_preferences()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        // Check defaults are created
        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/notifications/preferences');

        $response->assertStatus(200)
            ->assertJson([
                'goals' => true,
                'match_start' => true,
                'match_end' => true,
                'news' => true,
                'promotions' => false,
            ]);

        // Update preferences
        $this->actingAs($user, 'sanctum')
            ->putJson('/api/v1/notifications/preferences', [
                'goals' => false,
                'match_start' => true,
                'match_end' => false,
                'news' => false,
                'promotions' => true,
            ])
            ->assertStatus(200);

        $this->assertDatabaseHas('notification_preferences', [
            'user_id' => $user->id,
            'goals' => false,
            'match_start' => true,
            'match_end' => false,
            'news' => false,
            'promotions' => true,
        ]);
    }
}
