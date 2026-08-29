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
}
