<?php

namespace App\Models\Listing;

use Illuminate\Database\Eloquent\Model;

class ListingMenuModel extends Model
{
  protected $table        = 'listing_menu';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'listing_id',
    'item',
    'price',
    'description',
    'deleted_at',
  ];

  protected $casts = [
    'price'      => 'decimal:2',
    'deleted_at' => 'datetime',
  ];

  public function listing()
  {
    return $this->belongsTo(ListingModel::class, 'listing_id');
  }
}
