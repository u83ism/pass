# 12. 公式アップグレードガイドの外にある落とし穴（補足）

Laravelの公式アップグレードガイドは「フレームワーク自体の破壊的変更」を扱うもので、**周辺のパッケージやPHPUnit、雛形のファイルの変更**は書かれていないか、書かれていても扱いが小さいことがあります。5.6から13まで一気に上げると、これらが積み重なって効いてきます。

ここに書いたことは公式ガイドの記載ではなく、各パッケージの公開情報（`composer.json`、UPGRADING、CHANGELOG）と、よく知られた移行の事例にもとづく補足です。

---

## 1. `array_first()` / `array_last()` と `laravel/helpers`（最重要）

5.6から上げた場合に**最も踏みやすく、しかもAIに直させると誤った方向に直されやすい**落とし穴です（エラーを消すために `laravel/helpers` を入れると、PHP 8.5で別の壊れ方をする）。

### 何が起きるか

1. Laravel 5.8で `array_*` `str_*` のグローバルヘルパーが非推奨になり、6.0で削除された
2. 6.0の公式ガイドは、一時しのぎとして `laravel/helpers` パッケージを入れる方法を案内している。**多くのアプリがこれで済ませたまま年月が経つ**
3. `laravel/helpers` の `array_first($array, $callback = null, $default = null)` は「コールバックの条件に合う最初の要素」を返す関数で、`function_exists('array_first')` で既に定義されていないときだけ定義される
4. Laravel 13は `symfony/polyfill-php85` に依存し、PHP 8.5未満ではこのポリフィルが `array_first(array $array)` を定義する。**どちらが先に読み込まれるかで、同じ名前の別の関数になる**
5. **PHP 8.5では `array_first()` と `array_last()` がPHP本体の関数になった**。本体の関数が常に優先されるので、`laravel/helpers` 版は定義されない。コールバックを渡している呼び出しは引数の数が合わずにエラーになり、デフォルト値の第3引数も効かない

### 対処

- [ ] **X-01** 🔴🔍 `array_first(` / `array_last(` の呼び出しを、すべて `Illuminate\Support\Arr::first()` / `Arr::last()` に置き換える
  - 検出: `grep -rnE "\barray_(first|last)\(" app resources routes config database tests`
  - Bladeのテンプレートの中も忘れない（`resources/views`）
- [ ] **X-02 / X-03** 🔴🔍 `laravel/helpers` が提供する他のヘルパー（`str_slug` `array_get` `str_random` など）も `Str::` / `Arr::` に置き換え、**`laravel/helpers` への依存そのものをなくす**
  - 検出のための正規表現は `03_laravel_5.8_to_6.md` の「文字列・配列ヘルパーの削除」を参照
- [ ] **X-04** 🟡🔍 自前で `helpers.php` などにグローバル関数を定義している場合、PHPの新しいバージョンやLaravelの新しいヘルパー（9.xの `str()`、11.xの `once()` など）と名前が衝突しないか確認する。`function_exists` で囲っている場合は、**衝突しても黙って相手の関数が使われる**ので特に注意する

---

## 2. PHPUnitのバージョンの階段

Laravel 5.6の時点ではPHPUnit 7。最終的にLaravel 13ではPHPUnit 12になります。PHPUnitのメジャーバージョンごとの主な変更点です。

一気に上げた場合、**テストコードはPHPUnit 7の書き方のまま、PHPUnit 12で動かしている**ことになります。以下の各版の変更がまとめて効きます。

| Laravel | PHPUnit（公式ガイドの指定） |
|---|---|
| 5.6〜5.8 | 7（5.8で8も可） |
| 7.x | ^8.5 |
| 8.x / 9.x | ^9.0 |
| 10.x | ^10.0（任意） |
| 11.x | 雛形は ^11.0 |
| 12.x | ^11.0 |
| 13.x | ^12.0 |

- [ ] **PHPUnit 8**: `setUp()` / `tearDown()` などのテンプレートメソッドに `: void` が必須。`assertContains` で文字列を探すのは非推奨（`assertStringContainsString` を使う）、`assertInternalType` が非推奨（`assertIsArray` などを使う）
- [ ] **PHPUnit 9**: `assertRegExp` が非推奨（`assertMatchesRegularExpression`）、`assertFileNotExists` などの `NotExists` 系が非推奨（`assertFileDoesNotExist`）、モックの `at()` マッチャーが非推奨、`expectExceptionMessageRegExp` が削除
- [ ] **PHPUnit 10**: `phpunit.xml` の形式が変わった（`vendor/bin/phpunit --migrate-configuration` で変換できる）。**データプロバイダは `public static` が必須**。`withConsecutive()` が削除。`<coverage>` の `processUncoveredFiles` 属性の削除（Laravel 10の公式ガイドにも記載）
- [ ] **PHPUnit 11**: **docblockのアノテーション（`@test` `@dataProvider` `@group` `@depends` など）が非推奨**になった。`#[Test]` `#[DataProvider('...')]` などのアトリビュートに書き換える
- [ ] **PHPUnit 12**: **docblockのアノテーションが削除された**。アトリビュートに書き換えていないテストは、テストとして認識されなくなる（`@test` だけで `test` で始まらない名前のメソッドは**黙って実行されなくなる**）
  - 検出: `grep -rnE "@(test|dataProvider|depends|group|covers)\b" tests`
  - 書き換えにはRectorのPHPUnit用のルールが使える
