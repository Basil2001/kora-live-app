<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('matches', function (Blueprint $table) {
            $table->id();
            $table->foreignId('home_team_id')->constrained('teams')->onDelete('cascade');
            $table->foreignId('away_team_id')->constrained('teams')->onDelete('cascade');
            $table->string('status'); // scheduled, live, finished
            $table->integer('score_home')->default(0);
            $table->integer('score_away')->default(0);
            $table->integer('current_minute')->default(0);
            $table->dateTime('start_time');
            $table->string('competition_name');
            $table->string('round')->nullable();
            $table->string('referee')->nullable();
            $table->string('venue_name')->nullable();
            $table->timestamps();

            $table->index(['status', 'start_time']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('matches');
    }
};
