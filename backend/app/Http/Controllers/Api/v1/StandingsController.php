<?php

namespace App\Http\Controllers\Api\v1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Services\FootballApiService;

class StandingsController extends Controller
{
    protected FootballApiService $footballService;

    public function __construct(FootballApiService $footballService)
    {
        $this->footballService = $footballService;
    }

    /**
     * GET /api/v1/standings?competition=La Liga
     */
    public function index(Request $request)
    {
        $competition = $request->query('competition', 'La Liga');

        $standings = $this->footballService->getStandings($competition);

        return response()->json([
            'competition' => $competition,
            'count'       => count($standings),
            'standings'   => $standings,
        ]);
    }

    /**
     * GET /api/v1/competitions — List of supported competitions.
     */
    public function competitions()
    {
        return response()->json([
            'competitions' => $this->footballService->getCompetitions(),
        ]);
    }
}
