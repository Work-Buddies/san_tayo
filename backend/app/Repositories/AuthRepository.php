<?php

namespace App\Repositories;

use App\Http\Services\Auth\AuthProcess;

class AuthRepository implements AuthRepoInterface
{
  protected $auth_process;

  public function __construct(AuthProcess $auth_process)
  {
    $this->auth_process = $auth_process;
  }

  public function register($params)
  {
    return $this->auth_process->register($params);
  }

  public function login($params)
  {
    return $this->auth_process->login($params);
  }

  public function logout($account)
  {
    return $this->auth_process->logout($account);
  }

  public function me($account)
  {
    return $this->auth_process->me($account);
  }
}
