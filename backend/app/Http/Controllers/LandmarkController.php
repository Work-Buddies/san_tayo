<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Repositories\LandmarkRepoInterface;

class LandmarkController extends Controller
{
  public function index(LandmarkRepoInterface $repo)
  {
    return response()->json($repo->index());
  }

  public function store(Request $request, LandmarkRepoInterface $repo)
  {
    return response()->json($repo->store($request->all()));
  }

  public function update(Request $request, LandmarkRepoInterface $repo, $id)
  {
    return response()->json($repo->update($id, $request->all()));
  }
}
