<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('match_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('match_id')->constrained('matches')->onDelete('cascade');
            $table->foreignId('team_id')->nullable()->constrained('teams')->onDelete('cascade');
            $table->string('type'); // goal, card, substitution, var
            $table->integer('minute');
            $table->integer('extra_minute')->nullable();
            $table->string('player_name');
            $table->string('detail_player_name')->nullable(); // Assist player or substituted player
            $table->string('detail')->nullable(); // e.g. "Yellow Card", "Own Goal", etc.
            $table->string('video_clip_url')->nullable();
            $table->timestamps();

            $table->index('match_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('match_events');
    }
};
