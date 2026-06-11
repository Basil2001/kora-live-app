<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Team;
use App\Models\FootballMatch;
use App\Models\Comment;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CommentApiTest extends TestCase
{
    use RefreshDatabase;

    private $user;
    private $match;

    protected function setUp(): void
    {
        parent::setUp();

        $this->user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
        ]);

        $homeTeam = Team::create([
            'name' => 'Real Madrid',
            'logo_url' => 'https://example.com/logo.png',
        ]);

        $awayTeam = Team::create([
            'name' => 'Barcelona',
            'logo_url' => 'https://example.com/logo2.png',
        ]);

        $this->match = FootballMatch::create([
            'home_team_id' => $homeTeam->id,
            'away_team_id' => $awayTeam->id,
            'status' => 'live',
            'score_home' => 2,
            'score_away' => 1,
            'current_minute' => 75,
            'start_time' => now(),
            'competition_name' => 'La Liga',
        ]);
    }

    public function test_guest_can_view_comments()
    {
        Comment::create([
            'user_id' => $this->user->id,
            'match_id' => $this->match->id,
            'body' => 'Great match!',
        ]);

        $response = $this->getJson("/api/v1/matches/{$this->match->id}/comments");

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'comments' => [
                         '*' => [
                             'id',
                             'body',
                             'likes_count',
                             'user' => [
                                 'id',
                                 'name',
                                 'avatar_url',
                             ]
                         ]
                     ],
                     'total',
                     'current_page',
                     'last_page'
                 ]);
    }

    public function test_authenticated_user_can_post_comment()
    {
        $response = $this->actingAs($this->user, 'sanctum')
                         ->postJson("/api/v1/matches/{$this->match->id}/comments", [
                             'body' => 'Hala Madrid!',
                         ]);

        $response->assertStatus(201)
                 ->assertJson([
                     'message' => 'Comment posted successfully.',
                 ])
                 ->assertJsonStructure([
                     'comment' => [
                         'id',
                         'body',
                         'user' => [
                             'id',
                             'name',
                         ]
                     ]
                 ]);

        $this->assertDatabaseHas('comments', [
            'match_id' => $this->match->id,
            'user_id' => $this->user->id,
            'body' => 'Hala Madrid!',
        ]);
    }

    public function test_cannot_post_comment_without_body()
    {
        $response = $this->actingAs($this->user, 'sanctum')
                         ->postJson("/api/v1/matches/{$this->match->id}/comments", [
                             'body' => '',
                         ]);

        $response->assertStatus(422);
    }

    public function test_user_can_like_comment()
    {
        $comment = Comment::create([
            'user_id' => $this->user->id,
            'match_id' => $this->match->id,
            'body' => 'Like me',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
                         ->postJson("/api/v1/matches/{$this->match->id}/comments/{$comment->id}/like");

        $response->assertStatus(200)
                 ->assertJson([
                     'likes_count' => 1,
                 ]);

        $this->assertEquals(1, $comment->fresh()->likes_count);
    }

    public function test_user_can_delete_own_comment()
    {
        $comment = Comment::create([
            'user_id' => $this->user->id,
            'match_id' => $this->match->id,
            'body' => 'Delete me',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
                         ->deleteJson("/api/v1/matches/{$this->match->id}/comments/{$comment->id}");

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Comment deleted.',
                 ]);

        $this->assertDatabaseMissing('comments', [
            'id' => $comment->id,
        ]);
    }

    public function test_user_cannot_delete_other_comment()
    {
        $otherUser = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $comment = Comment::create([
            'user_id' => $otherUser->id,
            'match_id' => $this->match->id,
            'body' => 'Jane\'s comment',
        ]);

        $response = $this->actingAs($this->user, 'sanctum')
                         ->deleteJson("/api/v1/matches/{$this->match->id}/comments/{$comment->id}");

        $response->assertStatus(404);
    }
}
