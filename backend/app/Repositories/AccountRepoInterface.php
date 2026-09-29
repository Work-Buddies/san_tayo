<?php

namespace App\Repositories;

interface AccountRepoInterface
{
  public function upgrade_to_business($account);
  public function update_username($account, $params);
  public function change_password($account, $params);
}
