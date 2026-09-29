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

  public function update_username(Request $request, AccountRepoInterface $repo)
  {
    return response()->json($repo->update_username($request->user(), $request->all()));
  }

  public function change_password(Request $request, AccountRepoInterface $repo)
  {
    return response()->json($repo->change_password($request->user(), $request->all()));
  }
}
