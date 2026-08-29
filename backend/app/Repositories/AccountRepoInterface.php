<?php

namespace App\Repositories;

interface AccountRepoInterface
{
  public function upgrade_to_business($account);
}
