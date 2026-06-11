<?php

namespace App\Filament\Widgets;

use App\Models\FootballMatch;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class LiveMatchesWidget extends BaseWidget
{
    protected static ?int $sort = 2;

    protected int | string | array $columnSpan = 'full';

    protected static ?string $heading = '🔴 Live Matches Now';

    protected static ?string $pollingInterval = '15s';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                FootballMatch::query()
                    ->where('status', 'live')
                    ->with(['homeTeam', 'awayTeam'])
                    ->orderBy('start_time', 'desc')
            )
            ->columns([
                TextColumn::make('competition_name')
                    ->label('Competition')
                    ->badge()
                    ->color('info')
                    ->sortable(),

                TextColumn::make('homeTeam.name')
                    ->label('Home')
                    ->searchable()
                    ->weight('bold'),

                TextColumn::make('score_home')
                    ->label('H')
                    ->alignCenter()
                    ->size('lg')
                    ->weight('bold')
                    ->color('success'),

                TextColumn::make('score_away')
                    ->label('A')
                    ->alignCenter()
                    ->size('lg')
                    ->weight('bold')
                    ->color('success'),

                TextColumn::make('awayTeam.name')
                    ->label('Away')
                    ->searchable()
                    ->weight('bold'),

                TextColumn::make('current_minute')
                    ->label('Minute')
                    ->suffix("'")
                    ->badge()
                    ->color('danger'),

                TextColumn::make('venue_name')
                    ->label('Venue')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->emptyStateHeading('No Live Matches')
            ->emptyStateDescription('There are no matches being played right now.')
            ->emptyStateIcon('heroicon-o-tv')
            ->paginated(false);
    }
}
