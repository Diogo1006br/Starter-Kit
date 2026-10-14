<?php

use Illuminate\Support\Facades\Route;

// The backend is API-only; the SPA is served by the frontend service.
Route::get('/', fn () => response()->json(['name' => config('app.name'), 'api' => url('/api/v1')]));
