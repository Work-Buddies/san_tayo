<?php

namespace App\Repositories;

interface AuthRepoInterface
{
  public function register($params);
  public function login($params);
  public function logout($account);
  public function me($account);
}
