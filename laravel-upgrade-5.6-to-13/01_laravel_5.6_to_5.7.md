# 01. Laravel 5.7 での変更（5.6 → 5.7）

- 公式ガイド: https://laravel.com/docs/5.7/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/5.6...5.7
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

## 確認項目

- [ ] **L57-01** 🟡🔍 **Bladeの `or` 演算子の廃止**（The `or` Operator）
  - OK: `{{ $foo or 'default' }}` が1つも残っていない（すべて `{{ $foo ?? 'default' }}`）
  - 残っていると、エラーにならずに `$foo or 'default'` というPHPの論理演算の結果（`1` か空文字）が画面に出る。`$foo` が未定義なら例外
  - 検索: `resources/views` で `{{ ... or ... }}`（英文中の "or" にも当たるので目で確認）
- [ ] **L57-02** 🟡🔍 **`Route::redirect` が302を返す**（The `Route::redirect` Method）
  - OK: 恒久的なリダイレクト（301）が必要な箇所は `Route::permanentRedirect('/a', '/b')` か `Route::redirect('/a', '/b', 301)` になっている
- [ ] **L57-03** 🟡🔍 **`validate()` の戻り値にルールのないキーが含まれない**（Nested Validation Data）
  - OK: `validate()` / `validated()` の戻り値をそのまま保存や処理に渡している箇所で、**ルールを書いていないキー（ネストしたキーを含む）を使っていない**
  - 例: ルールが `person.name` だけなら、戻り値は `['person' => ['name' => ...]]` だけで、`person.job` は含まれない。9.xで、配列のキーについてさらに厳しくなった（L90の「Unvalidated Array Keys」）
- [ ] **L57-04** 🟡🔍 **`whereDate` に日時を渡すと日付だけで比較される**（The `whereDate` Method）
  - OK: `whereDate('col', '>', Carbon)` で時刻まで比較する意図の箇所がない（時刻まで比べるなら `where` を使う）
- [ ] **L57-05** 🔴🔍 **テストの `$this->artisan()` で出力がモックされる**（Testing）
  - OK: コマンドの出力に依存するテストは、`Artisan::call` を使うか `expectsOutput` などで確認している
- [ ] **L57-06** ⚪🔍 **`Login` イベントのコンストラクタに `$guard` が追加**（The `Login` Event）
  - OK: 手動で `new Login(...)` している箇所が `new Login(config('auth.defaults.guard'), $user, $remember)` の形
- [ ] **L57-07** 🟡🔍 **Markdownメールのボタンの色のクラス名の変更**（Template Theme）
  - OK: 公開済みのメールテーマで `blue` `green` `red` を使っていない（`primary` `success` `error`）
- [ ] **L57-08** ⚙️ **`storage/framework/cache/data` ディレクトリ**（Cache）
  - OK: `config/cache.php` の `file` ストアのパスと、実際のディレクトリ・`.gitignore` が合っている（デプロイ先で書き込めること）
- [ ] **L57-09** 🔴 **SQLiteでの `dropForeign` が例外**（SQLite Foreign Keys）
  - OK: テストでSQLiteを使っている場合、マイグレーションの `dropForeign` が `DB::getDriverName()` で分岐している
- [ ] **L57-10** 🟡 **`latest()` / `oldest()` がモデル独自の作成日時のカラムを使う**
  - OK: `const CREATED_AT` を変えているモデルで、並び順が意図どおり
- [ ] **L57-11** 🟡 **スケジュールされたジョブがジョブクラスの `queue` / `connection` を尊重**（Scheduled Job Connection & Queues）
  - OK: `$schedule->job(...)` で投入されるキューが意図どおり
- [ ] **L57-12** 🟡 **PostgreSQLの `Infinity` / `NaN` が `INF` / `NAN` にキャストされる**（PostgreSQLを使っている場合）
- [ ] **L57-13** 🟡 **コレクションの `split` が常に指定した数のグループを返す**

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `Authenticate` ミドルウェアの `authenticate($request, array $guards)`、`ResetsPasswords::sendResetResponse(Request $request, $response)`、`SendsPasswordResetEmails::sendResetLinkResponse(Request $request, $response)` のシグネチャ（上書きしている場合。`laravel/ui` を使っていれば、その版のトレイトに合わせる）
- [ ] `softDeletesTz($column = 'deleted_at', $precision = 0)` の引数の順番
- [ ] `Gate` contractの `raw`、Cookieの `Factory` contract、`ConnectionInterface` の `select` / `selectOne` / `cursor`、`Filesystem` contractの `readStream` / `writeStream`、`Validator` contractの `validate`
- [ ] `Illuminate\Support\Debug\Dumper` / `HtmlDumper` の削除（Symfonyの `VarDumper` を使う）
- [ ] マイグレーションのコマンドを拡張している場合の `$this->migrator->setOutput($this->output)`
- [ ] `queue:work` を拡張している場合の `stop-when-empty` オプション
- [ ] `Router::addRoute` が `public` に、`Application::register` の `$options` 引数の削除
- [ ] Mailableに動的に渡す変数がキャメルケースになる（ドキュメント化されていない機能）
- [ ] ⚙️ 環境変数 `QUEUE_DRIVER` → `QUEUE_CONNECTION`（`config/queue.php` を新しくした場合。**`.env` 側も改名されているか**）
