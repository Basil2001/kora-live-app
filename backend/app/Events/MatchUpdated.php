<?php

namespace App\Events;

use App\Models\FootballMatch;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MatchUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $match;

    /**
     * Create a new event instance.
     */
    public function __construct(FootballMatch $match)
    {
        // Eager load relationships to make sure they are available in broadcast
        $this->match = $match->loadMissing(['homeTeam', 'awayTeam']);
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('matches')
        ];
    }

    /**
     * Get the data to broadcast.
     */
    public function broadcastWith(): array
    {
        return [
            'id' => $this->match->id,
            'home_team_id' => $this->match->home_team_id,
            'home_team_name' => $this->match->homeTeam->name,
            'home_team' => [
                'id' => $this->match->home_team_id,
                'name' => $this->match->homeTeam->name,
                'logo_url' => $this->match->homeTeam->logo_url,
            ],
            'away_team_id' => $this->match->away_team_id,
            'away_team_name' => $this->match->awayTeam->name,
            'away_team' => [
                'id' => $this->match->away_team_id,
                'name' => $this->match->awayTeam->name,
                'logo_url' => $this->match->awayTeam->logo_url,
            ],
            'score_home' => $this->match->score_home,
            'score_away' => $this->match->score_away,
            'status' => $this->match->status,
            'current_minute' => $this->match->current_minute,
            'start_time' => $this->match->start_time ? $this->match->start_time->toIso8601String() : '',
            'competition_name' => $this->match->competition_name,
        ];
    }
}
