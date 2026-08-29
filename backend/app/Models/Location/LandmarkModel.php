<?php

namespace App\Models\Location;

use Illuminate\Database\Eloquent\Model;

class LandmarkModel extends Model
{
  protected $table        = 'landmark';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'barangay_id',
    'name',
    'map_latitude',
    'map_longitude',
  ];

  protected $casts = [
    'map_latitude'  => 'decimal:6',
    'map_longitude' => 'decimal:6',
  ];

  public function barangay()
  {
    return $this->belongsTo(BarangayModel::class, 'barangay_id');
  }
}
