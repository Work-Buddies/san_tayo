<?php

namespace App\Libraries;

class SharedFunction
{
  /**
   * @uses: Build a standardized success API response
   * @author: Kai Yaneza
   * Date: 2026-08-28
   */
  public static function api_success($msg, $data = null) {
    $rs = [
      'code'  => 1,
      'title' => 'Success!',
      'msg'   => $msg,
      'data'  => $data,
    ];

    return $rs;
  }

  /**
   * @uses: Build a standardized error API response
   * @author: Kai Yaneza
   * Date: 2026-08-28
   */
  public static function api_error($msg, $title = 'Ooops!') {
    $rs = [
      'code'  => 0,
      'title' => $title,
      'msg'   => $msg,
    ];

    return $rs;
  }

  public static function validate_account_register($params) {
    $rs = self::api_error('Validation failed.');
  
    if (empty($params['email'])) {
      $rs['msg'] = 'Email is required.';
      return $rs;
    }
    if (!filter_var($params['email'], FILTER_VALIDATE_EMAIL) || strlen($params['email']) > 255) {
      $rs['msg'] = 'Email must be a valid address up to 255 characters.';
      return $rs;
    }
    if (empty($params['username']) || strlen($params['username']) > 255) {
      $rs['msg'] = 'Username is required and must be 255 characters or less.';
      return $rs;
    }
    if (empty($params['password']) || strlen($params['password']) < 8) {
      $rs['msg'] = 'Password is required and must be at least 8 characters.';
      return $rs;
    }
  
    return self::api_success('Valid.');
  }
  
  public static function validate_listing_payload($params, $is_update = false) {
    $rs = self::api_error('Validation failed.');
  
    if (!$is_update && empty($params['landmark_id'])) {
      $rs['msg'] = 'Landmark is required.';
      return $rs;
    }
    if (!empty($params['title']) && strlen($params['title']) > 255) {
      $rs['msg'] = 'Title must be 255 characters or less.';
      return $rs;
    }
    if (!empty($params['address_street']) && strlen($params['address_street']) > 255) {
      $rs['msg'] = 'Street address must be 255 characters or less.';
      return $rs;
    }
    if (!empty($params['address_purok']) && strlen($params['address_purok']) > 255) {
      $rs['msg'] = 'Purok must be 255 characters or less.';
      return $rs;
    }
    if (isset($params['active']) && !is_bool($params['active']) && !in_array($params['active'], [0, 1, '0', '1', true, false], true)) {
      $rs['msg'] = 'Active must be a boolean value.';
      return $rs;
    }
  
    return self::api_success('Valid.');
  }
  
  public static function validate_landmark_payload($params) {
    $rs = self::api_error('Validation failed.');
  
    if (empty($params['barangay_id'])) {
      $rs['msg'] = 'Barangay is required.';
      return $rs;
    }
    if (empty($params['name']) || strlen($params['name']) > 255) {
      $rs['msg'] = 'Landmark name is required and must be 255 characters or less.';
      return $rs;
    }
    if (!isset($params['map_latitude']) || !is_numeric($params['map_latitude'])) {
      $rs['msg'] = 'Latitude is required and must be numeric.';
      return $rs;
    }
    if (!isset($params['map_longitude']) || !is_numeric($params['map_longitude'])) {
      $rs['msg'] = 'Longitude is required and must be numeric.';
      return $rs;
    }
    if (abs((float) $params['map_latitude']) > 90) {
      $rs['msg'] = 'Latitude must be between -90 and 90.';
      return $rs;
    }
    if (abs((float) $params['map_longitude']) > 180) {
      $rs['msg'] = 'Longitude must be between -180 and 180.';
      return $rs;
    }
  
    return self::api_success('Valid.');
  }
  
  public static function validate_menu_item($params) {
    $rs = self::api_error('Validation failed.');
  
    if (empty($params['item']) || strlen($params['item']) > 255) {
      $rs['msg'] = 'Menu item name is required and must be 255 characters or less.';
      return $rs;
    }
    if (!isset($params['price']) || !is_numeric($params['price']) || (float) $params['price'] < 0) {
      $rs['msg'] = 'Price is required and must be a non-negative decimal.';
      return $rs;
    }
  
    return self::api_success('Valid.');
  }
}
