# 06. Laravel 9 での変更（8.x → 9.x）

- 公式ガイド: https://laravel.com/docs/9.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/8.x...9.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

> **ファイル操作（Flysystem 3）とメール（Symfony Mailer）**が大きく変わった版。どちらも本番と同じ方式（S3、SMTPなど）で手で確認すること。

## 確認項目

### ファイル操作（Flysystem 3.x）

- [ ] **L90-01** 🟡🔍 **書き込みの失敗が例外ではなく `false` に**（Write Exceptions）
  - OK: `Storage::put` などの書き込みの戻り値を確認しているか、`config/filesystems.php` の**すべてのディスク**に `'throw' => true` がある
  - ないと、**S3の権限の誤りやディスクの容量不足でも、エラーにならずに保存されない**
- [ ] **L90-02** 🟡🔍 **存在しないファイルの読み込みが例外ではなく `null` に**（Reading Missing Files）
  - OK: `try { Storage::get(...) } catch (FileNotFoundException $e)` で分岐している箇所が、`Storage::exists()` や戻り値の `null` の確認に変わっている（`throw` を `true` にしていれば例外が出る）
- [ ] **L90-03** ⚙️🔍 **`config/filesystems.php` の `throw` の設定**（L90-01 と合わせて確認）
- [ ] **L90-18** 🟡 **書き込みが既存のファイルをデフォルトで上書き**（Overwriting Existing Files）
  - OK: 同じパスに書き込む可能性がある処理（アップロードのファイル名の衝突など）で、上書きされて困る箇所は事前に存在を確認している
- [ ] **L90-19** 🔴 **S3・FTP・SFTPのアダプタ**（Driver Prerequisites）
  - OK: 使っているなら `league/flysystem-aws-s3-v3` `^3.0`、`league/flysystem-ftp` `^3.0`、`league/flysystem-sftp-v3` `^3.0` が入っている
- [ ] **L90-20** ⚙️ **SFTPの秘密鍵のパスフレーズの設定キー**: `password` → `passphrase`
- [ ] **L90-21** 🔴 **独自のファイルシステムドライバ**（Custom Filesystems）
  - OK: `Storage::extend` のコールバックが `Illuminate\Filesystem\FilesystemAdapter` を返す
- [ ] **L90-22** 🧹 **"cached adapters" の削除**: ディスクの設定の `cache` キーは削除してよい

### メール（Symfony Mailer）

- [ ] **L90-04** 🔴🔍 **SwiftMailerの廃止**（Symfony Mailer）
  - OK: `Swift_*` クラス、`withSwiftMessage` / `getSwiftMessage`、`swiftmailer` 系のパッケージが残っていない（`withSymfonyMessage` などに置き換え）
  - Mailgunなら `symfony/mailgun-mailer` と `symfony/http-client`、Postmarkなら `symfony/postmark-mailer` と `symfony/http-client` が入っている
  - `Mail::send` などの戻り値が `SentMessage`（`void` ではない）。`MessageSent` イベントの `message` は `Symfony\Component\Mime\Email`
  - 送信後に失敗した宛先を取得する処理は使えない（失敗すると例外）
- [ ] **L90-23** ⚙️ **SMTPの設定**
  - OK: `config/mail.php` の SMTP の `stream` オプション（TLSの検証の無効化など）が、Symfony Mailerの設定の形に書き換わっている。`auth_mode` は不要。Message-IDのドメインの指定（`mime.idgenerator.idright`）は使えない
  - **自前のSMTPサーバーやTLSの設定によっては、ここで送信できなくなる**。本番と同じ設定で送信を確認する

### その他

- [ ] **L90-05** ⚙️🔍 **Postgresの `schema` → `search_path`**（`config/database.php`）
- [ ] **L90-06** 🟡🔍 **独自のキャストの `set` に `null` が渡る**（Custom Casts & `null`）
  - OK: `CastsAttributes` を実装したクラスの `set` が、`$value` が `null` の場合を処理している
- [ ] **L90-07** 🟡🔍 **`when` / `unless` にクロージャを渡すと、その戻り値で判定**
  - OK: `->when(function () {...}, ...)` の形で、クロージャの戻り値が条件として正しい（以前はクロージャ自体が常に真として扱われ、常に実行されていた）
- [ ] **L90-08** 🟡🔍 **HTTPクライアントのデフォルトのタイムアウトが30秒**（Default Timeout）
  - OK: 30秒以上かかりうる外部API（大きなファイルの送受信、帳票の生成など）の呼び出しに `Http::timeout(...)` がある
- [ ] **L90-09** 🔴🔍 **`assertDeleted` → `assertModelMissing`**
- [ ] **L90-10** 🔴🔍 **`password` ルール → `current_password`**
  - OK: 「現在のパスワードと一致するか」の検証に `current_password` を使っている（`password` のままだと、ルールが存在しないエラーになる）
