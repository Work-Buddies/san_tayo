<?php

namespace App\Repositories;

interface LookupRepoInterface
{
  public function barangays();
  public function food_types();
  public function listing_statuses();
  public function last_table_updates();
}
