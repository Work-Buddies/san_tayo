<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Repositories\ListingRepoInterface;

class ListingController extends Controller
{
  public function index(Request $request, ListingRepoInterface $repo)
  {
    return response()->json($repo->index($request->user()));
  }

  public function show(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->show($id, $request->user()));
  }

  public function store(Request $request, ListingRepoInterface $repo)
  {
    return response()->json($repo->store($request->user(), $request->all()));
  }

  public function update(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->update($request->user(), $id, $request->all()));
  }

  public function deactivate(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->deactivate($request->user(), $id));
  }

  public function activate(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->activate($request->user(), $id));
  }

  public function destroy(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->destroy($request->user(), $id));
  }

  public function approve(ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->approve($id));
  }

  public function reject(ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->reject($id));
  }

  public function store_image(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->store_image($request->user(), $id, $request->all()));
  }

  public function update_image(Request $request, ListingRepoInterface $repo, $id, $img_id)
  {
    return response()->json($repo->update_image($request->user(), $id, $img_id, $request->all()));
  }

  public function destroy_image(Request $request, ListingRepoInterface $repo, $id, $img_id)
  {
    return response()->json($repo->destroy_image($request->user(), $id, $img_id));
  }

  public function restore_image(Request $request, ListingRepoInterface $repo, $id, $img_id)
  {
    return response()->json($repo->restore_image($request->user(), $id, $img_id));
  }

  public function store_menu(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->store_menu($request->user(), $id, $request->all()));
  }

  public function update_menu(Request $request, ListingRepoInterface $repo, $id, $menu_id)
  {
    return response()->json($repo->update_menu($request->user(), $id, $menu_id, $request->all()));
  }

  public function destroy_menu(Request $request, ListingRepoInterface $repo, $id, $menu_id)
  {
    return response()->json($repo->destroy_menu($request->user(), $id, $menu_id));
  }

  public function restore_menu(Request $request, ListingRepoInterface $repo, $id, $menu_id)
  {
    return response()->json($repo->restore_menu($request->user(), $id, $menu_id));
  }

  public function sync_food_types(Request $request, ListingRepoInterface $repo, $id)
  {
    return response()->json($repo->sync_food_types($request->user(), $id, $request->all()));
  }

  public function destroy_food_type(Request $request, ListingRepoInterface $repo, $id, $food_type_id)
  {
    return response()->json($repo->destroy_food_type($request->user(), $id, $food_type_id));
  }

  public function restore_food_type(Request $request, ListingRepoInterface $repo, $id, $food_type_id)
  {
    return response()->json($repo->restore_food_type($request->user(), $id, $food_type_id));
  }
}