- [ ] **L90-11** 🔴🔍 **`fideloper/proxy` の削除と `TrustProxies`**（Trusted Proxies）
  - OK: `app/Http/Middleware/TrustProxies.php` が `Illuminate\Http\Middleware\TrustProxies` を継承し、`$headers` が `Request::HEADER_X_FORWARDED_FOR | ..._HOST | ..._PORT | ..._PROTO | ..._AWS_ELB` の形
  - ⚙️ **ロードバランサーの配下で、`$request->ip()`・`url()`・`https` の判定が正しいか**を本番相当の環境で確認する（間違っていると、HTTPSのURLがHTTPで生成される、IP制限が効かない、などが**エラーにならずに**起きる）
- [ ] **L90-12** 🔴🔍 **`reduceWithKeys` → `reduce`、`reduceMany` → `reduceSpread`、`registerCustomDoctrineType` の削除**
- [ ] **L90-13** 🔴🔍 **グローバルの `str()` ヘルパーの追加**: 自前で `str` 関数を定義していない
- [ ] **L90-14** 🟡🔍 **BelongsToManyの `firstOrNew` / `firstOrCreate` / `updateOrCreate` の比較対象**
  - OK: `$user->roles()->firstOrCreate([...])` の第1引数が、**中間テーブルではなく関連先のテーブル**（`roles`）のカラムとして意図どおり
- [ ] **L90-15 / L90-16** 🔴🔍 **CORSの旧パッケージ**: `fruitcake/laravel-cors` / `barryvdh/laravel-cors` とその `HandleCors` の参照が残っていない（フレームワーク内蔵の `Illuminate\Http\Middleware\HandleCors` を使う。公式ガイドではなく9.2以降の雛形の変更）
- [ ] **L90-17** 🔴🔍 **`facade/ignition` → `spatie/laravel-ignition`**
- [ ] **L90-24** 🟡 **検証していない配列のキーが `validated()` から常に除外**（Unvalidated Array Keys）
  - OK: `'items' => 'array'` のようにキーを指定しない `array` ルールの値を `validated()` から取り出して使っている箇所で、必要なキーが残っている（L57-03 と合わせて確認）
- [ ] **L90-25** 🟡 **HTTPクライアントの `Http::fake()` がGuzzleのミドルウェアを通し、DIで注入したクライアントにも効く**（テストの挙動）
- [ ] **L90-26** 🔴 **`Request::getSession()` がセッションがないと例外**
- [ ] **L90-27** 🔴 **`opis/closure` → `laravel/serializable-closure`**: `Illuminate\Queue\SerializableClosure` を直接使っていない
  - ⚙️ アップグレード前にキューに積まれたクロージャのジョブは、新しい版では復元できない。**デプロイの前にキューを空にしたか**
- [ ] **L90-28** 🟡 **Bladeの `@checked` `@disabled` `@selected` とVueの衝突**: Vueの `@selected` などのイベントを書いているテンプレートは `@@selected` にする
- [ ] **L90-29** 🟡 **Bladeで `LazyCollection` を回すとき `$loop` が使えない**
- [ ] **L90-30** ⚙️ **`lang` ディレクトリ**: 言語ファイルが `resources/lang` と `lang` のどちらにあり、どちらが読まれているか（両方にあると片方が無視される）
- [ ] **L90-31** 🔴 **Nexmo → Vonage の通知チャンネル**（`laravel/vonage-notification-channel`）

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] **戻り値の型**（PHP Return Types）: Laravelのコアクラスを継承して `count` `getIterator` `getSize` `jsonSerialize` `offsetExists` `offsetGet` `offsetSet` `offsetUnset` を上書きしている場合、戻り値の型が必要（PHP 8.1以降は組み込みのインターフェースでも必要。P81-05）
- [ ] 独自のセッションハンドラ（`SessionHandlerInterface`）の戻り値の型
- [ ] `Application` contractの `storagePath($path)` / `langPath($path)`
- [ ] 例外ハンドラの `ignore` が `public`、独自の例外ハンドラは `ExceptionHandler::class` でバインド
- [ ] `Enumerable` contractの `sole`、`Container` contractの `scoped` / `scopedIf`、`ContextualBindingBuilder` の `giveConfig`、`Encrypter` contractの `getKey`、`FailedJobProviderInterface::flush($hours)`
- [ ] 自前のファサードの `getFacadeAccessor` がオブジェクトではなく文字列を返す
- [ ] `touch($attribute = null)`、FormRequestの `validated($key = null, $default = null)` のシグネチャ
- [ ] ⚙️ `FILESYSTEM_DRIVER` → `FILESYSTEM_DISK`（`config/filesystems.php` を新しくした場合、**`.env` 側も**）
