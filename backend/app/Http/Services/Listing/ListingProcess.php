<?php

namespace App\Http\Services\Listing;

use Illuminate\Support\Str;
use Illuminate\Support\Facades\DB;
use App\Libraries\api;
use App\Libraries\SharedFunction;
use App\Models\Auth\AuthLevelModel;
use App\Models\Listing\ListingModel;
use App\Models\Listing\ListingImgModel;
use App\Models\Listing\ListingMenuModel;
use App\Models\Listing\ListingFoodTypeModel;
use App\Models\Listing\ListingStatusModel;
use App\Models\Location\LandmarkModel;

class ListingProcess
{
  /**
   * @uses: Check if account can manage a listing
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function can_manage_listing($account, $listing_id)
  {
    $account->load('auth_level');
    $level = $account->auth_level?->level;

    if ($level == AuthLevelModel::LEVEL_ADMIN) {
      return true;
    }

    if ($level == AuthLevelModel::LEVEL_BUSINESS) {
      return api::listing_belongs_to_account($listing_id, $account->id);
    }

    return false;
  }

  /**
   * @uses: Get all listings with filters
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function get_listings($account = null, $filters = [])
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (empty($account)) {
      $filters['public_only'] = true;
    } else {
      $account->load('auth_level');
      $level = $account->auth_level?->level;

      if ($level == AuthLevelModel::LEVEL_BUSINESS) {
        $filters['account_id'] = $account->id;
      } elseif ($level != AuthLevelModel::LEVEL_ADMIN) {
        $filters['public_only'] = true;
      }
    }

    $listings = api::get_listings($filters);
    $data     = [];

    foreach ($listings as $listing) {
      $data[] = api::format_listing($listing);
    }

    $rs = SharedFunction::api_success('Listings retrieved.', $data);
    return $rs;
  }

  /**
   * @uses: Get single listing with all children
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function get_listing($id, $account = null)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $include_trashed = false;
    if (!empty($account)) {
      $account->load('auth_level');
      $level = $account->auth_level?->level;
      $include_trashed = in_array($level, [AuthLevelModel::LEVEL_BUSINESS, AuthLevelModel::LEVEL_ADMIN]);
    }

    $listing = api::get_listing_with_children($id, $include_trashed);
    if (empty($listing)) {
      $rs['msg'] = 'Listing not found.';
      return $rs;
    }

    if (empty($account)) {
      $approved_id = api::get_listing_status_id(ListingStatusModel::STATUS_APPROVED);
      if ($listing->listing_status_id != $approved_id || !$listing->active) {
        $rs['msg'] = 'Listing not available.';
        return $rs;
      }
    }

    $rs = SharedFunction::api_success('Listing retrieved.', api::format_listing($listing, $include_trashed));
    return $rs;
  }

  /**
   * @uses: Create listing with optional children in one transaction
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function create_listing($account, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $validation = SharedFunction::validate_listing_payload($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    if (empty($params['title']) || empty($params['description']) || empty($params['address_street']) || empty($params['address_purok'])) {
      $rs['msg'] = 'Title, description, street, and purok are required.';
      return $rs;
    }

    if (!api::landmark_exists($params['landmark_id'])) {
      $rs['msg'] = 'Landmark not found.';
      return $rs;
    }

    $pending_id = api::get_listing_status_id(ListingStatusModel::STATUS_PENDING);
    if (empty($pending_id)) {
      $rs['msg'] = 'Pending listing status not found.';
      return $rs;
    }

    try {
      DB::beginTransaction();

      $listing_id = Str::uuid()->toString();
      ListingModel::create([
        'id'                => $listing_id,
        'account_id'        => $account->id,
        'landmark_id'       => $params['landmark_id'],
        'listing_status_id' => $pending_id,
        'title'             => $params['title'],
        'description'       => $params['description'],
        'address_street'    => $params['address_street'],
        'address_purok'     => $params['address_purok'],
        'active'            => true,
      ]);

      $this->save_children($listing_id, $params);

      DB::commit();

      $listing = api::get_listing_with_children($listing_id, true);
      $rs = SharedFunction::api_success('Listing created.', api::format_listing($listing, true));
    } catch (\Exception $e) {
      DB::rollBack();
      $rs['msg'] = 'Failed to create listing.';
    }

    return $rs;
  }

  /**
   * @uses: Update listing fields
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function update_listing($account, $id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $id)) {
      $rs['msg'] = 'You are not allowed to update this listing.';
      return $rs;
    }

    $validation = SharedFunction::validate_listing_payload($params, true);
    if ($validation['code'] != 1) {
      return $validation;
    }

    $listing = ListingModel::where('id', $id)->first();
    if (empty($listing)) {
      $rs['msg'] = 'Listing not found.';
      return $rs;
    }

    if (!empty($params['landmark_id']) && !api::landmark_exists($params['landmark_id'])) {
      $rs['msg'] = 'Landmark not found.';
      return $rs;
    }

    $fields = ['landmark_id', 'title', 'description', 'address_street', 'address_purok', 'active'];
    foreach ($fields as $field) {
      if (array_key_exists($field, $params)) {
        $listing->{$field} = $params[$field];
      }
    }

    $listing->save();

    $listing = api::get_listing_with_children($id, true);
    $rs = SharedFunction::api_success('Listing updated.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Deactivate listing (soft flag on listing itself)
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function deactivate_listing($account, $id)
  {
    return $this->set_listing_active($account, $id, false);
  }

  /**
   * @uses: Activate listing
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function activate_listing($account, $id)
  {
    return $this->set_listing_active($account, $id, true);
  }

  /**
   * @uses: Hard delete listing (children cascade via FK)
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function delete_listing($account, $id)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $id)) {
      $rs['msg'] = 'You are not allowed to delete this listing.';
      return $rs;
    }

    $listing = ListingModel::where('id', $id)->first();
    if (empty($listing)) {
      $rs['msg'] = 'Listing not found.';
      return $rs;
    }

    $listing->delete();

    $rs = SharedFunction::api_success('Listing deleted.');
    return $rs;
  }

  /**
   * @uses: Approve listing (admin only)
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function approve_listing($id)
  {
    return $this->set_listing_status($id, ListingStatusModel::STATUS_APPROVED);
  }

  /**
   * @uses: Reject listing (admin only)
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function reject_listing($id)
  {
    return $this->set_listing_status($id, ListingStatusModel::STATUS_REJECTED);
  }

  /**
   * @uses: Add image to listing
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function store_image($account, $listing_id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    if (empty($params['img_base64'])) {
      $rs['msg'] = 'Image data is required.';
      return $rs;
    }

    $binary = base64_decode($params['img_base64'], true);
    if ($binary === false) {
      $rs['msg'] = 'Invalid image data.';
      return $rs;
    }

    if (!empty($params['alt_text']) && strlen($params['alt_text']) > 255) {
      $rs['msg'] = 'Alt text must be 255 characters or less.';
      return $rs;
    }

    ListingImgModel::create([
      'listing_id' => $listing_id,
      'img'        => $binary,
      'alt_text'   => $params['alt_text'] ?? null,
    ]);

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Image added.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Update listing image
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function update_image($account, $listing_id, $img_id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $img = ListingImgModel::where('id', $img_id)->where('listing_id', $listing_id)->first();
    if (empty($img)) {
      $rs['msg'] = 'Image not found.';
      return $rs;
    }

    if (!empty($params['img_base64'])) {
      $binary = base64_decode($params['img_base64'], true);
      if ($binary === false) {
        $rs['msg'] = 'Invalid image data.';
        return $rs;
      }
      $img->img = $binary;
    }

    if (array_key_exists('alt_text', $params)) {
      if (!empty($params['alt_text']) && strlen($params['alt_text']) > 255) {
        $rs['msg'] = 'Alt text must be 255 characters or less.';
        return $rs;
      }
      $img->alt_text = $params['alt_text'];
    }

    $img->save();

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Image updated.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Soft delete listing image
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function destroy_image($account, $listing_id, $img_id)
  {
    return $this->soft_delete_child($account, $listing_id, $img_id, ListingImgModel::class, 'Image');
  }

  /**
   * @uses: Restore soft-deleted listing image
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function restore_image($account, $listing_id, $img_id)
  {
    return $this->restore_child($account, $listing_id, $img_id, ListingImgModel::class, 'Image');
  }

  /**
   * @uses: Add menu item to listing
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function store_menu($account, $listing_id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $validation = SharedFunction::validate_menu_item($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    ListingMenuModel::create([
      'listing_id'  => $listing_id,
      'item'        => $params['item'],
      'price'       => $params['price'],
      'description' => $params['description'] ?? null,
    ]);

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Menu item added.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Update menu item
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function update_menu($account, $listing_id, $menu_id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $menu = ListingMenuModel::where('id', $menu_id)->where('listing_id', $listing_id)->first();
    if (empty($menu)) {
      $rs['msg'] = 'Menu item not found.';
      return $rs;
    }

    if (!empty($params['item']) || !empty($params['price'])) {
      $validation = SharedFunction::validate_menu_item(array_merge([
        'item'  => $menu->item,
        'price' => $menu->price,
      ], $params));
      if ($validation['code'] != 1) {
        return $validation;
      }
    }

    if (!empty($params['item'])) {
      $menu->item = $params['item'];
    }
    if (isset($params['price'])) {
      $menu->price = $params['price'];
    }
    if (array_key_exists('description', $params)) {
      $menu->description = $params['description'];
    }

    $menu->save();

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Menu item updated.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Soft delete menu item
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function destroy_menu($account, $listing_id, $menu_id)
  {
    return $this->soft_delete_child($account, $listing_id, $menu_id, ListingMenuModel::class, 'Menu item');
  }

  /**
   * @uses: Restore soft-deleted menu item
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function restore_menu($account, $listing_id, $menu_id)
  {
    return $this->restore_child($account, $listing_id, $menu_id, ListingMenuModel::class, 'Menu item');
  }

  /**
   * @uses: Sync food types for a listing
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function sync_food_types($account, $listing_id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $food_type_ids = $params['food_type_ids'] ?? [];
    if (!is_array($food_type_ids)) {
      $rs['msg'] = 'food_type_ids must be an array.';
      return $rs;
    }

    foreach ($food_type_ids as $food_type_id) {
      if (!api::food_type_exists($food_type_id)) {
        $rs['msg'] = "Food type {$food_type_id} not found.";
        return $rs;
      }
    }

    $existing = ListingFoodTypeModel::where('listing_id', $listing_id)->get();

    foreach ($existing as $row) {
      if (in_array($row->food_type_id, $food_type_ids)) {
        if (!empty($row->deleted_at)) {
          $row->deleted_at = null;
          $row->save();
        }
      } else {
        $row->deleted_at = now();
        $row->save();
      }
    }

    foreach ($food_type_ids as $food_type_id) {
      $found = $existing->firstWhere('food_type_id', $food_type_id);
      if (empty($found)) {
        ListingFoodTypeModel::create([
          'listing_id'   => $listing_id,
          'food_type_id' => $food_type_id,
        ]);
      }
    }

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Food types synced.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Soft delete a food type link
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function destroy_food_type($account, $listing_id, $food_type_id)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $row = ListingFoodTypeModel::where('listing_id', $listing_id)
      ->where('food_type_id', $food_type_id)
      ->first();

    if (empty($row)) {
      $rs['msg'] = 'Food type link not found.';
      return $rs;
    }

    $row->deleted_at = now();
    $row->save();

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Food type removed.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Restore soft-deleted food type link
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function restore_food_type($account, $listing_id, $food_type_id)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $row = ListingFoodTypeModel::where('listing_id', $listing_id)
      ->where('food_type_id', $food_type_id)
      ->first();

    if (empty($row)) {
      $rs['msg'] = 'Food type link not found.';
      return $rs;
    }

    $row->deleted_at = null;
    $row->save();

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success('Food type restored.', api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Save nested children during listing create
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function save_children($listing_id, $params)
  {
    if (!empty($params['images']) && is_array($params['images'])) {
      foreach ($params['images'] as $img_params) {
        $this->store_image_internal($listing_id, $img_params);
      }
    }

    if (!empty($params['menu_items']) && is_array($params['menu_items'])) {
      foreach ($params['menu_items'] as $menu_params) {
        $validation = SharedFunction::validate_menu_item($menu_params);
        if ($validation['code'] == 1) {
          ListingMenuModel::create([
            'listing_id'  => $listing_id,
            'item'        => $menu_params['item'],
            'price'       => $menu_params['price'],
            'description' => $menu_params['description'] ?? null,
          ]);
        }
      }
    }

    if (!empty($params['food_type_ids']) && is_array($params['food_type_ids'])) {
      foreach ($params['food_type_ids'] as $food_type_id) {
        if (api::food_type_exists($food_type_id)) {
          ListingFoodTypeModel::create([
            'listing_id'   => $listing_id,
            'food_type_id' => $food_type_id,
          ]);
        }
      }
    }
  }

  /**
   * @uses: Internal image insert without permission re-check
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function store_image_internal($listing_id, $params)
  {
    if (empty($params['img_base64'])) {
      return;
    }

    $binary = base64_decode($params['img_base64'], true);
    if ($binary === false) {
      return;
    }

    ListingImgModel::create([
      'listing_id' => $listing_id,
      'img'        => $binary,
      'alt_text'   => $params['alt_text'] ?? null,
    ]);
  }

  /**
   * @uses: Set listing active flag
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function set_listing_active($account, $id, $active)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $listing = ListingModel::where('id', $id)->first();
    if (empty($listing)) {
      $rs['msg'] = 'Listing not found.';
      return $rs;
    }

    $listing->active = $active;
    $listing->save();

    $listing = api::get_listing_with_children($id, true);
    $msg = $active ? 'Listing activated.' : 'Listing deactivated.';
    $rs = SharedFunction::api_success($msg, api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Set listing status by name
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function set_listing_status($id, $status)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $status_id = api::get_listing_status_id($status);
    if (empty($status_id)) {
      $rs['msg'] = 'Listing status not found.';
      return $rs;
    }

    $listing = ListingModel::where('id', $id)->first();
    if (empty($listing)) {
      $rs['msg'] = 'Listing not found.';
      return $rs;
    }

    $listing->listing_status_id = $status_id;
    $listing->save();

    $listing = api::get_listing_with_children($id, true);
    $rs = SharedFunction::api_success("Listing {$status}.", api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Generic soft delete for listing child rows
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function soft_delete_child($account, $listing_id, $child_id, $model_class, $label)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $row = $model_class::where('id', $child_id)->where('listing_id', $listing_id)->first();
    if (empty($row)) {
      $rs['msg'] = "{$label} not found.";
      return $rs;
    }

    $row->deleted_at = now();
    $row->save();

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success("{$label} deleted.", api::format_listing($listing, true));
    return $rs;
  }

  /**
   * @uses: Generic restore for listing child rows
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  private function restore_child($account, $listing_id, $child_id, $model_class, $label)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    if (!$this->can_manage_listing($account, $listing_id)) {
      $rs['msg'] = 'You are not allowed to manage this listing.';
      return $rs;
    }

    $row = $model_class::where('id', $child_id)->where('listing_id', $listing_id)->first();
    if (empty($row)) {
      $rs['msg'] = "{$label} not found.";
      return $rs;
    }

    $row->deleted_at = null;
    $row->save();

    $listing = api::get_listing_with_children($listing_id, true);
    $rs = SharedFunction::api_success("{$label} restored.", api::format_listing($listing, true));
    return $rs;
  }
}
