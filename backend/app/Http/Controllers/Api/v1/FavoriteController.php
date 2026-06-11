<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Team;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $favorites = $request->user()->favoriteTeams()->get();
        return response()->json($favorites);
    }

    public function toggle(Request $request)
    {
        $request->validate([
            'team_id' => 'required|exists:teams,id',
        ]);

        $user = $request->user();
        $teamId = $request->input('team_id');

        // Check if already favorited
        $isFavorited = $user->favoriteTeams()->where('team_id', $teamId)->exists();

        if ($isFavorited) {
            $user->favoriteTeams()->detach($teamId);
            $status = 'detached';
        } else {
            $user->favoriteTeams()->attach($teamId);
            $status = 'attached';
        }

        return response()->json([
            'status' => 'success',
            'action' => $status,
            'team_id' => $teamId,
        ]);
    }
}
