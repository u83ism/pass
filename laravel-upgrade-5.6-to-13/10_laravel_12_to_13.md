# 10. Laravel 13 での変更（12.x → 13.x）

- 公式ガイド: https://laravel.com/docs/13.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/12.x...13.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

> Laravel Boost（https://github.com/laravel/boost ）はLaravel公式のMCPサーバーで、`/upgrade-laravel-v13` コマンドで12→13のアップグレードの手順をAIアシスタントに案内させられる。ローカルで動くので、Web検索が使えない環境でも使える（導入の可否は組織のルールに従う）。

## 確認項目

### セキュリティ（CSRF・シリアライズ）

- [ ] **L130-01** 🔴🔍 **CSRFのミドルウェアが `PreventRequestForgery` に改名され、`Sec-Fetch-Site` ヘッダーでリクエスト元を検証**（Request Forgery Protection）
  - OK: `VerifyCsrfToken` / `ValidateCsrfToken` の直接の参照（テストでの `withoutMiddleware`、ルートでの除外、`App\Http\Middleware\VerifyCsrfToken` の継承元）が `PreventRequestForgery` になっている（旧名は非推奨のエイリアスとして残っている）
  - **次の経路を、本番相当の環境で実際に送信して確認する**（テストでは `Sec-Fetch-Site` が付かないので見つからない）
    - 別のドメイン・サブドメインからのフォームの送信
    - 外部サービスからのPOST（決済サービスの戻り先、Webhook、SSOのコールバック）
    - iframeの中のフォーム、ブラウザの拡張機能やネイティブアプリからの送信
- [ ] **L130-02** ⚙️🔍 **CSRFの除外の設定**: `$except`（または `validateCsrfTokens(except: [...])`）が、L130-01 で弾かれる経路を正しく除外している
- [ ] **L130-03** ⚙️🔍 **キャッシュの `serializable_classes`**（Cache `serializable_classes` Configuration）
  - OK: `config/cache.php` の `serializable_classes` が `false` なら、**キャッシュにPHPのオブジェクト（Eloquentのモデルやコレクション、DTO）を入れていない**。入れているなら、そのクラスを列挙している
  - キー自体がなければ制限なし（従来どおり）。**AIが `config/cache.php` を新しい雛形に合わせていると `false` になり、オブジェクトを入れたキャッシュがエラーにならずに読めなくなる**（キャッシュが常に外れて、性能だけが落ちる場合もある）
- [ ] **L130-04** ⚙️🔍 **セッションの `serialization`**（Session `serialization` Configuration）
  - OK: `config/session.php` の `serialization` が `php` のまま、または `json` に変えた上で「セッションにオブジェクトを入れていない」「リリース時に全ユーザーがログアウトされてよい」ことを確認済み
- [ ] **L130-15** ⚙️ **キャッシュ・Redisの接頭辞とセッションのCookie名のデフォルト**（Cache Prefixes and Session Cookie Names）
  - OK: `CACHE_PREFIX` `REDIS_PREFIX` `SESSION_COOKIE` が `.env` か設定ファイルで明示されている。**フレームワークのデフォルトに頼っていると、`laravel_session` が `laravel-session` に変わり、リリース時に全ユーザーがログアウトされる**

### PHP 8.5との関係

- [ ] **X-01** 🔴🔍 **`array_first()` / `array_last()` の衝突**（Symfony PHP 8.5 Polyfill and Global Function Conflicts）
  - OK: `array_first(` / `array_last(` の呼び出しがすべて `Arr::first()` / `Arr::last()` に置き換わり、`laravel/helpers` に依存していない
  - `laravel/helpers` の `array_first($array, $callback, $default)` はコールバックで絞り込む関数。PHP 8.5本体の `array_first($array)` は最初の要素を返すだけ。PHP 8.5では本体が優先されるので、**コールバックを渡す呼び出しはエラーになり、1引数の呼び出しはたまたま動く**
  - 詳細は `12_pitfalls_outside_official_guides.md`

