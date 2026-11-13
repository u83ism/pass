# 07. Laravel 10 での変更（9.x → 10.x）

- 公式ガイド: https://laravel.com/docs/10.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/9.x...10.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

## 確認項目

- [ ] **L100-01** 🔴🔍 **`DB::raw()` を文字列として使えない**（Database Expressions）
  - OK: `(string) DB::raw(...)`、`'...' . DB::raw(...)`、`DB::raw(...)->__toString()` がない（文字列が必要なら `$expr->getValue(DB::connection()->getQueryGrammar())`）
  - 生のSQLの断片を組み立てるヘルパーなど、**実行頻度の低い集計・帳票の処理**に残りやすい
- [ ] **L100-02** 🟡🔍 **モデルの `$dates` プロパティの削除**（Model "Dates" Property）
  - OK: `protected $dates = [...]` が残っていない（`$casts` に `'deployed_at' => 'datetime'` として移している）
  - **残っていると、エラーにならずに無視され、その属性はCarbonではなく文字列になる**。`->format()` を呼べば例外になるが、JSONやBladeでそのまま出力している箇所は形式が変わるだけで気づけない
- [ ] **L100-03** 🔴🔍 **`MocksApplicationServices` の削除**（Service Mocking）
  - OK: テストに `expectsEvents` `expectsJobs` `expectsNotifications` `withoutEvents` `withoutJobs` がない（`Event::fake` `Bus::fake` `Notification::fake` を使う）
- [ ] **L100-04** 🔴🔍 **`Bus::dispatchNow` / `dispatch_now` の削除**: `dispatchSync` / `dispatch_sync` を使う
- [ ] **L100-05** 🔴🔍 **`Redirect::home` の削除**: 名前付きのルートにリダイレクトする
- [ ] **L100-06** ⚙️🔍 **Monolog 3**
  - OK: 独自のログのハンドラ・プロセッサ・フォーマッタが Monolog 3 の形（`LogRecord` を受け取る）になっている。BugSnagやSentryなど、ログを送るパッケージがMonolog 3対応の版
  - **ログが出ていない・外部のログサービスに届いていない**状態は、エラーにならないので気づきにくい。本番相当の環境でログの送信を確認する
- [ ] **L100-07** 🟡🔍 **Redisでの `Cache::tags()`**（Redis Cache Tags）
  - OK: Redisでキャッシュタグを使っているなら、`laravel/framework` が12.30.0以上（13なら問題なし）
- [ ] **L100-08** 🔴🔍 **FormRequestの `after()` が予約された**（Form Request After Method）
  - OK: FormRequestに、Laravelの "after validation" の機能以外の目的で `after()` メソッドを定義していない
- [ ] **L100-09** ⚙️ **Composer 2.2以上**: CIやデプロイ先のComposerのバージョン
- [ ] **L100-10** ⚙️ **`minimum-stability`**: `composer.json` で `stable` か、指定がない
- [ ] **L100-11** 🟡 **`dispatch()` ヘルパーの戻り値**
  - OK: キュー用のインターフェースを実装していないクラスを `dispatch()` して、`handle()` の戻り値を受け取っている箇所がない（`dispatch_sync()` を使う）
- [ ] **L100-12** 🟡 **`RateLimiter::attempt` がクロージャの戻り値を返す**
- [ ] **L100-13** 🟡 **クロージャのバリデーションルールの `$fail`**
  - OK: `$fail` を複数回呼んだときにメッセージが追加される。別のキーにメッセージを付けるときは `$fail('key', 'message')` の形
- [ ] **L100-14** 🟡 **`ulid()` のカラム名のデフォルトが `ulid`**（引数なしの `$table->ulid()`）
- [ ] **L100-15** 🧹 **`AuthServiceProvider` の `registerPolicies()`**: 自動で呼ばれるので、残っていても害はない
- [ ] **L100-16** 🧹 **`doctrine/dbal` `^3.0`**: 11.x以降は不要（L110-06）

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `path.public` のバインディング → `$app->usePublicPath(...)`
- [ ] `QueryException` のコンストラクタの第1引数が接続名
- [ ] `$routeMiddleware` → `$middlewareAliases`（任意。両方ある場合はどちらが使われているか）
