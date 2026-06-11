<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MatchEvent extends Model
{
    use HasFactory;

    protected $fillable = [
        'match_id',
        'team_id',
        'type',
        'minute',
        'extra_minute',
        'player_name',
        'detail_player_name',
        'detail',
        'video_clip_url',
    ];

    public function match()
    {
        return $this->belongsTo(FootballMatch::class);
    }

    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}
