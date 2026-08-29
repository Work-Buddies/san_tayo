<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Repositories\AccountRepoInterface;

class AccountController extends Controller
{
  public function upgrade_business(Request $request, AccountRepoInterface $repo)
  {
    return response()->json($repo->upgrade_to_business($request->user()));
  }
}
