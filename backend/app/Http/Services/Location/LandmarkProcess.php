<?php

namespace App\Http\Services\Location;

use Illuminate\Support\Str;
use App\Libraries\api;
use App\Libraries\SharedFunction;
use App\Models\Location\LandmarkModel;

class LandmarkProcess
{
  /**
   * @uses: Get all landmarks with barangay
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function get_landmarks()
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $landmarks = api::get_landmarks();
    $data      = [];

    foreach ($landmarks as $landmark) {
      $data[] = [
        'id'            => $landmark->id,
        'name'          => $landmark->name,
        'map_latitude'  => $landmark->map_latitude,
        'map_longitude' => $landmark->map_longitude,
        'barangay_id'   => $landmark->barangay_id,
        'barangay'      => $landmark->barangay?->name,
      ];
    }

    $rs = SharedFunction::api_success('Landmarks retrieved.', $data);
    return $rs;
  }

  /**
   * @uses: Create a new landmark
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function create_landmark($params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $validation = SharedFunction::validate_landmark_payload($params);
    if ($validation['code'] != 1) {
      return $validation;
    }

    if (!api::barangay_exists($params['barangay_id'])) {
      $rs['msg'] = 'Barangay not found.';
      return $rs;
    }

    $landmark = LandmarkModel::create([
      'barangay_id'   => $params['barangay_id'],
      'name'          => $params['name'],
      'map_latitude'  => $params['map_latitude'],
      'map_longitude' => $params['map_longitude'],
    ]);

    $landmark->load('barangay');

    $rs = SharedFunction::api_success('Landmark created.', [
      'id'            => $landmark->id,
      'name'          => $landmark->name,
      'map_latitude'  => $landmark->map_latitude,
      'map_longitude' => $landmark->map_longitude,
      'barangay_id'   => $landmark->barangay_id,
      'barangay'      => $landmark->barangay?->name,
    ]);

    return $rs;
  }

  /**
   * @uses: Update an existing landmark
   * @author: Kai Yaneza
   * Date: 2026-08-29
   */
  public function update_landmark($id, $params)
  {
    $rs = ['code' => 0, 'title' => 'Ooops!', 'msg' => 'Something went wrong.'];

    $landmark = api::get_landmark($id);
    if (empty($landmark)) {
      $rs['msg'] = 'Landmark not found.';
      return $rs;
    }

    $validation = SharedFunction::validate_landmark_payload(array_merge([
      'barangay_id'   => $landmark->barangay_id,
      'name'          => $landmark->name,
      'map_latitude'  => $landmark->map_latitude,
      'map_longitude' => $landmark->map_longitude,
    ], $params));

    if ($validation['code'] != 1) {
      return $validation;
    }

    if (!empty($params['barangay_id']) && !api::barangay_exists($params['barangay_id'])) {
      $rs['msg'] = 'Barangay not found.';
      return $rs;
    }

    $fields = ['barangay_id', 'name', 'map_latitude', 'map_longitude'];
    foreach ($fields as $field) {
      if (array_key_exists($field, $params)) {
        $landmark->{$field} = $params[$field];
      }
    }

    $landmark->save();
    $landmark->load('barangay');

    $rs = SharedFunction::api_success('Landmark updated.', [
      'id'            => $landmark->id,
      'name'          => $landmark->name,
      'map_latitude'  => $landmark->map_latitude,
      'map_longitude' => $landmark->map_longitude,
      'barangay_id'   => $landmark->barangay_id,
      'barangay'      => $landmark->barangay?->name,
    ]);

    return $rs;
  }
}
