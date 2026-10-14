<?php

return [
    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    // Comma-separated origins from CORS_ALLOWED_ORIGINS. Empty = none allowed.
    'allowed_origins' => array_values(array_filter(
        array_map('trim', explode(',', (string) env('CORS_ALLOWED_ORIGINS', '')))
    )),

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // Bearer-token API: no cookies cross origins.
    'supports_credentials' => false,
];
