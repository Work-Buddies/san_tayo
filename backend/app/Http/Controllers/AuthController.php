<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Repositories\AuthRepoInterface;

class AuthController extends Controller
{
  public function register(Request $request, AuthRepoInterface $repo)
  {
    return response()->json($repo->register($request->all()));
  }

  public function login(Request $request, AuthRepoInterface $repo)
  {
    return response()->json($repo->login($request->all()));
  }

  public function logout(Request $request, AuthRepoInterface $repo)
  {
    return response()->json($repo->logout($request->user()));
  }

  public function me(Request $request, AuthRepoInterface $repo)
  {
    return response()->json($repo->me($request->user()));
  }
}
