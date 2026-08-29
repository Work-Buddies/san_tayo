<?php

namespace App\Http\Controllers;

use App\Repositories\LookupRepoInterface;

class LookupController extends Controller
{
  public function barangays(LookupRepoInterface $repo)
  {
    return response()->json($repo->barangays());
  }

  public function food_types(LookupRepoInterface $repo)
  {
    return response()->json($repo->food_types());
  }

  public function listing_statuses(LookupRepoInterface $repo)
  {
    return response()->json($repo->listing_statuses());
  }
}
