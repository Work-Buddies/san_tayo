<?php

namespace App\Repositories;

use App\Http\Services\Location\LandmarkProcess;

class LandmarkRepository implements LandmarkRepoInterface
{
  protected $landmark_process;

  public function __construct(LandmarkProcess $landmark_process)
  {
    $this->landmark_process = $landmark_process;
  }

  public function index()
  {
    return $this->landmark_process->get_landmarks();
  }

  public function store($params)
  {
    return $this->landmark_process->create_landmark($params);
  }

  public function update($id, $params)
  {
    return $this->landmark_process->update_landmark($id, $params);
  }
}
