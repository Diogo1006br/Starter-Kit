<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Throwable;

/**
 * Reports whether the API can reach its backing services. Used by the
 * frontend smoke screen and by `make health` to prove the Docker network
 * (backend -> postgres, backend -> redis) is wired correctly.
 */
class HealthController
{
    public function __invoke(): JsonResponse
    {
        $checks = [
            'database' => $this->check(fn () => DB::select('select 1')),
            'redis' => $this->check(fn () => Redis::connection()->ping()),
        ];

        $healthy = ! in_array(false, $checks, true);

        return ApiResponse::success([
            'app' => config('app.name'),
            'status' => $healthy ? 'ok' : 'degraded',
            'checks' => $checks,
        ], $healthy ? 200 : 503);
    }

    private function check(callable $probe): bool
    {
        try {
            $probe();

            return true;
        } catch (Throwable) {
            return false;
        }
    }
}
