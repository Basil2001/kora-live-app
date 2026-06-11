<?php

namespace App\Filament\Resources;

use App\Models\FootballMatch;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class MatchResource extends Resource
{
    protected static ?string $model = FootballMatch::class;

    protected static ?string $navigationIcon = 'heroicon-o-calendar';

    protected static ?string $navigationGroup = 'Football Operations';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Select::make('home_team_id')
                    ->relationship('homeTeam', 'name')
                    ->required()
                    ->searchable(),

                Select::make('away_team_id')
                    ->relationship('awayTeam', 'name')
                    ->required()
                    ->searchable(),

                Select::make('status')
                    ->options([
                        'scheduled' => 'Scheduled',
                        'live' => 'Live',
                        'finished' => 'Finished',
                    ])
                    ->required(),

                TextInput::make('score_home')
                    ->numeric()
                    ->default(0),

                TextInput::make('score_away')
                    ->numeric()
                    ->default(0),

                TextInput::make('current_minute')
                    ->numeric()
                    ->default(0),

                DateTimePicker::make('start_time')
                    ->required(),

                TextInput::make('competition_name')
                    ->required(),

                TextInput::make('referee'),
                TextInput::make('venue_name'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('competition_name')->sortable()->searchable(),
                TextColumn::make('homeTeam.name')->label('Home Team')->searchable(),
                TextColumn::make('score_home')->label('Score H'),
                TextColumn::make('score_away')->label('Score A'),
                TextColumn::make('awayTeam.name')->label('Away Team')->searchable(),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'live' => 'danger',
                        'finished' => 'success',
                        default => 'warning',
                    }),
                TextColumn::make('start_time')->dateTime()->sortable(),
            ])
            ->filters([
                // Filters by league / status
            ])
            ->actions([
                EditAction::make(),
            ]);
    }
}
