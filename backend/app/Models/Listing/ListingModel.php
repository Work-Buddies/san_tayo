<?php

namespace App\Models\Listing;

use App\Models\Account\AccountModel;
use App\Models\Location\LandmarkModel;
use Illuminate\Database\Eloquent\Model;

class ListingModel extends Model
{
  protected $table        = 'listing';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'id',
    'account_id',
    'landmark_id',
    'listing_status_id',
    'title',
    'description',
    'address_street',
    'address_purok',
    'active',
  ];

  protected $casts = [
    'active' => 'boolean',
  ];

  public function account()
  {
    return $this->belongsTo(AccountModel::class, 'account_id');
  }

  public function landmark()
  {
    return $this->belongsTo(LandmarkModel::class, 'landmark_id');
  }

  public function listing_status()
  {
    return $this->belongsTo(ListingStatusModel::class, 'listing_status_id');
  }

  public function images()
  {
    return $this->hasMany(ListingImgModel::class, 'listing_id')->whereNull('deleted_at');
  }

  public function menu_items()
  {
    return $this->hasMany(ListingMenuModel::class, 'listing_id')->whereNull('deleted_at');
  }

  public function food_types()
  {
    return $this->hasMany(ListingFoodTypeModel::class, 'listing_id')->whereNull('deleted_at');
  }

  public function images_with_trashed()
  {
    return $this->hasMany(ListingImgModel::class, 'listing_id');
  }

  public function menu_items_with_trashed()
  {
    return $this->hasMany(ListingMenuModel::class, 'listing_id');
  }

  public function food_types_with_trashed()
  {
    return $this->hasMany(ListingFoodTypeModel::class, 'listing_id');
  }
}
