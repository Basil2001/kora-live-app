<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register()
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'access_token',
                     'token_type',
                     'user' => ['id', 'name', 'email']
                 ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
        ]);
    }

    public function test_user_can_login()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'jane@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'access_token',
                     'token_type',
                     'user'
                 ]);
    }

    public function test_user_cannot_login_with_invalid_credentials()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'jane@example.com',
            'password' => 'wrong_password',
        ]);

        $response->assertStatus(401)
                 ->assertJson([
                     'message' => 'Invalid login details'
                 ]);
    }

    public function test_authenticated_user_can_get_profile()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->actingAs($user, 'sanctum')
                         ->getJson('/api/v1/profile');

        $response->assertStatus(200)
                 ->assertJson([
                     'email' => 'jane@example.com',
                 ]);
    }

    public function test_user_can_logout()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->actingAs($user, 'sanctum')
                         ->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
                 ->assertJson([
                     'message' => 'Logged out successfully'
                 ]);
    }

    public function test_user_can_update_profile()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson('/api/v1/profile', [
                'name' => 'Updated Name',
                'email' => 'updated@example.com',
                'avatar_url' => 'http://example.com/avatar.jpg'
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('user.name', 'Updated Name')
            ->assertJsonPath('user.email', 'updated@example.com')
            ->assertJsonPath('user.avatar_url', 'http://example.com/avatar.jpg');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Updated Name',
            'email' => 'updated@example.com',
            'avatar_url' => 'http://example.com/avatar.jpg'
        ]);
    }

    public function test_user_can_change_password()
    {
        $user = User::create([
            'name' => 'Jane Doe',
            'email' => 'jane@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->putJson('/api/v1/profile/password', [
                'current_password' => 'password123',
                'new_password' => 'newpassword123',
                'new_password_confirmation' => 'newpassword123'
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Password changed successfully'
            ]);
    }
}
