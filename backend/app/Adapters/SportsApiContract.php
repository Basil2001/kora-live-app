<?php

namespace App\Adapters;

interface SportsApiContract
{
    /**
     * Fetch and sync matches for a specific date.
     *
     * @param string $date YYYY-MM-DD
     * @return array Sync statistics or list of synced matches.
     */
    public function syncMatchesByDate(string $date): array;

    /**
     * Fetch and sync standings for a specific competition/league.
     *
     * @param string $competitionName
     * @return array Standings details.
     */
    public function syncStandings(string $competitionName): array;

    /**
     * Fetch and sync details of a team.
     *
     * @param int $teamId
     * @return array Team details.
     */
    public function syncTeamDetails(int $teamId): array;
}
