<?php

namespace App\Models\Listing;

use Illuminate\Database\Eloquent\Model;

class ListingMenuGroupModel extends Model
{
  protected $table        = 'listing_menu_group';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'listing_id',
    'group_name',
    'deleted_at',
  ];

  protected $casts = [
    'deleted_at' => 'datetime',
  ];

  public function listing()
  {
    return $this->belongsTo(ListingModel::class, 'listing_id');
  }

  public function items()
  {
    return $this->hasMany(ListingMenuModel::class, 'listing_menu_group_id')->whereNull('deleted_at');
  }

  public function items_with_trashed()
  {
    return $this->hasMany(ListingMenuModel::class, 'listing_menu_group_id');
  }
}
