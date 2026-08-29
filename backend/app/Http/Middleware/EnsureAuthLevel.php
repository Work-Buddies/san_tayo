<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Libraries\SharedFunction;

class EnsureAuthLevel
{
  public function handle(Request $request, Closure $next, ...$levels)
  {
    $account = $request->user();
    $level   = $account?->auth_level?->level;

    if (empty($level) || !in_array($level, $levels)) {
      return response()->json(
        SharedFunction::api_error('You are not allowed to perform this action.'),
        403
      );
    }

    return $next($request);
  }
}
