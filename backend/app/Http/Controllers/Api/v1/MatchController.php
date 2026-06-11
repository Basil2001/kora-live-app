<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\FootballMatch;
use App\Services\FootballApiService;
use Illuminate\Support\Carbon;

class MatchController extends Controller
{
    protected FootballApiService $footballService;

    public function __construct(FootballApiService $footballService)
    {
        $this->footballService = $footballService;
    }

    /**
     * GET /api/v1/matches?date=YYYY-MM-DD&status=live|scheduled|finished
     */
    public function index(Request $request)
    {
        $dateInput = $request->query('date', Carbon::today()->toDateString());
        $status = $request->query('status'); // live, scheduled, finished

        $matches = $this->footballService->getMatchesByDate($dateInput, $status);

        return response()->json([
            'date'    => $dateInput,
            'count'   => count($matches),
            'matches' => $matches,
        ]);
    }

    /**
     * GET /api/v1/matches/live — Get only live matches.
     */
    public function live()
    {
        $matches = $this->footballService->getLiveMatches();

        return response()->json([
            'count'   => count($matches),
            'matches' => $matches,
        ]);
    }

    /**
     * GET /api/v1/matches/{id} — Match details with events & highlights.
     */
    public function show($id)
    {
        $match = $this->footballService->getMatchDetails((int) $id);

        if (!$match) {
            return response()->json(['message' => 'Match not found'], 404);
        }

        return response()->json($match);
    }

    /**
     * GET /api/v1/matches/{id}/stream — Secured streaming link (auth required).
     */
    public function streamInfo($id)
    {
        $match = FootballMatch::findOrFail($id);

        return response()->json([
            'match_id'         => $match->id,
            'stream_available' => true,
            'stream_provider'  => 'Kora Live Premium',
            'stream_url'       => 'https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8',
            'geo_restriction'  => [
                'allowed_countries' => ['EG', 'SA', 'AE', 'QA', 'JO'],
                'current_country'   => 'EG',
            ],
            'tokenized_key' => bin2hex(random_bytes(16)),
        ]);
    }

    /**
     * GET /api/v1/competitions — List available leagues.
     */
    public function competitions()
    {
        return response()->json([
            'competitions' => $this->footballService->getCompetitions(),
        ]);
    }
}
