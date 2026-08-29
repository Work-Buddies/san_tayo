<?php

namespace App\Models\Food;

use Illuminate\Database\Eloquent\Model;

class FoodTypeModel extends Model
{
  protected $table        = 'food_type';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = [
    'name',
    'description',
  ];
}
