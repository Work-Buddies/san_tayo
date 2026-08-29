<?php

namespace App\Models\Location;

use Illuminate\Database\Eloquent\Model;

class BarangayModel extends Model
{
  protected $table        = 'barangay';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = ['name'];
}
