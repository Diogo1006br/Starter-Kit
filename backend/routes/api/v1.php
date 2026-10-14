<?php

use App\Http\Controllers\Api\V1\HealthController;
use App\Http\Responses\ApiResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/health', HealthController::class)->name('health');

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return ApiResponse::success($request->user());
})->name('user');
