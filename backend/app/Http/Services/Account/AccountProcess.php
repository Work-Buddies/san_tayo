<?php

namespace App\Http\Services\Account;

use App\Libraries\api;
use App\Libraries\SharedFunction;
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
}
