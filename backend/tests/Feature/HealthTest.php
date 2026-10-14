<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Redis;
use Tests\TestCase;

class HealthTest extends TestCase
{
    public function test_health_reports_ok_when_services_respond(): void
    {
        Redis::shouldReceive('connection->ping')->once()->andReturn(true);

        $this->getJson('/api/v1/health')
            ->assertOk()
            ->assertJson([
                'success' => true,
                'data' => ['status' => 'ok', 'checks' => ['database' => true, 'redis' => true]],
            ]);
    }

    public function test_health_reports_degraded_when_redis_fails(): void
    {
        Redis::shouldReceive('connection->ping')->once()->andThrow(new \RuntimeException('down'));

        $this->getJson('/api/v1/health')
            ->assertStatus(503)
            ->assertJsonPath('data.checks.redis', false);
    }

    public function test_user_endpoint_requires_authentication_and_uses_error_envelope(): void
    {
        $this->getJson('/api/v1/user')
            ->assertStatus(401)
            ->assertExactJson(['success' => false, 'message' => 'Unauthenticated.', 'errors' => null]);
    }

    public function test_unknown_api_route_uses_error_envelope(): void
    {
        $this->getJson('/api/v1/nope')
            ->assertStatus(404)
            ->assertJsonPath('success', false);
    }
}
