<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Libraries\SharedFunction;

class VerifyClientKey
{
  public function handle(Request $request, Closure $next)
  {
    $client_key = $request->header('X-Client-Key');
    $expected   = env('CLIENT_API_KEY');

    if (empty($expected) || $client_key != $expected) {
      return response()->json(
        SharedFunction::api_error('Unauthorized client.', 'Access Denied'),
        403
      );
    }

    return $next($request);
  }
}
