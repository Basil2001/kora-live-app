<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationPreference extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'goals',
        'match_start',
        'match_end',
        'news',
        'promotions',
    ];

    protected $casts = [
        'goals' => 'boolean',
        'match_start' => 'boolean',
        'match_end' => 'boolean',
        'news' => 'boolean',
        'promotions' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
