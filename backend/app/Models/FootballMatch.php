<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FootballMatch extends Model
{
    use HasFactory;

    protected $table = 'matches';

    protected $dispatchesEvents = [
        'saved' => \App\Events\MatchUpdated::class,
    ];

    protected $fillable = [
        'home_team_id',
        'away_team_id',
        'status',
        'score_home',
        'score_away',
        'current_minute',
        'start_time',
        'competition_name',
        'round',
        'referee',
        'venue_name',
    ];

    protected $casts = [
        'start_time' => 'datetime',
    ];

    public function homeTeam()
    {
        return $this->belongsTo(Team::class, 'home_team_id');
    }

    public function awayTeam()
    {
        return $this->belongsTo(Team::class, 'away_team_id');
    }

    public function events()
    {
        return $this->hasMany(MatchEvent::class, 'match_id')->orderBy('minute', 'asc');
    }

    public function highlights()
    {
        return $this->hasMany(Highlight::class, 'match_id');
    }
}
