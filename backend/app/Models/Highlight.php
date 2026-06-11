<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Highlight extends Model
{
    use HasFactory;

    protected $fillable = [
        'match_id',
        'title',
        'title_ar',
        'video_url',
        'thumbnail_url',
        'access_level',
    ];

    public function match()
    {
        return $this->belongsTo(FootballMatch::class);
    }
}
