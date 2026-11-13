# 02. Laravel 5.8 での変更（5.7 → 5.8）

- 公式ガイド: https://laravel.com/docs/5.8/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/5.7...5.8
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

> この版は**エラーにならずに挙動だけ変わる**変更が特に多い。一気に上げた場合、ここが最も見落とされやすい。

## 確認項目

- [ ] **L58-01** 🟡🔍 **キャッシュのTTLが「分」から「秒」に**（TTL in seconds / PSR-16 Conformity）
  - OK: `Cache::put` `add` `remember` `putMany`、`cache([...], $ttl)`、`Cache::tags(...)->put` などに**整数で渡しているTTLが、秒のつもりの値**になっている（60分のつもりの `60` は60秒になる）。`now()->addMinutes(60)` のように `DateTime` で渡していればOK
  - あわせて: TTLを省略すると無期限、**TTLが0以下だと保存されず削除になる**。計算でTTLを出している箇所が0や負にならないか
  - キャッシュをラップした自前のクラスや、キャッシュを使うパッケージの設定（分単位を前提にしていないか）も確認する
- [ ] **L58-02** 🟡🔍 **アトミックロックの所有者の確認**（Lock Safety Improvements）
  - OK: `Cache::lock('foo')->release()` のように**取得したのとは別のインスタンスで解放していない**（取得した `$lock` で `release()` する。別のプロセスで解放するなら `$lock->owner()` を渡して `Cache::restoreLock('foo', $owner)->release()`）
  - 別インスタンスでの `release()` は、エラーにならずに解放されないだけなので、ロックが期限まで残る
- [ ] **L58-03** 🟡🔍 **パスワードの最小文字数のデフォルトが8文字に**（New Default Password Length）
  - OK: パスワードの設定・リセットのバリデーションと画面の説明が、意図した文字数で一致している（`min:6` が残っていても、パスワードリセットの仕組み側では8文字が要求される場合がある）
- [ ] **L58-04** 🔴🔍 **Nexmo・Slackの通知チャンネルが別パッケージに**（Nexmo / Slack Notification Channels）
  - OK: Slackの通知を使うなら `laravel/slack-notification-channel` が入っている。Nexmoは `laravel/vonage-notification-channel` に移行済み（`toNexmo` → `toVonage`）
- [ ] **L58-05** 🔴🔍 **コンテナの `tagged()` が配列ではなく `iterable` を返す**（Generators & Tagged Services）
  - OK: `tagged('x')[0]` のような添字でのアクセスや、`array` の型宣言がない
- [ ] **L58-06** 🟡🔍 **自動増分IDを持つ独自のピボットモデル**（Custom Pivot Models With Incrementing IDs）
  - OK: 自動増分の主キーを持つ独自のピボットモデルに `public $incrementing = true;` がある
- [ ] **L58-07** 🟡🔍 **`$defer = true` の遅延サービスプロバイダ**（Deferred Service Providers）
  - OK: `protected $defer = true;` が残っていない（無視されて即時ロードになる。動くが遅くなる）。遅延させたいなら `DeferrableProvider` を実装する
- [ ] **L58-08** 🟡🔍 **`env()` が実行時の変更を読まない**（Read-Only `env` Helper）
  - OK: `putenv()` などで実行時に変えた値を `env()` で読む処理がない（`config()` を使う）
  - 関連: **`config:cache` をしていると、`config/` の外の `env()` は常に `null`**（昔からの仕様だが、移行で `config:cache` を使い始めた場合に表面化する）
- [ ] **L58-09** 🔴🔍 **`Event::fire` の削除**（The `fire` Method）
  - OK: `fire()` がすべて `dispatch()` / `event()` になっている
- [ ] **L58-10** 🔴🔍 **BelongsToの `getForeignKey` などの改名**（BelongsTo `getForeignKey` & `getOwnerKey` Methods）
  - OK: BelongsToのリレーションに対して `getForeignKeyName` `getQualifiedForeignKeyName` `getOwnerKeyName` を使っている（モデルの `getForeignKey()` は別物で、そのまま使える）
- [ ] **L58-11** 🔴🔍 **テストの `setUp` / `tearDown` に `: void` が必須**（The `setUp` & `tearDown` Methods）
- [ ] **L58-12** 🟡🔍 **MySQLのJSONの値がクォートなしで返り、`->>` 演算子は不要に**（Unquoted MySQL JSON Values）
  - OK: クエリビルダで `col->>key` を使っていない。JSONの値の比較で、前後の `"` を前提にしていない
