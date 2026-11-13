# 08. Laravel 11 での変更（10.x → 11.x）

- 公式ガイド: https://laravel.com/docs/11.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/10.x...11.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

> 11.xで、アプリの構成（`bootstrap/app.php` での設定、`app/Http/Kernel.php` の廃止など）が大きく簡素化された。**公式は既存アプリの構成の移行を推奨していない**（10.xの構成のままでも動く）。**AIが新しい構成に移行していた場合は、下の L110-15 を重点的に確認する**。

## 確認項目

### マイグレーションとDB

- [ ] **L110-01** ⚙️🔍 **カラムの変更（`change()`）で、書かなかった属性が削除される**（Modifying Columns）
  - OK: `->change()` を含むマイグレーションで、残したい修飾子（`unsigned` `default` `comment` `nullable` など）をすべて書いている。または `php artisan schema:dump` でマイグレーションをまとめている
  - **既存の本番のDBには影響しない**（そのマイグレーションは実行済みのため）。影響するのは、**新しい環境（テスト用のDB、開発者の手元、CIの使い捨てのDB）で頭から流したとき**。本番とスキーマが違う環境でテストしていることになる
  - 確認: 空のDBに `php artisan migrate` を流し、本番のスキーマと比べる（`mysqldump --no-data` など）
- [ ] **L110-02** ⚙️🔍 **`double` / `float` の桁指定と `unsigned*` の浮動小数点数**（Floating-Point Types）
  - OK: `double('a', 8, 2)` のような桁の指定がない（11.xでは無視されるか、意味が変わる）。`unsignedDecimal` `unsignedDouble` `unsignedFloat` がない
  - L110-01 と同じく、**新しい環境のスキーマが本番と変わる**。金額などに `float` / `double` を使っている場合は特に注意（`decimal` を推奨）
- [ ] **L110-05** 🔴🔍 **空間データの型**（Spatial Types）: `point` `polygon` などは `geometry` / `geography` に
- [ ] **L110-06** 🔴🔍 **Doctrine DBALの削除**（Doctrine DBAL Removal）
  - OK: `getDoctrineSchemaManager()` `getDoctrineColumn()` `registerDoctrineType()` `Schema::getAllTables()` などが残っていない（`Schema::getTables()` `getColumns()` `getIndexes()` `getForeignKeys()` を使う）。`config/database.php` の `dbal` の設定は不要
- [ ] **L110-14** ⚙️ **SQLite 3.26.0以上・curl 7.34.0以上**（テストでSQLiteを使う場合も）
- [ ] **L110-16** 🟡 **MariaDB専用のドライバ**（Dedicated MariaDB Driver）
  - OK: MariaDBで `driver` を `mariadb` に変えた場合、既存のマイグレーションの `uuid()` が `char(36)` ではなくネイティブのUUID型を作る点を考慮している（`uuid` → `char('col', 36)` にする）

### 日付・レート制限・キャッシュ

- [ ] **L110-03** 🟡🔍 **Carbon 3の `diffIn*` が浮動小数点数・負の値を返す**（Carbon 3）
  - OK: `diffInDays` などの結果を**整数かつ正の値として使っている箇所**（「あと○日」の表示、期限切れの判定、日割りの料金計算、年齢の計算）が、`(int)`・`abs()`・比較の向きの見直しで対応されている
  - 例: `$now->diffInDays($deadline)` は、期限が過去なら**負の値**、端数があれば `2.5` のような値になる。`if ($days == 0)` や `if ($days > 7)` の判定が変わる
  - **12.x以降はCarbon 3が必須**なので、全件確認が必要
  - Carbonの移行ガイド: https://carbon.nesbot.com/guide/getting-started/migration.html （ほかにも、`createFromTimestamp` のタイムゾーンの扱いなどが変わっている）
- [ ] **L110-04** 🟡🔍 **レート制限が秒単位に**（Per-Second Rate Limiting）
  - OK: `new Limit(...)` `new GlobalLimit(...)` `new ThrottlesExceptions(...)` に渡す時間が、**分ではなく秒の値**になっている。`decayMinutes` → `decaySeconds`
  - `Limit::perMinute()` などの静的メソッドを使っていれば影響なし
- [ ] **L110-13** ⚙️🔍 **キャッシュのキーの接頭辞の後に `:` が付かない**（Cache Key Prefixes）
  - OK: DynamoDB・Memcached・Redisのキャッシュの接頭辞が変わってもよい（**既存のキャッシュは読めなくなる**）。外部のシステムやスクリプトがキャッシュのキーを直接参照している場合は、接頭辞の末尾に `:` を自分で付ける

