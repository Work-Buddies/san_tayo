<?php

namespace App\Libraries;

use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use App\Models\Account\AccountModel;
use App\Models\Auth\AuthLevelModel;
use App\Models\Food\FoodTypeModel;
use App\Models\Listing\ListingModel;
use App\Models\Listing\ListingImgModel;
use App\Models\Listing\ListingMenuModel;
use App\Models\Listing\ListingFoodTypeModel;
use App\Models\Listing\ListingStatusModel;
use App\Models\Location\BarangayModel;
use App\Models\Location\LandmarkModel;

class api
{
  public static function ping()
  {
    $data = [
      'app'       => config('app.name'),
      'status'    => 'ok',
      'timestamp' => now()->toIso8601String(),
    ];

    return SharedFunction::api_success('Health check successful.', $data);
  }

  public static function get_auth_level_id($level)
  {
    $row = AuthLevelModel::where('level', $level)->first();

    return $row?->id;
  }

  public static function get_listing_status_id($status)
  {
    $row = ListingStatusModel::where('status', $status)->first();

    return $row?->id;
  }

  public static function get_account_by_email($email)
  {
    return AccountModel::with('auth_level')->where('email', $email)->first();
  }

  public static function email_exists($email)
  {
    return AccountModel::where('email', $email)->exists();
  }

  public static function username_exists($username)
  {
    return AccountModel::where('username', $username)->exists();
  }

  public static function format_account($account)
  {
    if (empty($account)) {
      return null;
    }

    return [
      'id'         => $account->id,
      'email'      => $account->email,
      'username'   => $account->username,
      'auth_level' => $account->auth_level?->level,
      'created_at' => $account->created_at,
    ];
  }

  public static function listing_relations($include_trashed = false)
  {
    if ($include_trashed) {
      return [
        'landmark.barangay',
        'listing_status',
        'images_with_trashed',
        'menu_items_with_trashed',
        'food_types_with_trashed.food_type',
      ];
    }

    return [
      'landmark.barangay',
      'listing_status',
      'images',
      'menu_items',
      'food_types.food_type',
    ];
  }

  public static function format_listing($listing, $include_trashed = false)
  {
    if (empty($listing)) {
      return null;
    }

    $images_key     = $include_trashed ? 'images_with_trashed' : 'images';
    $menu_key       = $include_trashed ? 'menu_items_with_trashed' : 'menu_items';
    $food_types_key = $include_trashed ? 'food_types_with_trashed' : 'food_types';

    $images = [];
    foreach ($listing->{$images_key} ?? [] as $img) {
      $images[] = [
        'id'         => $img->id,
        'img_base64' => base64_encode($img->img),
        'alt_text'   => $img->alt_text,
        'deleted_at' => $img->deleted_at,
      ];
    }

    $menu_items = [];
    foreach ($listing->{$menu_key} ?? [] as $menu) {
      $menu_items[] = [
        'id'          => $menu->id,
        'item'        => $menu->item,
        'price'       => $menu->price,
        'description' => $menu->description,
        'deleted_at'  => $menu->deleted_at,
      ];
    }

    $food_types = [];
    foreach ($listing->{$food_types_key} ?? [] as $lft) {
      $food_types[] = [
        'id'           => $lft->id,
        'food_type_id' => $lft->food_type_id,
        'name'         => $lft->food_type?->name,
        'description'  => $lft->food_type?->description,
        'deleted_at'   => $lft->deleted_at,
      ];
    }

    return [
      'id'              => $listing->id,
      'account_id'      => $listing->account_id,
      'landmark_id'     => $listing->landmark_id,
      'landmark'        => $listing->landmark ? [
        'id'            => $listing->landmark->id,
        'name'          => $listing->landmark->name,
        'map_latitude'  => $listing->landmark->map_latitude,
        'map_longitude' => $listing->landmark->map_longitude,
        'barangay'      => $listing->landmark->barangay?->name,
      ] : null,
      'listing_status'  => $listing->listing_status?->status,
      'title'           => $listing->title,
      'description'     => $listing->description,
      'address_street'  => $listing->address_street,
      'address_purok'   => $listing->address_purok,
      'active'          => $listing->active,
      'images'          => $images,
      'menu_items'      => $menu_items,
      'food_types'      => $food_types,
    ];
  }

  public static function get_listing_with_children($id, $include_trashed = false)
  {
    return ListingModel::with(self::listing_relations($include_trashed))
      ->where('id', $id)
      ->first();
  }

  public static function get_listings($filters = [])
  {
    $query = ListingModel::with(self::listing_relations(false));

    if (!empty($filters['public_only'])) {
      $approved_id = self::get_listing_status_id(ListingStatusModel::STATUS_APPROVED);
      $query->where('listing_status_id', $approved_id)
        ->where('active', true);
    }

    if (!empty($filters['account_id'])) {
      $query->where('account_id', $filters['account_id']);
    }

    if (isset($filters['active'])) {
      $query->where('active', (bool) $filters['active']);
    }

    return $query->get();
  }

  public static function get_barangays()
  {
    return BarangayModel::orderBy('name')->get();
  }

  public static function get_food_types()
  {
    return FoodTypeModel::orderBy('name')->get();
  }

  public static function get_listing_statuses()
  {
    return ListingStatusModel::orderBy('status')->get();
  }

  public static function get_landmarks()
  {
    return LandmarkModel::with('barangay')->orderBy('name')->get();
  }

  public static function get_landmark($id)
  {
    return LandmarkModel::with('barangay')->where('id', $id)->first();
  }

  public static function barangay_exists($id)
  {
    return BarangayModel::where('id', $id)->exists();
  }

  public static function landmark_exists($id)
  {
    return LandmarkModel::where('id', $id)->exists();
  }

  public static function food_type_exists($id)
  {
    return FoodTypeModel::where('id', $id)->exists();
  }

  public static function listing_belongs_to_account($listing_id, $account_id)
  {
    return ListingModel::where('id', $listing_id)
      ->where('account_id', $account_id)
      ->exists();
  }

  public static function soft_delete_child($model_class, $id)
  {
    return $model_class::where('id', $id)->update(['deleted_at' => now()]);
  }

  public static function restore_child($model_class, $id)
  {
    return $model_class::where('id', $id)->update(['deleted_at' => null]);
  }
}
