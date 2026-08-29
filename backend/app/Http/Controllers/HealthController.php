<?php

namespace App\Http\Controllers;

use App\Repositories\HealthRepoInterface;

class HealthController extends Controller
{
  /**
   * @uses: Health check endpoint — delegates to HealthRepository
   * @author: Kai Yaneza
   * Date: 2026-08-28
   */
  public function ping(HealthRepoInterface $health_repo)
  {
    $rs = $health_repo->ping();

    return response()->json($rs);
  }
}