- [ ] **L58-13** 🔴🔍 **公開済みのMarkdownメールのディレクトリ名**（Markdown File Directory Change）
  - OK: `resources/views/vendor/mail/markdown` ではなく `resources/views/vendor/mail/text` になっている
- [ ] **L58-14** ⚙️ **`.env` の `#` 以降がコメントとして扱われる**（Environment Variable Parsing）
  - OK: **すべての環境（本番・ステージング・開発・CI）の `.env`** で、`#` を含む値がクォートされている（例: `DB_PASSWORD="abc#123"`）
  - クォートしていないと `abc` までしか読まれず、エラーにならないまま認証などに失敗する。phpdotenvはこの後のLaravelのバージョンでもさらにメジャーバージョンが上がっているので、**値にスペース・`$`・`"` を含むものも確認する**
  - 確認: `grep -nE '^[A-Z0-9_]+=[^"'"'"'].*#' .env*`
- [ ] **L58-15** 🟡 **不規則な複数形で終わるモデル名のテーブル名**（Model Names Ending With Irregular Plurals）
  - OK: 複数の単語からなり、最後の単語が不規則な複数形のモデル（例: `UserFeedback` → 5.7では `user_feedbacks`、5.8以降は `user_feedback`）に `protected $table` が明示されている
  - 確認: `$table` を定義していないモデルの一覧について、`php artisan tinker` で `(new App\Models\X)->getTable()` が実際のテーブル名と一致するか
- [ ] **L58-16** ⚙️ **マイグレーションの `bigIncrements` と外部キー**（Migrations & `bigIncrements`）
  - OK: アップグレード後に作ったテーブル（`$table->id()` = BIGINT）から、古い `increments`（INT）のテーブルを外部キーで参照する箇所で、型が合っている
- [ ] **L58-17** 🟡 **`deleted_at` が自動でCarbonにキャストされる**
  - OK: `SoftDeletes` を使うモデルで、`deleted_at` を文字列として扱っている箇所がない
- [ ] **L58-18** 🟡 **`TransformsRequest` ミドルウェアに完全修飾のキーが渡る**
  - OK: 独自の `TrimStrings` / `ConvertEmptyStringsToNull` 系のミドルウェアで、`$except` や `transform($key, ...)` が `user.name` のようなドット区切りのキーを前提にしている
- [ ] **L58-19** 🟡 **`email` ルールがRFC6530準拠に**
  - OK: 国際化メールアドレス（`hej@bär.se` など）が有効と判定されても問題ない
- [ ] **L58-20** 🔴 **`loadCount` メソッドの追加**
  - OK: モデルに独自の `loadCount` メソッドがない

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `Application` contractの `environment` のシグネチャと多数のメソッドの追加
- [ ] Cacheの `Repository` / `Store` contractの `put` `putMany` `forever` の戻り値が `bool` に
- [ ] コレクションの `add` `firstWhere` のシグネチャ、Consoleの `Kernel` contractの `terminate`、コンテナの `resolve` / `addContextualBinding` / `flush`
- [ ] `ExceptionHandler` contractの `shouldReport`、例外ハンドラの `renderHttpException` のシグネチャ
- [ ] `PendingMail` の各メソッドが `Illuminate\Contracts\Mail\Mailable` を受け取る、`markdownComponentPaths` → `textComponentPaths`
- [ ] Queueの `Job` contractに `isReleased` `hasFailed` `markAsFailed` `fail`（独自のキュードライバ）
- [ ] `UrlGenerator` contractの `previous`、`$cachedSchema` → `$cachedScheme`
- [ ] `StartSession` ミドルウェアの保存処理が `handle` に移動
- [ ] `Validator` contractの `validated`、`ValidatesAttributes` などの一部のメソッドが `public` に
- [ ] `View` contractの `getData`
- [ ] `originalIsEquivalent` が `public` に
- [ ] ⚙️ Pheanstalkを使う場合のバージョン、SQLiteの最低バージョン（11.xで3.26.0以上が必要。L110-14）
- [ ] ⚙️ Redisのブロッキングpopで、キューごとに `:notify` 付きのリストが作られる（Redisを監視している場合）
