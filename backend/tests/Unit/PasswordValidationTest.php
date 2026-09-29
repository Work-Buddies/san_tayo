<?php

namespace Tests\Unit;

use App\Libraries\SharedFunction;
use Tests\TestCase;

class PasswordValidationTest extends TestCase
{
  public function test_new_password_requires_minimum_length(): void
  {
    $rs = SharedFunction::validate_new_password('short1');

    $this->assertEquals(0, $rs['code']);
  }

  public function test_new_password_requires_a_number(): void
  {
    $rs = SharedFunction::validate_new_password('abcdefgh');

    $this->assertEquals(0, $rs['code']);
  }

  public function test_valid_new_password_passes(): void
  {
    $rs = SharedFunction::validate_new_password('abcdefg1');

    $this->assertEquals(1, $rs['code']);
  }

  public function test_username_update_rejects_empty(): void
  {
    $rs = SharedFunction::validate_username_update(['username' => '']);

    $this->assertEquals(0, $rs['code']);
  }
}
