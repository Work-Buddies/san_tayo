<?php

namespace App\Repositories;

interface ListingRepoInterface
{
  public function index($account = null);
  public function show($id, $account = null);
  public function store($account, $params);
  public function update($account, $id, $params);
  public function deactivate($account, $id);
  public function activate($account, $id);
  public function destroy($account, $id);
  public function approve($id);
  public function reject($id);
  public function store_image($account, $listing_id, $params);
  public function update_image($account, $listing_id, $img_id, $params);
  public function destroy_image($account, $listing_id, $img_id);
  public function restore_image($account, $listing_id, $img_id);
  public function store_menu($account, $listing_id, $params);
  public function update_menu($account, $listing_id, $menu_id, $params);
  public function destroy_menu($account, $listing_id, $menu_id);
  public function restore_menu($account, $listing_id, $menu_id);
  public function sync_food_types($account, $listing_id, $params);
  public function destroy_food_type($account, $listing_id, $food_type_id);
  public function restore_food_type($account, $listing_id, $food_type_id);
}
