<?php

namespace App\Repositories;

use App\Libraries\api;
use App\Libraries\SharedFunction;

class LookupRepository implements LookupRepoInterface
{
  public function barangays()
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];
    $rs = SharedFunction::api_success('Barangays retrieved.', api::get_barangays());
    return $rs;
  }

  public function food_types()
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];
    $rs = SharedFunction::api_success('Food types retrieved.', api::get_food_types());
    return $rs;
  }

  public function listing_statuses()
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];
    $rs = SharedFunction::api_success('Listing statuses retrieved.', api::get_listing_statuses());
    return $rs;
  }

  /**
   * @uses: Return per-table last_update stamps for client cache sync
   * @author: Kai Yaneza
   * Date: 2026-09-19
   */
  public function last_table_updates()
  {
    $rs   = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];
    $rows = api::get_last_table_updates();
    $data = [];

    foreach ($rows as $row) {
      $data[] = [
        'table_name'  => $row->table_name,
        'last_update' => $row->last_update?->toIso8601String(),
      ];
    }

    $rs = SharedFunction::api_success('Table updates retrieved.', $data);
    return $rs;
  }
}
