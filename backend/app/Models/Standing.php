<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Standing extends Model
{
    use HasFactory;

    protected $fillable = [
        'team_id',
        'competition_name',
        'rank',
        'played',
        'won',
        'drawn',
        'lost',
        'goals_for',
        'goals_against',
        'goals_diff',
        'points',
    ];

    public function team()
    {
        return $this->belongsTo(Team::class);
    }
}
