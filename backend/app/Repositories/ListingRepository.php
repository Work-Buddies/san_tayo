<?php

namespace App\Repositories;

use App\Http\Services\Listing\ListingProcess;

class ListingRepository implements ListingRepoInterface
{
  protected $listing_process;

  public function __construct(ListingProcess $listing_process)
  {
    $this->listing_process = $listing_process;
  }

  public function index($account = null)
  {
    return $this->listing_process->get_listings($account);
  }

  public function show($id, $account = null)
  {
    return $this->listing_process->get_listing($id, $account);
  }

  public function store($account, $params)
  {
    return $this->listing_process->create_listing($account, $params);
  }

  public function update($account, $id, $params)
  {
    return $this->listing_process->update_listing($account, $id, $params);
  }

  public function deactivate($account, $id)
  {
    return $this->listing_process->deactivate_listing($account, $id);
  }

  public function activate($account, $id)
  {
    return $this->listing_process->activate_listing($account, $id);
  }

  public function destroy($account, $id)
  {
    return $this->listing_process->delete_listing($account, $id);
  }

  public function approve($id)
  {
    return $this->listing_process->approve_listing($id);
  }

  public function reject($id)
  {
    return $this->listing_process->reject_listing($id);
  }

  public function store_image($account, $listing_id, $params)
  {
    return $this->listing_process->store_image($account, $listing_id, $params);
  }

  public function update_image($account, $listing_id, $img_id, $params)
  {
    return $this->listing_process->update_image($account, $listing_id, $img_id, $params);
  }

  public function destroy_image($account, $listing_id, $img_id)
  {
    return $this->listing_process->destroy_image($account, $listing_id, $img_id);
  }

  public function restore_image($account, $listing_id, $img_id)
  {
    return $this->listing_process->restore_image($account, $listing_id, $img_id);
  }

  public function store_menu($account, $listing_id, $params)
  {
    return $this->listing_process->store_menu($account, $listing_id, $params);
  }

  public function update_menu($account, $listing_id, $menu_id, $params)
  {
    return $this->listing_process->update_menu($account, $listing_id, $menu_id, $params);
  }

  public function destroy_menu($account, $listing_id, $menu_id)
  {
    return $this->listing_process->destroy_menu($account, $listing_id, $menu_id);
  }

  public function restore_menu($account, $listing_id, $menu_id)
  {
    return $this->listing_process->restore_menu($account, $listing_id, $menu_id);
  }

  public function sync_food_types($account, $listing_id, $params)
  {
    return $this->listing_process->sync_food_types($account, $listing_id, $params);
  }

  public function destroy_food_type($account, $listing_id, $food_type_id)
  {
    return $this->listing_process->destroy_food_type($account, $listing_id, $food_type_id);
  }

  public function restore_food_type($account, $listing_id, $food_type_id)
  {
    return $this->listing_process->restore_food_type($account, $listing_id, $food_type_id);
  }
}