### DB・Eloquent

- [ ] **L130-05** 🔴🔍 **MySQL / MariaDBの `upsert` で `uniqueBy` が空だと例外**
- [ ] **L130-16** 🔴 **MySQLの `JOIN` 付きの `DELETE` で `ORDER BY` / `LIMIT` がSQLに含まれる**
  - OK: `->join(...)->orderBy(...)->limit(...)->delete()` のような処理がない。MySQLと11.8.1より前のMariaDBでは例外になる。**以前は `ORDER BY` / `LIMIT` が黙って無視され、範囲を限定しない削除が実行されていた**ので、その処理の意図と過去の削除の結果も確認する
- [ ] **L130-14** 🔴🔍 **モデルの起動中に同じモデルをインスタンス化すると `LogicException`**: `boot()` / `boot*()` の中で `new static` や `static::create()` などをしていない
- [ ] **L130-10** 🟡🔍 **ポリモーフィックな多対多で、独自のピボットのテーブル名の推測が複数形に**: 依存している場合はピボットモデルに `$table` を明示する
- [ ] **L130-17** 🟡 **モデルのコレクションをシリアライズして復元すると、Eagerロードしたリレーションも復元される**（キューのジョブなど）

### キュー・イベント

- [ ] **L130-06** 🔴🔍 **`JobAttempted` イベントの `$exceptionOccurred` → `$exception`、`QueueBusy` イベントの `$connection` → `$connectionName`**
- [ ] **L130-18** 🟡 **キューに入れた通知が `#[DeleteWhenMissingModels]` / `$deleteWhenMissingModels` を尊重**
- [ ] **L130-19** 🟡 **`withScheduling()` で登録したスケジュールの登録のタイミングが遅延**

### 表示・その他

- [ ] **L130-07** 🟡🔍 **ページネーションのBootstrap 3のビュー名**: `pagination::default` → `pagination::bootstrap-3`、`pagination::simple-default` → `pagination::simple-bootstrap-3`
- [ ] **L130-11** 🟡🔍 **`Js::from`（`@js`）がUnicodeをエスケープしない**: 日本語が `\uXXXX` ではなくそのまま出力される。出力の比較をしているテストやスナップショット
- [ ] **L130-12** 🟡🔍 **パスワードリセットのメールの件名**: `Reset Password Notification` → `Reset your password`。**日本語化のための翻訳ファイル（`lang/ja.json` など）のキーが旧い件名のままだと、件名が英語に戻る**
- [ ] **L130-13** 🟡🔍 **ドメインを指定したルートが優先して照合される**: ドメインなしのルートと同じパスがある場合のマッチが意図どおり
- [ ] **L130-08** 🟡🔍 **Managerの `extend` のクロージャの `$this` がマネージャーに**: サービスプロバイダの `$this` を使っていた場合は `use (...)` で渡す
- [ ] **L130-09** 🟡🔍 **`Str` のファクトリ（UUID・ULID・ランダム文字列）がテストの終了時にリセット**
- [ ] **L130-20** 🟡 **`Container::call` がnull許容のクラスの引数のデフォルト値を尊重**（12.xのコンストラクタ注入と同じ挙動。L120-09）
- [ ] **L130-21** ⚙️ **PHPUnit 12**: docblockのアノテーションは削除された。`@test` だけで `test` で始まらない名前のメソッドは、**エラーにならずに実行されなくなる**（`12_pitfalls_outside_official_guides.md`）

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] Cacheの `Store` / `Repository` contractの `touch`
- [ ] `Bus\Dispatcher` contractの `dispatchAfterResponse`、`ResponseFactory` contractの `eventStream`、`MustVerifyEmail` contractの `markEmailAsUnverified`
- [ ] `Queue` contractの `pendingSize` `delayedSize` `reservedSize` `creationTimeOfOldestPendingJob`
- [ ] HTTPクライアントの `Response::throw` / `throwIf` のシグネチャ