### 認証

- [ ] **L110-08** 🟡🔍 **ログイン時のパスワードの自動の再ハッシュ**（Password Rehashing）
  - OK: パスワードのカラム名が `password` でないなら、`User` モデルに `protected $authPasswordName = '...';` がある。**ないと、ログインのたびに存在しないカラムへの書き込みでエラーになる**場合がある
  - 再ハッシュを望まないなら `config/hashing.php` に `'rehash_on_login' => false`
- [ ] **L110-09** 🟡🔍 **メール確認の通知の自動登録**（Email Verification Notification on Registration）
  - OK: `Registered` イベントに `SendEmailVerificationNotification` が二重に登録されていない（`EventServiceProvider` 以外の場所で登録していると、**確認メールが2通届く**）
- [ ] **L110-17** ⚪ `UserProvider` contractの `rehashPasswordIfRequired`、`Authenticatable` contractの `getAuthPasswordName`（独自のユーザープロバイダ・独自の `Authenticatable` 実装）
- [ ] **L110-18** ⚪ `AuthenticationException::redirectTo($request)`

### パッケージ

- [ ] **L110-11** ⚙️🔍 **Sanctum・Passport・Telescope・Cashier・Spark のマイグレーションのpublish**
  - OK: 各パッケージが自分のマイグレーションを自動で読み込まなくなったので、`php artisan vendor:publish --tag=sanctum-migrations` などでアプリに取り込まれている
  - **本番のDBにはテーブルが既にあるので、`migrate` で「テーブルが既に存在する」にならないこと**、かつ**新しい環境では作られること**を両方確認する
- [ ] **L110-12** ⚙️🔍 **Passportのパスワードグラントがデフォルトで無効**: 使っているなら `Passport::enablePasswordGrant()`
- [ ] **L110-19** 🔴 **Sanctumの設定**: `config/sanctum.php` の `middleware` が `authenticate_session` `encrypt_cookies` `validate_csrf_token`（13.xでは `PreventRequestForgery` の系統。L130-01）を指している
- [ ] **L110-10** 🔴🔍 **`spatie/once` の削除**（Laravelの `once()` と衝突）
- [ ] **L110-20** 🧹 **`doctrine/dbal` の削除**

### モデル・その他

- [ ] **L110-07** 🔴🔍 **基底のモデルに `casts()` メソッドが追加**: モデルに `casts` という名前のリレーションや独自のメソッドがない
- [ ] **L110-21** 🟡 **`sync` ドライバのジョブも "after commit" を尊重**（Synchronous Jobs in Database Transactions）
  - OK: `after_commit` を有効にしていて、テストやローカルで `sync` ドライバを使っている場合、ジョブの実行のタイミングが意図どおり
- [ ] **L110-15** ⚙️ **アプリの構成の移行をしたか**（Application Structure）
  - **移行していない場合**: 10.xの構成（`app/Http/Kernel.php`、`app/Console/Kernel.php`、`app/Exceptions/Handler.php`、各サービスプロバイダ）がそのまま使われていることを確認する
  - **移行した場合**: 次がすべて `bootstrap/app.php` などに移っているか
    - グローバル・グループ・ルートのミドルウェア（独自のミドルウェア、`$middlewarePriority` を含む）
    - ミドルウェアのエイリアス（`auth` `can` `verified` 以外の独自のもの）
    - スケジュール（`app/Console/Kernel.php` の `schedule()` → `routes/console.php` または `withSchedule`）。**移し忘れると、エラーにならずにバッチが動かなくなる**
    - 例外ハンドラの `report` / `render` / `$dontReport` / `$dontFlash`
    - `RouteServiceProvider` のルートの読み込み（API・管理画面などの独自のルートファイル）、`$namespace`（L80-12）、レート制限の定義
    - `EventServiceProvider` の `$listen` / `$subscribe`（イベントの自動検出に任せる場合は、リスナーの置き場所と `handle` の型宣言）
    - `AuthServiceProvider` の `$policies` と `Gate::define`
    - `config/app.php` の `providers` と `aliases`（11.xでは `bootstrap/providers.php` と、`aliases` は基本的に不要）
  - 確認: `php artisan route:list -v`（ミドルウェアの一覧）と `php artisan schedule:list` を旧版と比べる

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `Enumerable::dump(...$args)`、`ConnectionInterface` の `scalar`、`Mailer` contractの `sendNow`、`BatchRepository` の `rollBack`
- [ ] `Schema::getColumnType()` が実際の型を返す
- [ ] パッケージがサービスプロバイダを公開する場合の `ServiceProvider::addProviderToBootstrapFile`
