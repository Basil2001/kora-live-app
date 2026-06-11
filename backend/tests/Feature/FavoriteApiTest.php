<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Team;
use Illuminate\Foundation\Testing\RefreshDatabase;

class FavoriteApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_toggle_favorites()
    {
        $response = $this->postJson('/api/v1/favorites/toggle', [
            'team_id' => 1,
        ]);

        $response->assertStatus(401);
    }

    public function test_user_can_toggle_team_favorite_status()
    {
        $user = User::create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => bcrypt('password123'),
        ]);

        $team = Team::create([
            'name' => 'Real Madrid',
            'short_name' => 'RMA',
            'logo_url' => 'https://example.com/logo.png',
        ]);

        // Toggle ON (Attach)
        $response = $this->actingAs($user, 'sanctum')
                         ->postJson('/api/v1/favorites/toggle', [
                             'team_id' => $team->id,
                         ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'status' => 'success',
                     'action' => 'attached',
                     'team_id' => $team->id,
                 ]);

        $this->assertDatabaseHas('favorite_teams', [
            'user_id' => $user->id,
            'team_id' => $team->id,
        ]);

        // Toggle OFF (Detach)
        $response = $this->actingAs($user, 'sanctum')
                         ->postJson('/api/v1/favorites/toggle', [
                             'team_id' => $team->id,
                         ]);

        $response->assertStatus(200)
                 ->assertJson([
                     'status' => 'success',
                     'action' => 'detached',
                     'team_id' => $team->id,
                 ]);

        $this->assertDatabaseMissing('favorite_teams', [
            'user_id' => $user->id,
            'team_id' => $team->id,
        ]);
    }

    public function test_user_can_list_favorite_teams()
    {
        $user = User::create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'password' => bcrypt('password123'),
        ]);

        $team = Team::create([
            'name' => 'Real Madrid',
            'short_name' => 'RMA',
            'logo_url' => 'https://example.com/logo.png',
        ]);

        $user->favoriteTeams()->attach($team->id);

        $response = $this->actingAs($user, 'sanctum')
                         ->getJson('/api/v1/favorites');

        $response->assertStatus(200)
                 ->assertJsonCount(1)
                 ->assertJsonFragment([
                     'name' => 'Real Madrid',
                 ]);
    }
}
