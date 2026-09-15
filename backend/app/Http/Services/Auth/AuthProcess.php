<?php

namespace App\Http\Services\Auth;

use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use App\Libraries\api;
use App\Libraries\SharedFunction;
use App\Models\Account\AccountModel;
use App\Models\Auth\AuthLevelModel;

class AuthProcess
{
  /**
   * @uses: Register a new account at the unverified auth level and email it an OTP.
   *        No token is issued here — the account stays unverified until verify_otp succeeds.
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

    $auth_level_id = api::get_auth_level_id(AuthLevelModel::LEVEL_UNVERIFIED);
    if (empty($auth_level_id)) {
      $rs['msg'] = 'Unverified auth level not found.';
      return $rs;
    }

    $account = AccountModel::create([
      'email'         => $params['email'],
      'password_hash' => Hash::make($params['password']),
      'username'      => $params['username'],
      'auth_level_id' => $auth_level_id,
    ]);

    // account.id is DB-generated (DEFAULT UUID()). With $incrementing = false, Eloquent
    // omits id from INSERT but never reads the generated value back — reload by email.
    if (empty($account->id)) {
      $account = api::get_account_by_email($params['email']);
      if (empty($account)) {
        $rs['msg'] = 'Account was created but could not be loaded.';
        return $rs;
      }
    }

    $account->load('auth_level');

    $this->send_otp($account->email);

    $rs = SharedFunction::api_success('Registration successful. Check your email for the verification code.', [
      'account'            => api::format_account($account),
      'email'              => $account->email,
      'needs_verification' => true,
    ]);

    return $rs;
  }

  /**
   * @uses: Verify a submitted OTP, promote the account from unverified to user, and issue its token
   * @author: Kai Yaneza
   * Date: 2026-09-12
   */
  public function verify_otp($params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $validation = SharedFunction::validate_otp_payload($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    $account = api::get_account_by_email($params['email']);
    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    // Already verified accounts have nothing to consume, so send them back to sign in.
    if ($account->auth_level?->level != AuthLevelModel::LEVEL_UNVERIFIED) {
      $rs['msg'] = 'This account is already verified.';
      return $rs;
    }

    if (!api::otp_check($params['email'], $params['code'])) {
      $rs['msg'] = 'The verification code is incorrect or has expired.';
      return $rs;
    }

    if (!api::set_account_auth_level($account, AuthLevelModel::LEVEL_USER)) {
      $rs['msg'] = 'User auth level not found.';
      return $rs;
    }

    $token = $account->createToken('auth_token')->plainTextToken;

    $rs = SharedFunction::api_success('Account verified.', [
      'account' => api::format_account($account),
      'token'   => $token,
    ]);

    return $rs;
  }

  /**
   * @uses: Issue a fresh OTP for an unverified account, honouring the resend cooldown
   * @author: Kai Yaneza
   * Date: 2026-09-12
   */
  public function resend_otp($params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $validation = SharedFunction::validate_otp_payload($params, false);
    if ($validation['code'] != 1) {
      return $validation;
    }

    $account = api::get_account_by_email($params['email']);
    if (empty($account)) {
      $rs['msg'] = 'Account not found.';
      return $rs;
    }

    if ($account->auth_level?->level != AuthLevelModel::LEVEL_UNVERIFIED) {
      $rs['msg'] = 'This account is already verified.';
      return $rs;
    }

    $wait = api::otp_resend_wait($params['email']);
    if ($wait > 0) {
      $rs['msg']  = "Please wait {$wait}s before requesting another code.";
      $rs['data'] = ['retry_after' => $wait];
      return $rs;
    }

    $this->send_otp($account->email);

    $rs = SharedFunction::api_success('A new verification code has been sent.', [
      'email'       => $account->email,
      'retry_after' => api::OTP_RESEND_SECONDS,
    ]);

    return $rs;
  }

  /**
   * @uses: Generate, cache, and mail a one-time code. MAIL_MAILER=log writes it to storage/logs/laravel.log.
   * @author: Kai Yaneza
   * Date: 2026-09-12
   */
  private function send_otp($email)
  {
    $code    = api::otp_generate();
    $minutes = api::OTP_TTL_MINUTES;

    api::otp_store($email, $code);

    Mail::raw(
      "Your Sa'n Tayo verification code is {$code}. It expires in {$minutes} minutes.",
      function ($message) use ($email) {
        $message->to($email)->subject("Sa'n Tayo account verification");
      }
    );

    return $code;
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

    // Credentials are good but the account never cleared OTP — send the client to the verification screen.
    if ($account->auth_level?->level == AuthLevelModel::LEVEL_UNVERIFIED) {
      $rs['msg']  = 'This account is not verified yet. Enter the code we sent to your email.';
      $rs['data'] = [
        'email'              => $account->email,
        'needs_verification' => true,
      ];
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
