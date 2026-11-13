# 03. Laravel 6 での変更（5.8 → 6.x）

- 公式ガイド: https://laravel.com/docs/6.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/5.8...6.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

## 確認項目

- [ ] **X-03** 🔴🔍 **`str_*` / `array_*` のグローバルヘルパーの削除**（String & Array Helpers Package）
  - OK: `str_slug` `str_random` `array_get` `array_only` `starts_with` `str_contains` などが、すべて `Str::` / `Arr::` に置き換わっていて、**`laravel/helpers` に依存していない**
  - **`config/` の中も確認する**。5.6の雛形の `config/session.php` と `config/cache.php` には `str_slug(env('APP_NAME', 'laravel'), '_')` がある
  - `laravel/helpers` で済ませていると、PHP 8.5の `array_first()` / `array_last()` と衝突する（X-01、`12_pitfalls_outside_official_guides.md`）
  - Bladeのテンプレートも対象。置き換えたら `php artisan view:clear`
- [ ] **L60-01** 🔴🔍 **`authorizeResource` には `viewAny` が必要**（Authorized Resources & `viewAny`）
  - OK: `authorizeResource` を使うコントローラのポリシーに、すべて `viewAny` がある（**ないと `index` が403になる**）
  - 関連: Laravel 11以降の新しい雛形のベースの `Controller` は `AuthorizesRequests` トレイトを使っていない。既存の `App\Http\Controllers\Controller` を新しい雛形で上書きしていたら、`authorizeResource` / `authorize` が未定義になる
- [ ] **L60-02** 🔴🔍 **`Input` ファサードの削除**
  - OK: `Input::get` → `Request::input`、その他の `Input::` → `Request::`。`config/app.php` の `aliases` に `Input` が残っていない
- [ ] **L60-03** 🔴🔍 **`Lang::trans` / `Lang::transChoice` / `Lang::getFromJson` の改名・統合**
  - OK: `Lang::get` / `Lang::choice` になっている（ヘルパーの `trans()` `trans_choice()` `__()` はそのまま使える）
- [ ] **L60-04** 🟡🔍 **ポリシーで `deny()` を `return` する**（Returning "Deny" Responses）
  - OK: `$this->deny(...)` が必ず `return $this->deny(...)` になっている（`return` しないと**許可されたまま**処理が進む場合がある）
- [ ] **L60-05** 🟡🔍 **スケジューラの `between` が日付をまたぐ範囲で正しく動く**（The `between` Method）
  - OK: `between('23:00', '4:00')` のような指定が、**夜間（23時〜4時）に動く**という意図になっている（5.8までは逆の時間帯で動いていた）
- [ ] **L60-06** 🟡🔍 **`BelongsTo::update` がアドホックな更新クエリに**（The `BelongsTo::update` Method）
  - OK: `$post->user()->update([...])` のような更新で、**マスアサインメントの保護やEloquentのイベント（オブザーバー）を期待していない**。期待するなら `$post->user->update([...])`
- [ ] **L60-07** 🟡🔍 **文字列の主キーには `$keyType` が必要**（Declaration Of Primary Key Type）
  - OK: 主キーが文字列のモデル（`$incrementing = false`）に `protected $keyType = 'string';` がある
  - ないと、Eagerロード（`with()`）のときにキーが整数としてクエリに埋め込まれ、`'abc'` のような文字列のキーが `0` になって、**エラーにならずにリレーションが空になる**ことがある
- [ ] **L60-08** ⚙️🔍 **`queue:work` のデフォルトの試行回数が1回に**（Queue Retry Limit）
  - OK: Supervisor・systemd・Procfile・デプロイのスクリプトなど、**ワーカーの起動設定で `--tries` を明示している**か、ジョブクラスに `$tries` がある
  - 失敗したジョブを記録する `failed_jobs` テーブルがある（8.xのバッチ処理を使うなら `uuid` カラムも。L80-14）
- [ ] **L60-09** 🟡🔍 **`route()` / `action()` の余分なパラメータがクエリ文字列に**（Route URL Generation & Extra Parameters）
  - OK: ルートのパスにないキーを渡している呼び出しで、生成されるURLが意図どおり（例: `Route::get('/profile/{location?}')` に `route('profile', ['status' => 'active'])` は `/profile?status=active` になる）
  - 確認: 旧版と新版で、主な画面のリンクのURLを比べる
- [ ] **L60-10** 🔴🔍 **メール確認の再送ルートがPOSTに、確認のURLに `{hash}` が追加**（Email Verification）
  - OK: `email/resend` へのリンクがPOSTのフォーム（`@csrf` 付き）になっている。確認のURLが `/email/verify/{id}/{hash}`
- [ ] **L60-11** ⚙️ **Redisのデフォルトのクライアントが `phpredis` に**（Redis Default Client）
  - OK: `config/database.php` の `redis.client` が明示されていて、`phpredis` なら全サーバー（Web・ワーカー・バッチ）に `redis` 拡張が入っている。`predis` なら `predis/predis` がPHP 8.5に対応した版
- [ ] **L60-12** 🟡 **`toArray` が `Arrayable` の属性を配列にする**
  - OK: モデルの属性に `Arrayable` を実装したオブジェクトを入れている場合、JSONの出力が意図どおり
- [ ] **L60-13** ⚙️ **Carbon 1の非対応** → 最終的にはCarbon 3が必須（L110-03）
- [ ] **L60-14** 🔴 **MandrillとSparkPostのメールドライバ、Rackspaceのストレージドライバの削除**
  - OK: 使っていない、またはコミュニティのパッケージに置き換え済み
- [ ] **L60-15** 🔴 **Nexmoのルーティングの削除**
  - OK: Nexmo（Vonage）の通知を使うモデルに `routeNotificationForVonage` がある
- [ ] **L60-16** 🟡 **`PasswordBroker` がパスワードを検証しない**（Password Validation）
  - OK: 標準の `ResetPasswordController` 以外で `Password` ファサードを使っている場合、自分でパスワードを検証している
- [ ] **L60-17** 🟡 **`cursor()` が `LazyCollection` を返す**
  - OK: `cursor()` の結果を `Generator` の型で受けていない

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `Illuminate\Auth\Access\Response` のコンストラクタの変更（手動で生成している場合）
- [ ] `Gate` contractの `inspect`、`MustVerifyEmail` contractの `getEmailForVerification`、`Translator` contractの `get` / `choice`
- [ ] FormRequestの `validationData` が `public` に
- [ ] Capsuleの `table` メソッド（Laravelの外で `illuminate/database` を使う場合）
- [ ] ⚙️ `AWS_REGION` → `AWS_DEFAULT_REGION`（Vaporを使う場合、またはS3の設定を新しい雛形に合わせた場合。**`.env` 側の名前も合っているか**）
