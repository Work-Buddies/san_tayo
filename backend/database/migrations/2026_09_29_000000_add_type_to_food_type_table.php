<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
  public function up(): void
  {
    if (!Schema::hasTable('food_type')) {
      return;
    }

    if (!Schema::hasColumn('food_type', 'type')) {
      Schema::table('food_type', function (Blueprint $table) {
        $table->string('type', 32)->default('foodtype');
      });
    }

    $pax = ['1 pax', '2 pax', '3 pax', '4 pax', '5+ pax'];
    foreach ($pax as $name) {
      $exists = DB::table('food_type')
        ->where('name', $name)
        ->where('type', 'pax')
        ->exists();

      if ($exists) {
        continue;
      }

      DB::table('food_type')->insert([
        'id'          => (string) Str::uuid(),
        'name'        => $name,
        'description' => 'How many people this place can seat.',
        'type'        => 'pax',
      ]);
    }
  }

  public function down(): void
  {
    if (!Schema::hasTable('food_type') || !Schema::hasColumn('food_type', 'type')) {
      return;
    }

    DB::table('food_type')->where('type', 'pax')->delete();

    Schema::table('food_type', function (Blueprint $table) {
      $table->dropColumn('type');
    });
  }
};
