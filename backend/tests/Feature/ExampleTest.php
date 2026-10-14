<?php

namespace Tests\Feature;

use Tests\TestCase;

class ExampleTest extends TestCase
{
    public function test_root_returns_a_successful_json_response(): void
    {
        $this->getJson('/')->assertOk()->assertJsonStructure(['name', 'api']);
    }
}
