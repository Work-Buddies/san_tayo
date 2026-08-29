<?php

namespace App\Repositories;

use App\Http\Services\Account\AccountProcess;

class AccountRepository implements AccountRepoInterface
{
  protected $account_process;

  public function __construct(AccountProcess $account_process)
  {
    $this->account_process = $account_process;
  }

  public function upgrade_to_business($account)
  {
    return $this->account_process->upgrade_to_business($account);
  }
}
