<?php

namespace App\Http\Services\Auth;

use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Libraries\api;
use App\Libraries\SharedFunction;
use App\Models\Account\AccountModel;
use App\Models\Auth\AuthLevelModel;

class AuthProcess
{
  /**
   * @uses: Register a new account with user auth level
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function register($params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $validation = SharedFunction::validate_account_register($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    if (api::email_exists($params['email'])) {
      $rs['msg'] = 'Email is already registered.';
      return $rs;
    }

    if (api::username_exists($params['username'])) {
      $rs['msg'] = 'Username is already taken.';
      return $rs;
    }

    $auth_level_id = api::get_auth_level_id(AuthLevelModel::LEVEL_USER);
    if (empty($auth_level_id)) {
      $rs['msg'] = 'User auth level not found.';
      return $rs;
    }

    $account = AccountModel::create([
      'email'         => $params['email'],
      'password_hash' => Hash::make($params['password']),
      'username'      => $params['username'],
      'auth_level_id' => $auth_level_id,
    ]);

    $account->refresh();

    $account->load('auth_level');
    $token = $account->createToken('auth_token')->plainTextToken;

    $rs = SharedFunction::api_success('Registration successful.', [
      'account' => api::format_account($account),
      'token'   => $token,
    ]);

    return $rs;
  }

  /**
   * @uses: Login and return Sanctum token
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function login($params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($params['email']) || empty($params['password'])) {
      $rs['msg'] = 'Email and password are required.';
      return $rs;
    }

    $account = api::get_account_by_email($params['email']);
    if (empty($account) || !Hash::check($params['password'], $account->password_hash)) {
      $rs['msg'] = 'Invalid email or password.';
      return $rs;
    }

    $token = $account->createToken('auth_token')->plainTextToken;

    $rs = SharedFunction::api_success('Login successful.', [
      'account' => api::format_account($account),
      'token'   => $token,
    ]);

    return $rs;
  }

  /**
   * @uses: Revoke current access token
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function logout($account)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    $account->currentAccessToken()?->delete();

    $rs = SharedFunction::api_success('Logout successful.');
    return $rs;
  }

  /**
   * @uses: Return authenticated account details
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function me($account)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    $account->load('auth_level');

    $rs = SharedFunction::api_success('Account retrieved.', api::format_account($account));
    return $rs;
  }
}
