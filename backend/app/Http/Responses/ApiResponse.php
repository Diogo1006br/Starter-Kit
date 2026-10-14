<?php

namespace App\Http\Responses;

use Illuminate\Http\JsonResponse;

/**
 * Single response envelope for the whole API:
 *   success: { success: true,  message: string|null, data: mixed }
 *   error:   { success: false, message: string, errors: mixed|null }
 */
final class ApiResponse
{
    public static function success(mixed $data = null, int $status = 200, ?string $message = null): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $status);
    }

    public static function error(string $message, mixed $errors = null, int $status = 422): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
        ], $status);
    }
}
