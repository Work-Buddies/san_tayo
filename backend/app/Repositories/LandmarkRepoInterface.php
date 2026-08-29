<?php

namespace App\Repositories;

interface LandmarkRepoInterface
{
  public function index();
  public function store($params);
  public function update($id, $params);
}
