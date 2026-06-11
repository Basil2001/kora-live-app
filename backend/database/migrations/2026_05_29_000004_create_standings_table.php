<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('standings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('team_id')->constrained('teams')->onDelete('cascade');
            $table->string('competition_name');
            $table->integer('rank');
            $table->integer('played');
            $table->integer('won');
            $table->integer('drawn');
            $table->integer('lost');
            $table->integer('goals_for');
            $table->integer('goals_against');
            $table->integer('goals_diff');
            $table->integer('points');
            $table->timestamps();

            $table->index(['competition_name', 'rank']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('standings');
    }
};
