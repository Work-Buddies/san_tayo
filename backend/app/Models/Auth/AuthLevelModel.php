<?php

namespace App\Models\Auth;

use Illuminate\Database\Eloquent\Model;

class AuthLevelModel extends Model
{
  protected $table        = 'auth_level';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = ['level'];

  public const LEVEL_ADMIN    = 'admin';
  public const LEVEL_BUSINESS = 'business';
  public const LEVEL_USER     = 'user';
}
