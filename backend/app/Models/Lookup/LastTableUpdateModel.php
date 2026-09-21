<?php

namespace App\Models\Lookup;

use Illuminate\Database\Eloquent\Model;

class LastTableUpdateModel extends Model
{
  protected $table        = 'last_table_updates';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'table_name',
    'last_update',
  ];

  protected $casts = [
    'last_update' => 'datetime',
  ];
}
