<?php

namespace Tests\Unit;

use App\Libraries\api;
use Tests\TestCase;

class OtpTest extends TestCase
{
  private $email = 'juan.dela.cruz@gmail.com';

  public function test_generated_code_is_always_four_digits(): void
  {
    // Loop so the zero-padding branch (codes under 1000) is actually exercised.
    for ($i = 0; $i < 200; $i++) {
      $this->assertMatchesRegularExpression('/^[0-9]{4}$/', api::otp_generate());
    }
  }

  public function test_correct_code_passes_and_wrong_code_fails(): void
  {
    api::otp_store($this->email, '1234');

    $this->assertFalse(api::otp_check($this->email, '9999'));
    $this->assertTrue(api::otp_check($this->email, '1234'));
  }

  public function test_code_is_single_use(): void
  {
    api::otp_store($this->email, '1234');

    $this->assertTrue(api::otp_check($this->email, '1234'));
    $this->assertFalse(api::otp_check($this->email, '1234'));
  }

  public function test_check_is_case_insensitive_on_email(): void
  {
    api::otp_store($this->email, '1234');

    $this->assertTrue(api::otp_check(strtoupper($this->email), '1234'));
  }

  public function test_code_expires(): void
  {
    api::otp_store($this->email, '1234');

    $this->travel(api::OTP_TTL_MINUTES + 1)->minutes();

    $this->assertFalse(api::otp_check($this->email, '1234'));
  }

  public function test_resend_is_blocked_until_the_cooldown_elapses(): void
  {
    $this->assertSame(0, api::otp_resend_wait($this->email));

    api::otp_store($this->email, '1234');
    $this->assertGreaterThan(0, api::otp_resend_wait($this->email));

    $this->travel(api::OTP_RESEND_SECONDS + 1)->seconds();
    $this->assertSame(0, api::otp_resend_wait($this->email));
  }

  public function test_consuming_a_code_clears_the_cooldown(): void
  {
    api::otp_store($this->email, '1234');
    api::otp_check($this->email, '1234');

    $this->assertSame(0, api::otp_resend_wait($this->email));
  }
}
