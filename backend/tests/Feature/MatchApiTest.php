<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Team;
use App\Models\FootballMatch;
use Illuminate\Foundation\Testing\RefreshDatabase;

class MatchApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_matches_can_be_retrieved_and_auto_synced()
    {
        // Calling index should trigger the MockSportsApiAdapter sync and create matches
        $response = $this->getJson('/api/v1/matches?date=2026-06-03');

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'date',
                     'matches' => [
                         '*' => [
                             'id',
                             'status',
                             'competition_name',
                             'home_team',
                             'away_team',
                         ]
                     ]
                 ]);

        $this->assertDatabaseCount('matches', 3);
    }

    public function test_match_detail_can_be_retrieved()
    {
        // Seed database by hitting matches first
        $this->getJson('/api/v1/matches?date=2026-06-03');
        $match = FootballMatch::first();

        $response = $this->getJson('/api/v1/matches/' . $match->id);

        $response->assertStatus(200)
                 ->assertJson([
                     'id' => $match->id,
                 ])
                 ->assertJsonStructure([
                     'home_team',
                     'away_team',
                     'events',
                 ]);
    }

    public function test_guest_cannot_access_stream_info()
    {
        // Seed matches
        $this->getJson('/api/v1/matches?date=2026-06-03');
        $match = FootballMatch::first();

        $response = $this->getJson('/api/v1/matches/' . $match->id . '/stream');

        $response->assertStatus(401);
    }

    public function test_user_can_access_stream_info()
    {
        $user = User::create([
            'name' => 'Subscriber',
            'email' => 'sub@example.com',
            'password' => bcrypt('password123'),
        ]);

        // Seed matches
        $this->getJson('/api/v1/matches?date=2026-06-03');
        $match = FootballMatch::first();

        $response = $this->actingAs($user, 'sanctum')
                         ->getJson('/api/v1/matches/' . $match->id . '/stream');

        $response->assertStatus(200)
                 ->assertJson([
                     'match_id' => $match->id,
                     'stream_available' => true,
                     'stream_provider' => 'Kora Live Premium',
                 ])
                 ->assertJsonStructure([
                     'stream_url',
                     'tokenized_key',
                 ]);
    }
}
