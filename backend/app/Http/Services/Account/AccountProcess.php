<?php

namespace App\Http\Services\Account;

use Illuminate\Support\Facades\Hash;
use App\Libraries\api;
use App\Libraries\SharedFunction;
use App\Models\Account\AccountModel;
use App\Models\Auth\AuthLevelModel;

class AccountProcess
{
  /**
   * @uses: Upgrade user account to business auth level
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function upgrade_to_business($account)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    $account->load('auth_level');

    if ($account->auth_level?->level != AuthLevelModel::LEVEL_USER) {
      $rs['msg'] = 'Only user accounts can be upgraded to business.';
      return $rs;
    }

    $business_level_id = api::get_auth_level_id(AuthLevelModel::LEVEL_BUSINESS);
    if (empty($business_level_id)) {
      $rs['msg'] = 'Business auth level not found.';
      return $rs;
    }

    $account->auth_level_id = $business_level_id;
    $account->save();
    $account->load('auth_level');

    $rs = SharedFunction::api_success('Account upgraded to business.', api::format_account($account));
    return $rs;
  }

  /**
   * @uses: Update the authenticated account username
   * @author: Kai Yaneza
   * Date: 2026-09-29
   */
  public function update_username($account, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    $validation = SharedFunction::validate_username_update($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    $username = trim($params['username']);

    if ($account->username === $username) {
      $account->load('auth_level');
      $rs = SharedFunction::api_success('Username updated.', api::format_account($account));
      return $rs;
    }

    $taken = AccountModel::where('username', $username)
      ->where('id', '!=', $account->id)
      ->exists();

    if ($taken) {
      $rs['msg'] = 'Username is already taken.';
      return $rs;
    }

    $account->username = $username;
    $account->save();
    $account->load('auth_level');

    $rs = SharedFunction::api_success('Username updated.', api::format_account($account));
    return $rs;
  }

  /**
   * @uses: Change password for the authenticated account
   * @author: Kai Yaneza
   * Date: 2026-09-29
   */
  public function change_password($account, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    $validation = SharedFunction::validate_password_change_payload($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    if (!Hash::check($params['current_password'], $account->password_hash)) {
      $rs['msg'] = 'Current password is incorrect.';
      return $rs;
    }

    if ($params['current_password'] === $params['new_password']) {
      $rs['msg'] = 'New password must not match your current password.';
      return $rs;
    }

    $account->password_hash = Hash::make($params['new_password']);
    $account->save();

    $rs = SharedFunction::api_success('Password updated.');
    return $rs;
  }
}
