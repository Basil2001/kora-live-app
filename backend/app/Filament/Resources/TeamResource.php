<?php

namespace App\Filament\Resources;

use App\Models\Team;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class TeamResource extends Resource
{
    protected static ?string $model = Team::class;

    protected static ?string $navigationIcon = 'heroicon-o-flag';

    protected static ?string $navigationGroup = 'Football Operations';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                TextInput::make('short_name')
                    ->maxLength(50),
                TextInput::make('logo_url')
                    ->url()
                    ->maxLength(2048),
                TextInput::make('venue_name')
                    ->maxLength(255),
                TextInput::make('venue_city')
                    ->maxLength(255),
                TextInput::make('founded')
                    ->numeric(),
                TextInput::make('coach_name')
                    ->maxLength(255),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->sortable()
                    ->searchable(),
                TextColumn::make('short_name')
                    ->sortable()
                    ->searchable(),
                TextColumn::make('venue_name')
                    ->searchable(),
                TextColumn::make('coach_name')
                    ->searchable(),
                TextColumn::make('founded')
                    ->sortable(),
            ])
            ->actions([
                EditAction::make(),
            ]);
    }
}
