<?php

namespace App\Models\Listing;

use Illuminate\Database\Eloquent\Model;

class ListingStatusModel extends Model
{
  protected $table        = 'listing_status';
  protected $primaryKey   = 'id';
  public    $incrementing = false;
  protected $keyType      = 'string';
  public    $timestamps   = false;

  protected $fillable = ['status'];

  public const STATUS_PENDING  = 'pending';
  public const STATUS_VIEWED   = 'viewed';
  public const STATUS_APPROVED = 'approved';
  public const STATUS_REJECTED = 'rejected';
}
