# 05. Laravel 8 での変更（7.x → 8.x）

- 公式ガイド: https://laravel.com/docs/8.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/7.x...8.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

## 確認項目

- [ ] **L80-01** 🔴🔍 **SeederとFactoryの名前空間化**（Seeder & Factory Namespaces）
  - OK: `database/seeds` が `database/seeders` になり、Seederに `namespace Database\Seeders;` がある。`composer.json` の `autoload` に `classmap` がなく、`psr-4` に `"Database\\Factories\\": "database/factories/"` と `"Database\\Seeders\\": "database/seeders/"` がある
  - CIやデプロイのスクリプトの `db:seed --class=...` も確認する
- [ ] **L80-02** 🧹🔍 **モデルファクトリのクラス化**（Model Factories）
  - OK: `$factory->define(...)` と `factory(User::class)` がなく、クラスベースのファクトリ（`User::factory()`）とモデルの `use HasFactory;` になっている
  - `fzaninotto/faker` ではなく `fakerphp/faker` が入っている（PHP 8非対応のため）
- [ ] **L80-03** 🧹🔍 **`laravel/legacy-factories`**: 残っているなら、L80-02 の書き直しの対象
- [ ] **L80-04 / L80-05** 🟡🔍 **ページネーションのデフォルトがTailwind CSSに**（Pagination Defaults）
  - OK: Bootstrapを使っている画面があるなら、`AppServiceProvider` の `boot` に `Paginator::useBootstrap()`（Bootstrap 5なら `useBootstrapFive()`、4なら `useBootstrapFour()`）がある
  - **ない場合、エラーにならずにページ送りのリンクの見た目が崩れる**（Tailwindのクラスが当たらない）
  - **5.6のデフォルトはBootstrap 4**（`pagination::bootstrap-4`）で、13の `Paginator::useBootstrap()` もBootstrap 4。5.6のときの見た目に戻すなら `useBootstrap()`（= `useBootstrapFour()`）。CSSをBootstrap 5に上げているなら `useBootstrapFive()`。**実際に読み込んでいるCSSのバージョンに合わせる**
  - 独自のページネーションのビュー（`resources/views/vendor/pagination`）を使っている箇所は、この設定の影響を受けない
  - 13.xで、Bootstrap 3のビュー名が `pagination::bootstrap-3` などになった（L130-07）
- [ ] **L80-06** 🟡🔍 **キューの `retryAfter` → `backoff`、`timeoutAt` → `retryUntil`**
  - OK: ジョブ・メール・通知・リスナーに `retryAfter` / `timeoutAt` のメソッドやプロパティが残っていない
  - **残っていても、エラーにならずに無視される**。リトライの間隔や期限が効かなくなる
- [ ] **L80-07** 🔴🔍 **ジョブチェーンの `allOnQueue()` / `allOnConnection()` の削除**
  - OK: `withChain([...])` と組み合わせている箇所が、`->onConnection('x')->onQueue('y')->dispatch()` の形
- [ ] **L80-08** ⚙️🔍 **`php artisan down --message` の削除**
  - OK: デプロイのスクリプト・CIの設定・手順書に `--message` が残っていない（メンテナンス画面は `--render` などで出す）
- [ ] **L80-09** 🟡🔍 **モデルの `increment` / `decrement` でイベントが発火**（Increment / Decrement Events）
  - OK: `$post->increment('views')` などで、`updating` `updated` `saving` `saved` のオブザーバーが動いても問題ない（**閲覧数のカウントのたびに更新日時や監査ログが更新される**、などがないか）
- [ ] **L80-10** 🔴🔍 **`EventServiceProvider` の `register` で `parent::register()` が必要**
  - OK: `register()` を定義しているなら、最初に `parent::register();` がある（**ないとイベントのリスナーが一切登録されず、エラーも出ない**）
- [ ] **L80-11** 🔴🔍 **`elixir()` / `Mail::sendNow` / `decodeResponseJson` の引数の削除**
- [ ] **L80-12 / L80-13** 🔴🔍 **コントローラの名前空間の自動付与**（Automatic Controller Namespace Prefixing）
  - OK: ルートが `'UserController@index'` のような文字列の形なら、`RouteServiceProvider` の `$namespace = 'App\Http\Controllers'` が残っていて、ルートの登録で使われている。**11.x以降の `bootstrap/app.php` の構成に移行した場合、`$namespace` の仕組みはない**ので、`[UserController::class, 'index']` の形に書き換えるか、`Route::namespace('App\Http\Controllers')->group(...)` で囲む
  - `action('UserController@index')` のようなURLの生成も同様
- [ ] **L80-14** ⚙️ **`failed_jobs` テーブルの `uuid` カラム**（Failed Jobs Table Batch Support）
  - OK: `config/queue.php` の `failed.driver` が `database-uuids` なら、`failed_jobs` に `uuid` カラムがある（ないと**ジョブの失敗の記録そのものが失敗する**）。ジョブのバッチ処理を使うなら `job_batches` テーブルもある
- [ ] **L80-15** ⚙️ **メンテナンスモードの事前レンダリング**（Maintenance Mode Updates）
  - OK: `public/index.php` に `storage/framework/maintenance.php` を読み込む処理がある（新しい雛形の `public/index.php` に合わせていればOK）。**`artisan down` 中に画面がエラーにならないか**を確認する
- [ ] **L80-16** 🟡 **コレクションの `isset` / `offsetExists` が `null` を「存在しない」と判定**
  - OK: `isset($collection['key'])` で、値が `null` の要素の存在を判定していない（`$collection->has('key')` を使う）
- [ ] **L80-17** 🟡 **`unique` / `exists` ルールがモデルのDB接続を使う**（Database Rule Connections）
  - OK: 複数のDB接続を使っている場合、`unique:App\Models\X` の検証先の接続が意図どおり
- [ ] **L80-18** 🟡 **テストの `assertExactJson` が数値キーの配列の順番まで比較**: 順番を問わないなら `assertSimilarJson`
- [ ] **L80-19** ⚙️ **モデルの置き場所**（`app/Models`）
  - OK: モデルを `app/Models` に移した場合、**ポリモーフィックなリレーションの `*_type` カラムに保存されたクラス名（`App\User` など）**がDB上で更新されているか、`Relation::enforceMorphMap` / `morphMap` で対応している（**エラーにならずにリレーションが空になる**）。`config/auth.php` の `providers.users.model` も確認する

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `Castable::castUsing(array $arguments)`
- [ ] `Dispatcher` contractの `listen($events, $listener = null)`
- [ ] `Session` contractの `pull`
- [ ] `Manager` の `$app` → `$container`
- [ ] `dragonmantank/cron-expression` を直接使っている場合（3.x）