- [ ] **テストの件数が旧版より減っていないか**を確認する（`vendor/bin/phpunit --list-tests` の件数を旧版と比べる。実行されなくなったテストを見逃さないため）

---

## 3. 開発終了・置き換えられたパッケージ

最終状態で**残っていてはいけない**パッケージの一覧は `00_how_to_audit.md` の「最終状態の確認（composer.json）」にあります。ここでは補足だけ書きます。

- [ ] `fzaninotto/faker` → `fakerphp/faker`: 名前空間は同じ `Faker\` なので、`composer.json` の差し替えだけで済むことが多い
- [ ] `laravel/helpers` → `Str::` / `Arr::`: 上の1を参照
- [ ] `laravel/legacy-factories`: 2026年11月時点でLaravel 13対応の版もあるが、一時しのぎ。テストを書き足すなら新しい形式で書く
- [ ] `spatie/laravel-ignition` を使っているなら、最新版（Laravel 13・PHP 8.4以上が必要）になっている。**本番で `APP_DEBUG=false` になっている**ことも確認する
- [ ] ⚙️ Composer自体のバージョン: **Laravel 10以降はComposer 2.2以上が必須**。Composer 1のままの環境（CI、デプロイ先）が残っていないか

---

## 4. Carbonのバージョンの階段

| Laravel | Carbon |
|---|---|
| 5.6〜5.7 | 1 |
| 5.8 | 1 または 2 |
| 6.x〜10.x | 2 |
| 11.x | 2 または 3 |
| 12.x〜13.x | 3（必須） |

- [ ] Carbon 2への移行（5.8〜6.0）: https://carbon.nesbot.com/docs/#api-carbon-2
- [ ] Carbon 3への移行（11.x〜12.0）: **`diffIn*` が浮動小数点数を返し、時間の向きで負になる**。日数・月数の差を整数として使っている箇所（「あと○日」の表示、期限切れの判定、料金の日割り計算）を全部確認する
  - https://carbon.nesbot.com/guide/getting-started/migration.html

---

## 5. 雛形のファイル（公式ガイドに出てこない差分）

各版の公式ガイドの最後に「`laravel/laravel` の差分を見るように」と書かれています。一気に上げた場合は、**5.6の雛形と13.xの雛形の間の差分**（ https://github.com/laravel/laravel/compare/5.6...13.x ）のうち、次のファイルを自分のアプリの現状と見比べます。逆に、**AIが雛形の設定ファイルを丸ごとコピーしていないか**も同じ観点で確認します。

- [ ] `config/*.php`（新しい設定項目が増えている。特に `logging.php` `queue.php` `mail.php` `cache.php` `session.php` `database.php` `filesystems.php`）
- [ ] `app/Http/Kernel.php`（ミドルウェアの追加・置き換え。11.x以降の新しい雛形にはこのファイル自体がないが、既存アプリはそのまま使える）
- [ ] `app/Http/Middleware/*`（`TrustProxies` `TrustHosts` `PreventRequestsDuringMaintenance` など）
- [ ] `app/Exceptions/Handler.php`（7.xの `Throwable`、8.xの `register()` メソッドでの登録方式）
- [ ] `phpunit.xml`（PHPUnitのバージョンごと）
- [ ] `public/index.php`（8.xのメンテナンスモード）
- [ ] `composer.json`（`autoload`、`scripts`、`minimum-stability`）
- [ ] `.env.example`（環境変数の改名: `QUEUE_DRIVER` → `QUEUE_CONNECTION`、`MAIL_DRIVER` → `MAIL_MAILER`、`FILESYSTEM_DRIVER` → `FILESYSTEM_DISK`、`CACHE_DRIVER` → `CACHE_STORE`（11.x）など）

**注意**: 雛形の設定ファイルに**丸ごと置き換える**と、デフォルト値の変化で挙動が変わることがあります（12.xの `local` ディスクのルート、13.xのセッションの `serialization`・キャッシュの `serializable_classes`・接頭辞など）。必ず差分を見て、必要な項目だけを取り込んでください。

---

## 6. フロントエンドのビルド（任意）

- Laravel 9.19以降の新規アプリは、Laravel Mix（webpack）ではなくVite を使う雛形になった
- **既存アプリはLaravel Mixのままでも動く**。この取り組みの範囲外にしてよい。移行する場合は別の作業として扱い、PHP・Laravelのアップグレードと混ぜない
- ただし、Node.jsのバージョンが古いままだとビルド環境の保守が難しくなるので、別途計画しておく

---

「例外が出ずに結果だけ変わる」変更の一覧は `00_how_to_audit.md` に移しました。
