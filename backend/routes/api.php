<?php

use Illuminate\Support\Facades\Route;

// API routes are versioned: each version lives in routes/api/{version}.php.
Route::prefix('v1')
    ->name('api.v1.')
    ->group(base_path('routes/api/v1.php'));
