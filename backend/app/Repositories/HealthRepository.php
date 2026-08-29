<?php

namespace App\Repositories;

use App\Libraries\api;

class HealthRepository implements HealthRepoInterface
{
  /**
   * @uses: Return health check data for the API
   * @author: Kai Yaneza
   * Date: 2026-08-28
   */
  public function ping()
  {
    $rs = [
      'code'  => 0,
      'title' => 'Ooops!',
      'msg'   => 'Something went wrong.',
    ];

    $rs = api::ping();

    return $rs;
  }
}
