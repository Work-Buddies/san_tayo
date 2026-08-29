<?php

namespace App\Models\Listing;

use App\Models\Food\FoodTypeModel;
use Illuminate\Database\Eloquent\Model;

class ListingFoodTypeModel extends Model
{
  protected $table        = 'listing_food_type';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'listing_id',
    'food_type_id',
    'deleted_at',
  ];

  protected $casts = [
    'deleted_at' => 'datetime',
  ];

  public function listing()
  {
    return $this->belongsTo(ListingModel::class, 'listing_id');
  }

  public function food_type()
  {
    return $this->belongsTo(FoodTypeModel::class, 'food_type_id');
  }
}
