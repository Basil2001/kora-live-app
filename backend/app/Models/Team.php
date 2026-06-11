<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Team extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'short_name',
        'logo_url',
        'venue_name',
        'venue_city',
        'founded',
        'coach_name',
    ];

    public function homeMatches()
    {
        return $this->hasMany(FootballMatch::class, 'home_team_id');
    }

    public function awayMatches()
    {
        return $this->hasMany(FootballMatch::class, 'away_team_id');
    }

    public function standing()
    {
        return $this->hasOne(Standing::class);
    }
}
