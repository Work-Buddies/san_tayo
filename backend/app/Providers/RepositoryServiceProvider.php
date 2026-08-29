<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Repositories\HealthRepoInterface;
use App\Repositories\HealthRepository;
use App\Repositories\AuthRepoInterface;
use App\Repositories\AuthRepository;
use App\Repositories\AccountRepoInterface;
use App\Repositories\AccountRepository;
use App\Repositories\LookupRepoInterface;
use App\Repositories\LookupRepository;
use App\Repositories\LandmarkRepoInterface;
use App\Repositories\LandmarkRepository;
use App\Repositories\ListingRepoInterface;
use App\Repositories\ListingRepository;

class RepositoryServiceProvider extends ServiceProvider
{
  public function register()
  {
    $this->app->bind(HealthRepoInterface::class, HealthRepository::class);
    $this->app->bind(AuthRepoInterface::class, AuthRepository::class);
    $this->app->bind(AccountRepoInterface::class, AccountRepository::class);
    $this->app->bind(LookupRepoInterface::class, LookupRepository::class);
    $this->app->bind(LandmarkRepoInterface::class, LandmarkRepository::class);
    $this->app->bind(ListingRepoInterface::class, ListingRepository::class);
  }

  public function boot()
  {
    //
  }
}
