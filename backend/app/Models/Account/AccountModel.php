<?php

namespace App\Models\Account;

use App\Models\Auth\AuthLevelModel;
use App\Models\Listing\ListingModel;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class AccountModel extends Authenticatable
{
  use HasApiTokens;

  protected $table        = 'account';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'email',
    'password_hash',
    'username',
    'auth_level_id',
  ];

  protected $hidden = [
    'password_hash',
  ];

  public function auth_level()
  {
    return $this->belongsTo(AuthLevelModel::class, 'auth_level_id');
  }

  public function listings()
  {
    return $this->hasMany(ListingModel::class, 'account_id');
  }

  public function getAuthPassword()
  {
    return $this->password_hash;
  }
}
