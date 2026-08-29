<?php

namespace App\Models\Listing;

use Illuminate\Database\Eloquent\Model;

class ListingImgModel extends Model
{
  protected $table        = 'listing_img';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'listing_id',
    'img',
    'alt_text',
    'deleted_at',
  ];

  protected $casts = [
    'deleted_at' => 'datetime',
  ];

  public function listing()
  {
    return $this->belongsTo(ListingModel::class, 'listing_id');
  }
}
