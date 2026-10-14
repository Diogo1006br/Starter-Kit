<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use RuntimeException;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Safety net: RefreshDatabase wipes the database. Never let a test run
        // against anything but SQLite or a database named *_test.
        $default = config('database.default');
        $database = (string) config("database.connections.{$default}.database");

        if ($default !== 'sqlite' && ! str_ends_with($database, '_test')) {
            throw new RuntimeException(
                "Refusing to run tests against non-test database [{$database}]. Use `make test-pg`."
            );
        }
    }
}
