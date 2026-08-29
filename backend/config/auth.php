<?php

use App\Models\Account\AccountModel;

return [

    'defaults' => [
        'guard'     => env('AUTH_GUARD', 'api'),
        'passwords' => env('AUTH_PASSWORD_BROKER', 'accounts'),
    ],

    'guards' => [
        'web' => [
            'driver'   => 'session',
            'provider' => 'accounts',
        ],
        'api' => [
            'driver'   => 'sanctum',
            'provider' => 'accounts',
        ],
    ],

    'providers' => [
        'accounts' => [
            'driver' => 'eloquent',
            'model'  => AccountModel::class,
        ],
    ],

    'passwords' => [
        'accounts' => [
            'provider' => 'accounts',
            'table'    => env('AUTH_PASSWORD_RESET_TOKEN_TABLE', 'password_reset_tokens'),
            'expire'   => 60,
            'throttle' => 60,
        ],
    ],

    'password_timeout' => env('AUTH_PASSWORD_TIMEOUT', 10800),

];
