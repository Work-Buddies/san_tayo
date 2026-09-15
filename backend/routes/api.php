<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\AccountController;
use App\Http\Controllers\LookupController;
use App\Http\Controllers\LandmarkController;
use App\Http\Controllers\ListingController;

Route::get('/health', [HealthController::class, 'ping']);

Route::middleware(['client.key'])->group(function () {

  // Public auth
  Route::post('/auth/register',   [AuthController::class, 'register']);
  Route::post('/auth/verify-otp', [AuthController::class, 'verify_otp']);
  Route::post('/auth/resend-otp', [AuthController::class, 'resend_otp']);
  Route::post('/auth/login',      [AuthController::class, 'login']);

  // Public lookups
  Route::get('/lookups/barangays',        [LookupController::class, 'barangays']);
  Route::get('/lookups/food-types',       [LookupController::class, 'food_types']);
  Route::get('/lookups/listing-statuses', [LookupController::class, 'listing_statuses']);

  // Public browse (students) — approved + active only
  Route::get('/listings',      [ListingController::class, 'index']);
  Route::get('/listings/{id}', [ListingController::class, 'show']);

  Route::middleware('auth:sanctum')->group(function () {

    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me',      [AuthController::class, 'me']);

    // User → Business upgrade (no admin upgrade endpoint)
    Route::post('/account/upgrade-business', [AccountController::class, 'upgrade_business'])
      ->middleware('auth.level:user');

    // Landmarks
    Route::get('/landmarks',             [LandmarkController::class, 'index']);
    Route::post('/landmarks',            [LandmarkController::class, 'store'])
      ->middleware('auth.level:business,admin');
    Route::put('/landmarks/{id}',        [LandmarkController::class, 'update'])
      ->middleware('auth.level:business,admin');

    // Listing management — business + admin
    Route::middleware('auth.level:business,admin')->group(function () {
      Route::post('/listings',                    [ListingController::class, 'store']);
      Route::put('/listings/{id}',                [ListingController::class, 'update']);
      Route::patch('/listings/{id}/deactivate',   [ListingController::class, 'deactivate']);
      Route::patch('/listings/{id}/activate',     [ListingController::class, 'activate']);
      Route::delete('/listings/{id}',             [ListingController::class, 'destroy']);

      // Images (soft delete + restore)
      Route::post('/listings/{id}/images',                         [ListingController::class, 'store_image']);
      Route::put('/listings/{id}/images/{img_id}',                 [ListingController::class, 'update_image']);
      Route::delete('/listings/{id}/images/{img_id}',                [ListingController::class, 'destroy_image']);
      Route::patch('/listings/{id}/images/{img_id}/restore',         [ListingController::class, 'restore_image']);

      // Menu (soft delete + restore)
      Route::post('/listings/{id}/menu',                           [ListingController::class, 'store_menu']);
      Route::put('/listings/{id}/menu/{menu_id}',                    [ListingController::class, 'update_menu']);
      Route::delete('/listings/{id}/menu/{menu_id}',                 [ListingController::class, 'destroy_menu']);
      Route::patch('/listings/{id}/menu/{menu_id}/restore',          [ListingController::class, 'restore_menu']);

      // Food types (soft delete via sync)
      Route::put('/listings/{id}/food-types',                      [ListingController::class, 'sync_food_types']);
      Route::delete('/listings/{id}/food-types/{food_type_id}',      [ListingController::class, 'destroy_food_type']);
      Route::patch('/listings/{id}/food-types/{food_type_id}/restore', [ListingController::class, 'restore_food_type']);
    });

    // Admin-only moderation (future-ready)
    Route::middleware('auth.level:admin')->group(function () {
      Route::patch('/listings/{id}/approve',  [ListingController::class, 'approve']);
      Route::patch('/listings/{id}/reject',   [ListingController::class, 'reject']);
    });
  });
});
