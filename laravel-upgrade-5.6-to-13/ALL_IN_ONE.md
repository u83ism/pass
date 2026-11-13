# Laravel 5.6 / PHP 7.4 → Laravel 13 / PHP 8.5 アップグレード後の抜け漏れ監査チェックリスト（全ファイル結合版）

> このファイルは同じディレクトリの README.md と 00〜12 のファイルを番号順に結合したものです。内容は個別のファイルと同じです。検索スクリプトは audit_grep.sh を参照してください。


<!-- ===== README.md ===== -->

# Laravel 5.6 / PHP 7.4 → Laravel 13 / PHP 8.5 アップグレード後の抜け漏れ監査チェックリスト

Laravel 5.6 / PHP 7.4 から **Laravel 13 / PHP 8.5 まで一気に上げた後**に、抜け漏れを探すためのチェックリストと検索スクリプトです。Laravel公式の歴代アップグレードガイド（5.7〜13.x、計10本）とPHP公式の移行ノート（php-src の `UPGRADING` 8.0〜8.5、計6本）を1本ずつ読み、**バージョンごとに「最終的にどうなっていればOKか」と「どう探すか」**の形にまとめ直しました。

- 作成日: 2026-11-13（この時点の公式ドキュメントの内容にもとづく）
- 対象: Laravel 5.6 / PHP 7.4 で動いていた一般的なWebアプリケーション
- 特定の組織やアプリに固有の情報は含みません

## 想定している状況

- アップグレードはすでに済んでいて、壊れた所は（人やAIが）動かしながら直した
- 自動テストのカバー率は低く、テストの質（ステータスコードだけを確認するものから中身まで確認するものまで）もまちまち
- そのため、**実行されなかった経路の壊れ**と、**エラーにならずに挙動だけ変わったもの**が残っている可能性が高い

## ファイル

| ファイル | 内容 |
|---|---|
| `00_how_to_audit.md` | **最初に読む**。監査の手順（機械的な全量検査、旧版との比較、AIによる修正の後始末の確認、AIアシスタントへの頼み方）、最終状態の確認、**静かに変わる変更の一覧** |
| `01_laravel_5.6_to_5.7.md` 〜 `10_laravel_12_to_13.md` | Laravelのバージョンごとの確認項目。1ファイルが1バージョン分 |
| `11_php_7.4_to_8.5_checklist.md` | PHP 8.0〜8.5の確認項目 |
| `12_pitfalls_outside_official_guides.md` | 公式ガイドに載っていない落とし穴（`laravel/helpers` とPHP 8.5の衝突、PHPUnit 7→12、Carbon、雛形のファイル） |
| `audit_grep.sh` | 確認項目に対応するコードを、プロジェクト全体から検索するスクリプト（読み取りのみ） |
| `ALL_IN_ONE.md` | README と 00〜12 を1つに結合したもの（内容は同じ） |

## 確認項目の見方

```
- [ ] **L58-01** 🟡🔍 **キャッシュのTTLが「分」から「秒」に**（TTL in seconds）
  - OK: …最終的にこうなっていればよい、という状態…
```

- **ID**: `L58-01` は「Laravel 5.8で入った変更」、`P84-01` は「PHP 8.4で入った変更」、`X-01` はバージョンをまたぐもの。`audit_grep.sh` の結果と同じIDを使う
- **記号**

| 記号 | 意味 |
|---|---|
| 🔴 | 実行されればエラー（例外・致命的エラー・403/419/500）になる。通っていない経路は検索で探す |
| 🟡 | **エラーにならず、結果だけ変わる**。テストでは見つかりにくいので**最優先** |
| ⚙️ | 設定・環境・データ・運用（`.env`、php.ini、DB、キャッシュ、ワーカーの起動設定など） |
| 🧹 | 動くが整理すべき残骸 |
| ⚪ | interfaceの自前実装やコアクラスの継承など、まれなケース |
| 🔍 | `audit_grep.sh` に同じIDの検索がある |

- 括弧内の英語は、公式ガイドの見出しそのまま（原文を検索するときに使う）

## 検索スクリプトの使い方

```bash
bash audit_grep.sh /path/to/laravel-project > audit_result.md
```

- GNU grep と bash があれば動く（Linux、WSL、Git for Windows）。ファイルは一切変更しない
- **ヒットした＝問題がある、ではない**。チェックリストの「OK」の状態と照らして判定する
- **ヒットしない＝問題がない、でもない**。変数経由の呼び出しなどは拾えない
- 1つのチェックで表示する行数は既定で40行。`MAX_LINES=200 bash audit_grep.sh ...` のように変えられる
- 動作確認: 該当するコードを仕込んだテスト用のプロジェクトで全チェックの検出を確認し、Laravel 13の素の雛形（誤検出は設定ファイルの確認項目だけ）と、Laravel 5.6の素の雛形（`config/session.php` の `str_slug()`、例外ハンドラの `Exception` 型、`Fideloper\Proxy` などを検出）でも確認した

## 出典（すべて一次情報）

### Laravel公式アップグレードガイド

| 版 | URL |
|---|---|
| 5.7 | https://laravel.com/docs/5.7/upgrade |
| 5.8 | https://laravel.com/docs/5.8/upgrade |
| 6.x | https://laravel.com/docs/6.x/upgrade |
| 7.x | https://laravel.com/docs/7.x/upgrade |
| 8.x | https://laravel.com/docs/8.x/upgrade |
| 9.x | https://laravel.com/docs/9.x/upgrade |
| 10.x | https://laravel.com/docs/10.x/upgrade |
| 11.x | https://laravel.com/docs/11.x/upgrade |
| 12.x | https://laravel.com/docs/12.x/upgrade |
| 13.x | https://laravel.com/docs/13.x/upgrade |

原文のMarkdownは `https://github.com/laravel/docs/blob/<ブランチ名>/upgrade.md`（ブランチ名は `5.7` `5.8` `6.x` 〜 `13.x`）。

### PHP公式移行ノート

| 版 | URL |
|---|---|
| 8.0 | https://github.com/php/php-src/blob/PHP-8.0/UPGRADING |
| 8.1 | https://github.com/php/php-src/blob/PHP-8.1/UPGRADING |
| 8.2 | https://github.com/php/php-src/blob/PHP-8.2/UPGRADING |
| 8.3 | https://github.com/php/php-src/blob/PHP-8.3/UPGRADING |
| 8.4 | https://github.com/php/php-src/blob/PHP-8.4/UPGRADING |
| 8.5 | https://github.com/php/php-src/blob/PHP-8.5/UPGRADING |

php.net のマニュアルにも「Migrating from PHP 7.4.x to PHP 8.0.x」などの章で同じ内容があります。

### 補足に使った公開情報

- `laravel/laravel`（雛形）と `laravel/framework` の各ブランチのソースコード・`composer.json`（例: Laravel 13が `handle()` の戻り値を `(int)` でキャストすること、`cache.serializable_classes` が未設定なら制限なしになること）
- `laravel/helpers` のソースコード（`array_first` を `function_exists` で囲って定義していること）

## 出典とライセンスについて

- このドキュメントは、Laravel公式ドキュメント（MIT License、Copyright (c) Taylor Otwell。 https://github.com/laravel/docs ）とPHPの移行ノート（php-src、PHP License）を**要約・翻訳・再構成**したものです。原文の文章をそのまま転載しているのは、コード例と英語の見出しだけです
- Laravel公式・PHP公式のドキュメントではありません。内容に誤りがあっても、それは原文ではなくこのドキュメントの誤りです

## 注意

- これは公式ガイドの**要約と再構成**です。判断に迷う項目は、英語の見出しで原文を確認してください
- サードパーティのパッケージの対応状況は範囲外です


<!-- ===== 00_how_to_audit.md ===== -->

# 00. 監査の進め方（Laravel 13 / PHP 8.5 に上げた後で抜け漏れを探す）

このチェックリストは、**Laravel 5.6 / PHP 7.4 からLaravel 13 / PHP 8.5 まで一気に上げ、壊れた所を直した後**に、抜け漏れを探すためのものです。1段ずつ上げる手順書ではありません。

## なぜ抜け漏れが起きるか

「動かして壊れた所を直す」というやり方（人でもAIでも）では、次の2種類がほぼ確実に残ります。

1. **実行されなかった経路**: 自動テストやスモークテストで通らなかった画面・API・バッチ・ジョブ・例外処理の中の壊れ。ルートのカバー率が20%なら、残り80%は未確認と考える
2. **エラーにならず挙動だけ変わったもの**: キャッシュの有効期限、日付のJSONの形式、ファイル保存の失敗、CSRFの判定など。ステータスコードしか見ないテストでは、実行されていても見つからない

このため、以下の3つを**テストとは別に**行います。

- **機械的な全量検査**: 構文チェック・静的解析・検索スクリプトで、実行しなくてもコード全体を調べる
- **🟡（静かに変わる）項目の重点確認**: 下の「静かに変わる変更の一覧」を1つずつ潰す
- **旧版との突き合わせ**: アップグレード前のコード（gitのタグやコミット）が手元にあるので、出力を比べる

## 記号の意味

| 記号 | 意味 | 見つけ方 |
|---|---|---|
| 🔴 | 実行されればエラー（例外・致命的エラー・403/419/500）になる | その経路を通せば分かる。通っていない経路は検索で探す |
| 🟡 | **エラーにならず、結果だけ変わる** | テストでは見つかりにくい。**最優先で確認する** |
| ⚙️ | 設定・環境・データ・運用（`.env`、php.ini、DB、キャッシュ、ワーカーの起動設定など） | コードの外なので、AIに直させても見落としやすい |
| 🧹 | 動くが整理すべき残骸（一時しのぎのパッケージなど） | 後回しでよい |
| ⚪ | interfaceの自前実装やコアクラスの継承など、まれなケース | 該当がなければ不要 |
| 🔍 | `audit_grep.sh` に同じIDの検索がある | スクリプトの結果を見る |

各項目の英語の見出しは、公式ガイドの見出しそのままです（原文を検索するときに使う）。

## 手順

### 1. 機械的な全量検査（テスト不要。最初にやる）

PHP 8.5 の環境で、プロジェクトのルートで実行します。

- [ ] **構文チェック**: 全PHPファイルを `php -l` する。構文エラーに加えて、**コンパイル時に出る非推奨**（暗黙のnull許容型、バッククォート演算子、非正規のキャスト、`case` の後のセミコロン、`"${var}"` など）も表示される

    ```bash
    find app bootstrap config database routes tests -name '*.php' -print0 | xargs -0 -n1 -P4 php -d error_reporting=E_ALL -d display_errors=1 -l 2>&1 | grep -v '^No syntax errors'
    ```

- [ ] **Bladeの構文チェック**: テンプレートを全部コンパイルしてから、コンパイル結果を `php -l` する

    ```bash
    php artisan view:clear && php artisan view:cache
    ```

    ```bash
    find storage/framework/views -name '*.php' -print0 | xargs -0 -n1 php -d error_reporting=E_ALL -l 2>&1 | grep -v '^No syntax errors'
    ```

- [ ] **Artisanでの全量の読み込み**: 次がすべてエラーなしで通ること（コントローラ・ミドルウェア・設定・イベントのクラスがすべて読み込める）

    ```bash
    php artisan config:cache && php artisan route:cache && php artisan event:cache && php artisan view:cache && php artisan route:list > /dev/null
    ```

  - 確認が終わったら `php artisan optimize:clear` でキャッシュを消す
- [ ] **Composer**: `composer validate` と `composer check-platform-reqs` が通る。`composer outdated --direct` で取り残しを確認する
- [ ] **静的解析（最も効果が大きい）**: PHPStan + Larastan を入れて、レベル0から始める。**存在しないクラス・メソッド・関数の呼び出し、引数の数の誤り**を、テストのカバー率に関係なく全コードから拾える。レベル0〜2の結果を潰すだけでも、未実行の経路の🔴の多くが見つかる

    ```bash
    composer require --dev larastan/larastan
    ```

    ```bash
    vendor/bin/phpstan analyse app --level=0 --memory-limit=2G
    ```

- [ ] **Rectorの「検出のみ」の実行（任意）**: `vendor/bin/rector process --dry-run` で、PHP 8.x向けのルールに当たる箇所の一覧が得られる（書き換えはしない）
- [ ] **検索スクリプト**: このディレクトリの `audit_grep.sh` を実行する。結果のIDは、各チェックリストのIDと対応している

    ```bash
    bash audit_grep.sh /path/to/project > audit_result.md
    ```

  - **ヒットした＝問題がある、ではない**。各チェックリストの「OK」の状態と照らして判定する
  - **ヒットしない＝問題がない、でもない**。変数経由の呼び出しなどは拾えない

### 2. 静かに変わる変更（🟡）を重点確認する

下の「静かに変わる変更の一覧」の各項目について、該当するコードがあるか、あれば意図どおりかを確認します。**テストを書き足すなら、まずここ**です（ステータスコードではなく、中身を確認するテスト）。

### 3. 旧版との突き合わせ（テストが薄い場合に特に有効）

アップグレード前のコード（以下 `<旧>` は、そのgitのタグかコミット）を別の場所で動かせるなら、同じ入力に対する出力を比べるのが、テストを書くより早く広く確認できます。

- [ ] **ルートの一覧の比較**: 両方で `php artisan route:list` を出して比べる（名前・URI・ミドルウェアの違い。名前の重複は12.x以降で「最初に登録したもの」が使われる）
  - 5.6の `route:list` には `--json` がないので、表形式のまま差分を見る
- [ ] **APIのレスポンスの比較**: 同じDBのコピーに対して、旧版と新版の主なGETのAPI・画面を叩き、レスポンスの本文を比べる（日付の形式、数値か文字列か、キーの欠落、`null` の扱い）
- [ ] **DBのスキーマの比較**: 空のDBに旧版と新版でそれぞれ `php artisan migrate` を流し、スキーマを比べる（`mysqldump --no-data` など）。11.xの `change()` と浮動小数点数の変更の影響が出る。**本番のスキーマとも比べる**
- [ ] **バッチ・コマンドの終了コードの比較**: cronで動くコマンドの終了コードが変わっていないか（7.xの「`handle()` の戻り値」。13.xでは `return true;` が終了コード1になる）
- [ ] **送信されるメールの比較**: メールをログ（`MAIL_MAILER=log`）に出して、件名・本文・宛先を比べる

### 4. AIによる修正の後始末を確認する

AIに「エラーを直して」と頼むと、**エラーを消す方向の修正**（原因を直さずに握りつぶす）が入りやすいです。アップグレード前からの差分を、次の観点で確認します。

```bash
git diff <旧>..HEAD -U0 -- app bootstrap config routes resources database tests composer.json | grep -E '^(\+\+\+ |\+)' | grep -E '^\+\+\+ |@\$|@[a-z_]+\(|catch \([^)]*\) \{\s*\}|AllowDynamicProperties|ReturnTypeWillChange|error_reporting|ini_set|\?\? ?(null\b|0\b|'"''"'|""|\[\])|\(string\) ?\$|markTestSkipped|markTestIncomplete|withoutMiddleware|withoutExceptionHandling|'"'"'throw'"'"' => false|laravel/helpers' | grep -B1 -vE '^\+\+\+ ' | grep -v '^--$'
```

- [ ] **`@` による警告の抑止**、**空の `catch`**: 本当の失敗を隠していないか
- [ ] **`#[\AllowDynamicProperties]` / `#[\ReturnTypeWillChange]`**: 警告を消すだけの暫定の対応。必要な箇所だけに限られているか
- [ ] **`?? ''` / `?? null` / `(string)` の大量の追加**: PHP 8.1の「null を渡すと非推奨」への対応として正しい場合もあるが、**null になるべきでない値が null になっている原因**を隠していないか
- [ ] **`laravel/helpers` の追加**: 削除されたヘルパーのエラーを消すために入れられていないか（**PHP 8.5の `array_first()` と衝突する**。`12_pitfalls_outside_official_guides.md`）
- [ ] **テストの削除・スキップ**: `git diff --stat <旧>..HEAD -- tests` で、削除されたテストや、`markTestSkipped` の追加がないか。PHPUnit 12でdocblockのアノテーション（`@test` など）が無視され、**黙って実行されなくなったテストがないか**（テストの件数を旧版と比べる）
- [ ] **設定の値の変更**: `git diff <旧>..HEAD -- config .env.example` を全部読む。AIが新しい雛形の設定ファイルを丸ごとコピーしていると、デフォルト値の変化（セッションのシリアライズ、キャッシュの接頭辞、`local` ディスクのルートなど）がそのまま入る

### 5. AIアシスタントに監査を任せる場合のコツ

- **1回の依頼で1つのチェックリスト（1バージョン分）**だけを渡す。全部を一度に渡すと、後半の項目の確認が雑になりやすい
- **「調査」と「修正」を別の依頼に分ける**。まず「各項目について、該当箇所・判定（OK/NG/該当なし）・根拠（ファイル名と行番号）」を表で出させ、人が見てから修正を頼む
- `audit_grep.sh` の結果のうち、そのバージョンのIDの部分を一緒に渡すと、AIが自分で検索するより漏れが少ない
- **AIが出した修正案は、そのまま適用する前に意味が変わらないかを確認する**。実際によくある例:
  - 引数なしの `get_class()` → `static::class`（正しくは `self::class`。P83-01）
  - CSV関数に `escape: ''` を追加（警告は消えるが出力が変わりうる。挙動を変えないなら `escape: '\\'`。P84-03）
  - `diffInDays(absolute: true)` だけで整数になると思っている（浮動小数点数のまま。L110-03）
  - 「`schema` は `search_path` に改名されたので今は効いていない」（13でもフォールバックで読まれる。L90-05）
- `audit_grep.sh` の結果には誤検知が含まれる。PHPの構文に関するチェックの一部（P82-01、P85-08）はBladeを対象外にしているので、**Blade内のPHPはコンパイル済みビューへの `php -l` の結果で判断する**
- 依頼の例:

    ```
    添付の 02_laravel_5.7_to_5.8.md の各項目について、このリポジトリのコードが
    「OK」の状態になっているかを調べてください。修正はまだしないでください。
    audit_result.md の L58-* の検索結果も参照してください。
    結果は「ID / 判定（OK・NG・該当なし・要確認）/ 根拠（ファイル:行）/ NGの場合の修正方針」の表で出してください。
    ```

## 最終状態の確認（composer.json）

- [ ] `"php"` の制約が、実際に動かすPHPと合っている（Laravel 13は `^8.3`。8.5でしか動かさないなら `^8.5` でもよい）
- [ ] `laravel/framework` `^13.0`、`laravel/tinker` `^3.0`、`phpunit/phpunit` `^12.0`、`pestphp/pest` `^4.0`（使っていれば）
- [ ] 次のパッケージが**残っていない**（残っていればID付きの項目を確認する）

| パッケージ | 理由 | 関連ID |
|---|---|---|
| `laravel/helpers` | PHP 8.5の `array_first()` / `array_last()` と衝突 | X-01, X-02 |
| `fzaninotto/faker` | 開発終了。PHP 8非対応（`fakerphp/faker` へ） | L80-02 |
| `fideloper/proxy` | Laravel 9以降は非対応 | L90-11 |
| `fruitcake/laravel-cors` / `barryvdh/laravel-cors` | CORSはフレームワークに内蔵 | L90-15 |
| `facade/ignition` | `spatie/laravel-ignition` に置き換え | L90-17 |
| `swiftmailer/swiftmailer`、`wildbit/swiftmailer-postmark` | Symfony Mailerに移行 | L90-04 |
| `doctrine/dbal` | Laravel 11以降は不要 | L110-06 |
| `spatie/once` | Laravelの `once()` と衝突 | L110-10 |
| `laravel/nexmo-notification-channel` | Vonageに置き換え | L58-04 |
| `laravel/legacy-factories` | 一時しのぎ（13対応版はあるが、書き直すべき） | L80-03 |

- [ ] 公式パッケージ（Sanctum、Passport、Horizon、Telescope、Cashierなど）と、サードパーティのパッケージが、Laravel 13とPHP 8.5に対応した版になっている

## 静かに変わる変更の一覧（🟡・⚙️の主なもの）

テストが通っても安心できないものです。**ここが監査の本丸**です。

| ID | 版 | 変更 | 確認すること |
|---|---|---|---|
| L57-01 | 5.7 | Bladeの `{{ $x or 'default' }}` が使えない | 画面に「1」や空文字が出ていないか |
| L57-02 | 5.7 | `Route::redirect` が302に | 恒久的なリダイレクトが必要な箇所 |
| L57-03 | 5.7 / 9.0 | `validate()` の戻り値からルールのないキーが消える | 保存される値が欠けていないか |
| L58-01 | 5.8 | **キャッシュのTTLが分から秒に** | キャッシュの有効期限が1/60になっていないか |
| L58-14 | 5.8 | **`.env` の `#` 以降がコメントに** | `#` を含むパスワード・APIキー |
| L58-03 | 5.8 | パスワードの最小文字数が8に | 登録・変更の画面とバリデーション |
| L60-08 | 6.0 | キューの試行回数のデフォルトが1回に | ワーカーの `--tries`、失敗時の再実行 |
| L60-06 | 6.0 | `BelongsTo::update` でイベントが発火しない | オブザーバーの処理 |
| L60-09 | 6.0 | `route()` の余分なパラメータがクエリ文字列に | 生成されるURL |
| L70-13 | 7.0 | **日付のシリアライズがISO-8601（UTC）に** | APIのレスポンス、JSON、フロントエンドの日付の解析 |
| L70-03 | 7.0 / 13.0 | Artisanコマンドの戻り値が整数に（`true` は終了コード1） | cronの成否の判定、監視 |
| L80-04 | 8.0 | ページネーションがTailwindに | 一覧画面のページ送りの見た目 |
| L80-06 | 8.0 | `retryAfter` / `timeoutAt` が無視される | ジョブのリトライの間隔・期限 |
| L80-09 | 8.0 | `increment` / `decrement` でイベントが発火 | オブザーバーの処理 |
| L90-01 | 9.0 | **ファイルの書き込みの失敗が例外ではなく `false` に** | ファイルの保存・アップロード |
| L90-08 | 9.0 | HTTPクライアントのタイムアウトが30秒に | 時間のかかる外部APIとの通信 |
| L100-02 | 10.0 | **モデルの `$dates` が無視される** | 日付の属性がCarbonになっているか |
| L110-01 | 11.0 | **マイグレーションの `change()` で属性が消える** | 新しい環境で作ったDBのスキーマ |
| L110-03 | 11.0 / 12.0 | **Carbon 3の `diffIn*` が浮動小数点数・負の値に** | 日数・期間の計算と表示 |
| L110-04 | 11.0 | レート制限の値が分から秒に | 制限の強さ |
| L110-13 | 11.0 | キャッシュのキーの接頭辞から `:` が消える | 既存のキャッシュ、外部からキーを参照する仕組み |
| L120-01 | 12.0 | `HasUuids` がUUIDv7に | IDの形式・並び順 |
| L120-02 | 12.0 | `image` ルールがSVGを拒否 | 画像のアップロード |
| L120-03 | 12.0 | `local` ディスクのデフォルトのルート | ファイルの保存先 |
| L130-01 | 13.0 | CSRFでの `Sec-Fetch-Site` の検証 | 外部からのPOST、別ドメインのフォーム |
| L130-03 / 04 | 13.0 | キャッシュ・セッションのシリアライズの強化 | キャッシュが読めるか、ログインが維持されるか |
| L130-11 | 13.0 | `Js::from` がUnicodeをエスケープしない | 日本語を含むJSの出力 |
| P80-08 | PHP 8.0 | `0 == "abc"` が `false` に | 非厳密な比較、`in_array` |
| P81-07 | PHP 8.1 | PDOで整数・浮動小数点数がネイティブな型で返る | `===` での比較、JSONの `"1"` と `1` |
| P82-04 | PHP 8.2 | `strtolower()` などがロケールに依存しない | 文字列の変換 |
| X-01 | PHP 8.5 | **`array_first()` / `array_last()` が本体の関数に** | `laravel/helpers` の利用箇所 |


<!-- ===== 01_laravel_5.6_to_5.7.md ===== -->

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


<!-- ===== 02_laravel_5.7_to_5.8.md ===== -->

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


<!-- ===== 03_laravel_5.8_to_6.md ===== -->

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


<!-- ===== 04_laravel_6_to_7.md ===== -->

# 04. Laravel 7 での変更（6.x → 7.x）

- 公式ガイド: https://laravel.com/docs/7.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/6.x...7.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

## 確認項目

- [ ] **L70-01** 🔴🔍 **例外ハンドラの引数が `Throwable` に**（Symfony 5 Related Upgrades）
  - OK: `app/Exceptions/Handler.php` の `report` `render` `shouldReport` `renderForConsole` が `Throwable $e` を受け取る（または11.x以降の `bootstrap/app.php` の `withExceptions` に移行済み）
- [ ] **L70-02** 🟡🔍 **ジョブ・リスナー・メール・通知の `failed()` の引数が `Throwable` に**
  - OK: `failed(Exception $e)` が残っていない
  - 残っていると、ジョブが `Error`（`TypeError` など）で失敗したときに `failed()` の呼び出し自体が `TypeError` になり、**失敗時の後始末（通知、状態の巻き戻し）が動かない**。普段は気づけない
- [ ] **L70-03** 🟡🔍 **Artisanコマンドの戻り値は整数**（Symfony 5 Related Upgrades）
  - OK: `handle()` が `true` / `false` / 文字列を返していない（成功は `return 0;` か `return self::SUCCESS;`、または何も返さない）
  - **Laravel 13は戻り値を `(int)` でキャストするので、`return true;` は終了コード1（失敗）になる**。エラーは出ないが、cronの監視、`&&` でつないだシェルのスクリプト、スケジューラの `onFailure` / `onSuccess` の判定が逆になる
- [ ] **L70-13** 🟡🔍 **日付のシリアライズの形式がISO-8601（UTC）に**（Date Serialization）
  - OK: モデルの `toArray` / `toJson`（APIのレスポンス、Bladeで `@json` するデータ、キューに積むデータ、外部システムへの送信）の日付の形式が、**受け取る側の期待と一致している**
  - 7.x以降は `2019-12-02T20:01:00.283041Z`（UTC、マイクロ秒付き）。6.xまでは `2019-12-02 20:01:00`（アプリのタイムゾーン）
  - 従来の形式を保つなら、モデル（共通の基底モデル）で `serializeDate` を上書きする

    ```php
    protected function serializeDate(\DateTimeInterface $date)
    {
        return $date->format('Y-m-d H:i:s');
    }
    ```

  - `audit_grep.sh` は `serializeDate` がどこにもなければ警告を出す
  - **日本時間で表示している画面で、JS側が文字列をそのまま表示していると、9時間ずれる**
- [ ] **L70-04** 🔴🔍 **`Blade::component` が `Blade::aliasComponent` に**
  - OK: `Blade::component('components.alert', 'alert')` の形（ビューに別名を付ける旧用途）が残っていない。Laravel 13の `Blade::component` はクラスのコンポーネントの登録で、引数の意味が違う
- [ ] **L70-05** 🔴🔍 **ファクトリの "types" の廃止**（Factory Types）
  - OK: `factory(User::class, 'admin')` の形がない（ステートを使う。8.xでクラスベースのファクトリに移行。L80-02）
- [ ] **L70-06** 🔴🔍 **`addHidden` / `addVisible` の削除**: `makeHidden` / `makeVisible` を使う
- [ ] **L70-07** 🟡🔍 **`getOriginal()` がキャスト・ミューテータを反映した値を返す**
  - OK: 変更前の生の値が必要な箇所は `getRawOriginal()` を使っている
- [ ] **L70-08** 🔴🔍 **`Illuminate\Http\Resources\Json\Resource` の削除**: `JsonResource` を継承する
- [ ] **L70-09** 🔴🔍 **`TestResponse` / `Assert` の名前空間の変更**: `Illuminate\Testing\TestResponse` / `Illuminate\Testing\Assert`
- [ ] **L70-10** 🟡🔍 **`different` ルールがパラメータの欠如でも失敗する**
  - OK: `different:field` で、比較先のフィールドが送られない場合がある画面で、意図せずバリデーションエラーにならない
- [ ] **L70-11** 🔴🔍 **モデルの `booting` / `booted` メソッドとの衝突**
  - OK: モデルに、これらの名前の（静的でない）独自のメソッドがない
- [ ] **L70-12** 🔴🔍 **`swift.mailer` / `swift.transport` のバインディングがない**（Swift Mailer Bindings。9.xでSymfony Mailerに移行。L90-04）
- [ ] **L70-14** 🔴 **認証のスキャフォールドが `laravel/ui` に**（Scaffolding）
  - OK: `Auth::routes()` やログイン・登録・パスワードリセットの画面のトレイトを使っているなら、`laravel/ui` が **`require`**（`require-dev` ではない）に入っていて、Laravel 13に対応した版
- [ ] **L70-15** 🔴 **ルート名の重複が不可**（Unique Route Names）
  - OK: `php artisan route:list` で同じ名前のルートがない。12.x以降は、重複していると**最初に登録したもの**が使われる（L120-07）
  - 確認: `php artisan route:list --json | php -r '$r=json_decode(stream_get_contents(STDIN),true);$n=array_count_values(array_filter(array_column($r,"name")));print_r(array_filter($n,fn($c)=>$c>1));'`
- [ ] **L70-16** ⚙️ **CORS**（CORS Support）
  - OK: CORSは最終的にフレームワーク内蔵の `Illuminate\Http\Middleware\HandleCors` と `config/cors.php` で設定されている。旧パッケージ（`barryvdh/laravel-cors`、`fruitcake/laravel-cors`）と二重になっていない（L90-15、L90-16）
- [ ] **L70-17** ⚙️ **`config/session.php` の `secure`**
  - OK: `'secure' => env('SESSION_SECURE_COOKIE')` で、本番（HTTPS）では `true` になっている
- [ ] **L70-18** ⚙️ **メールの設定ファイルの形式と `MAIL_DRIVER` → `MAIL_MAILER`**（Mail Configuration File Changes）
  - OK: `config/mail.php` が `mailers` 配列の形式で、`.env` の変数名も合っている。古い `mail.driver` の形式も13で互換として動くが、**設定ファイルだけ新しくして `.env` が `MAIL_DRIVER` のままだと、デフォルトの送信方式（`log` など）になって、エラーにならずにメールが送られない**
- [ ] **L70-19** 🟡 **Markdownメールのテンプレートの刷新**（Markdown Mail Template Updates）
  - OK: 公開済みのメールテンプレート（`resources/views/vendor/mail`）が新しい版で再公開されているか、インデントのないHTMLになっている（インデントがあるとコードブロックとして表示される）。`promotion` コンポーネントを使っていない
- [ ] **L70-20** 🟡 **テストの `assertSee` 系が値を自動でエスケープ**
  - OK: `assertSee` に、手動でエスケープした値やHTMLを渡していない（HTMLを確認するなら第2引数に `false`）。**テストが通っていても、何も確認していない状態になっている場合がある**
- [ ] **L70-21** 🟡 **`array` セッションドライバが同じリクエストの間は値を保持する**（テストでの挙動）
- [ ] **L70-22** 🔴 **PSR-7のブリッジ**（PSR-7 Compatibility）
  - OK: PSR-7を使っているなら `nyholm/psr7` と `symfony/psr-http-message-bridge` が入っている（Zend Diactorosは使わない）

## ⚪ interfaceの自前実装・コアの継承をしている場合だけ

- [ ] `TokenRepositoryInterface` の `recentlyCreatedToken`
- [ ] `resolveRouteBinding($value, $field = null)`（`UrlRoutable` の実装、モデルでの上書き、`DelegatesToResources`）
- [ ] ルーターの `getRoutes` が `RouteCollectionInterface` を返す
- [ ] Bladeのタグ形式のコンポーネント（`<x-...>`）が、独自のタグやVueのコンポーネントと衝突しない（`spatie/laravel-blade-x` などを使っていた場合）


<!-- ===== 05_laravel_7_to_8.md ===== -->

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


<!-- ===== 06_laravel_8_to_9.md ===== -->

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
  - Laravel 13でも、`search_path` がなければ `schema` が読まれる（`$config['search_path'] ?? $config['schema']`）ので、**`schema` のままでも現在は動く**。急ぎではないが、将来の削除に備えて改名しておく
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


<!-- ===== 07_laravel_9_to_10.md ===== -->

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


<!-- ===== 08_laravel_10_to_11.md ===== -->

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
  - **`diffInDays($d, absolute: true)` は符号をなくすだけで、浮動小数点数のまま**。整数が必要なら `(int)` も付ける。**切り捨てでよいか（Carbon 2は切り捨てだった）**も確認する
  - **12.x以降はCarbon 3が必須**なので、全件確認が必要
  - Carbonの移行ガイド: https://carbon.nesbot.com/guide/getting-started/migration.html （ほかにも、`createFromTimestamp` のタイムゾーンの扱いなどが変わっている）
- [ ] **L110-04** 🟡🔍 **レート制限が秒単位に**（Per-Second Rate Limiting）
  - OK: `new Limit(...)` `new GlobalLimit(...)` `new ThrottlesExceptions(...)` に渡す時間が、**分ではなく秒の値**になっている。`decayMinutes` → `decaySeconds`
  - `Limit::perMinute()` などの静的メソッドを使っていれば影響なし
- [ ] **L110-13** ⚙️🔍 **キャッシュのキーの接頭辞の後に `:` が付かない**（Cache Key Prefixes）
  - 対象は **DynamoDB・Memcached・Redisのキャッシュストアだけ**（`file` や `database` のストアは関係ない）。`config/cache.php` の `default` と、実際に使っているストアを確認する
  - OK: キャッシュの接頭辞が変わってもよい。影響は**リリース直後に既存のキャッシュが一度すべて外れる**ことで、普通は作り直されるだけで済む（リリース直後の負荷に注意）。外部のシステムやスクリプトがキャッシュのキーを直接参照している場合、またはキャッシュを「消えては困るデータ」の保存に使っている場合は、接頭辞の末尾に `:` を自分で付ける

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


<!-- ===== 09_laravel_11_to_12.md ===== -->

# 09. Laravel 12 での変更（11.x → 12.x）

- 公式ガイド: https://laravel.com/docs/12.x/upgrade
- 雛形の差分: https://github.com/laravel/laravel/compare/11.x...12.x
- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / 🧹残骸 / ⚪まれ / 🔍`audit_grep.sh` で検索できる

## 確認項目

- [ ] **L120-08** 🟡 **Carbon 3が必須**（Carbon 3）: L110-03 の `diffIn*` を必ず確認する
- [ ] **L120-01** 🟡🔍 **`HasUuids` がUUIDv7を返す**（Models and UUIDv7）
  - OK: `HasUuids` を使うモデルで、IDの形式（v4からv7）や並び順が変わっても問題ない。従来どおりにするなら `use HasVersion4Uuids as HasUuids;`。`HasVersion7Uuids` は削除された
  - v7は先頭が時刻なので、**IDから作成日時が推測できる**。IDを外部に公開している場合は要件を確認する
- [ ] **L120-02** 🟡🔍 **`image` ルールがSVGを拒否**（Image Validation Now Excludes SVGs）
  - OK: SVGのアップロードを受け付けていた画面で、`image:allow_svg` か `File::image(allowSvg: true)` になっている（**SVGを受け付けないことにしたなら、そのままでよい**。SVGはXSSの原因になりうる）
- [ ] **L120-03** ⚙️🔍 **`local` ディスクのデフォルトのルートが `storage/app/private`**（Local Filesystem Disk Default Root Path）
  - OK: `config/filesystems.php` に `local` ディスクが明示されている。**AIが設定ファイルを新しい雛形に合わせていると、`root` が `storage_path('app/private')` になり、既存のファイルが「見つからない」状態になる**（L90-02 と組み合わさると、エラーにならずに `null` が返る）
- [ ] **L120-04** 🟡🔍 **`Schema::getTables()` などが全スキーマを返し、`getTableListing()` がスキーマ名付きを返す**
  - OK: 結果を使っている処理（テーブルの一覧からの処理、テストのDBの掃除など）で、`main.users` のような名前を前提にしている
- [ ] **L120-05** 🟡🔍 **`mergeIfMissing` がドット記法をネストした配列として扱う**
- [ ] **L120-06** 🔴🔍 **`Grammar::setConnection()` / `Connection::withTablePrefix()` の削除**（独自のDBドライバ・Grammarを作っている場合）
- [ ] **L120-07** 🟡 **同じ名前のルートは最初に登録したものが使われる**（Route Precedence）
  - OK: ルート名の重複がない（L70-15）。**キャッシュなし（開発環境）とキャッシュあり（本番）で挙動が同じになった**ので、以前は本番でだけ起きていた違いが、開発環境でも見えるようになる
- [ ] **L120-09** 🟡 **コンテナがクラスのプロパティのデフォルト値を尊重**（Container Class Dependency Resolution）
  - OK: `public function __construct(public ?Carbon $date = null)` のようなnull許容でデフォルト値のある引数を、コンテナが自動で注入してくれることを前提にしていない（12.x以降は `null` のまま）
- [ ] **L120-10** 🟡 **`Concurrency::run` に連想配列を渡すと、結果もそのキーで返る**
- [ ] **L120-11** ⚪ **`DatabaseTokenRepository` のコンストラクタの `$expires` が分から秒に**（パスワードリセットのトークンの仕組みを自前で組み立てている場合）
- [ ] **L120-12** ⚙️ **PHPUnit 11 / Pest 3**: docblockのアノテーションが非推奨（13.xのPHPUnit 12で削除。`12_pitfalls_outside_official_guides.md`）

## ⚪ 独自のDBドライバ・スキーマビルダ・Grammarを作っている場合だけ

- [ ] `Blueprint` と `Grammar` のコンストラクタが `Connection` を必須に。`Blueprint::getPrefix()`、`Grammar::getTablePrefix()` / `setTablePrefix()` は非推奨（`$connection->getTablePrefix()` を使う）


<!-- ===== 10_laravel_12_to_13.md ===== -->

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


<!-- ===== 11_php_7.4_to_8.5_checklist.md ===== -->

# 11. PHP 7.4 → 8.5 での変更

PHP公式の移行ノート（php-src の `UPGRADING`）の「Backward Incompatible Changes」「Deprecated Functionality」「Removed Extensions」から、一般的なWebアプリケーションで影響しうるものを抜き出したものです。

| PHP | 原文 |
|---|---|
| 8.0 | https://github.com/php/php-src/blob/PHP-8.0/UPGRADING |
| 8.1 | https://github.com/php/php-src/blob/PHP-8.1/UPGRADING |
| 8.2 | https://github.com/php/php-src/blob/PHP-8.2/UPGRADING |
| 8.3 | https://github.com/php/php-src/blob/PHP-8.3/UPGRADING |
| 8.4 | https://github.com/php/php-src/blob/PHP-8.4/UPGRADING |
| 8.5 | https://github.com/php/php-src/blob/PHP-8.5/UPGRADING |

- 記号: 🔴エラーになる / 🟡静かに変わる / ⚙️設定・環境 / ⚪まれ / 🔍`audit_grep.sh` で検索できる
- **非推奨（Deprecated）は、PHP 8.5の時点ではエラーではない**（警告がログに出るだけ）。ただし、Laravelは設定によって非推奨の警告を例外にしない一方、**テストの設定（PHPUnitの `failOnDeprecation` など）やエラーの監視によっては失敗として扱われる**。PHP 9で削除される予告なので、ここで潰しておく

## 全バージョン共通

- [ ] ⚙️ **PHP 8.5で `php -l` を全ファイルにかけた**（`00_how_to_audit.md` の手順1）。コンパイル時に出る非推奨（暗黙のnull許容型、バッククォート、非正規のキャスト、`case` の後のセミコロン、`"${var}"`、省略可能な引数の後の必須の引数など）はここでまとめて出る
- [ ] ⚙️ **実行時の非推奨の警告をログで集める**: `config/logging.php` の `deprecations` チャンネル（環境変数 `LOG_DEPRECATIONS_CHANNEL`）を有効にして、ステージングなどで一定期間動かし、出た警告を潰す（null を渡す系や動的プロパティは実行しないと出ない）
- [ ] ⚙️ **CLI（cron・キューワーカー）とWeb（PHP-FPMなど）の両方が8.5**で、**PHP拡張とphp.iniの設定が両方で同じ**
- [ ] ⚙️ **静的解析**（PHPStan / Larastan）で型の不整合を拾った

---

## PHP 8.0

### エラーの扱いが厳しくなった

- [ ] **P80-20** 🔴 **多くの警告が例外（`Error` / `TypeError` / `ValueError`）になった**
  - null・false・空文字列のプロパティへの書き込み（以前は暗黙に `stdClass` を作っていた）、配列やオブジェクトを配列のキーに使う、スカラー値に配列の添字で書き込む、配列でないものの展開
  - 組み込み関数に間違った型の引数を渡すと `TypeError`（例: `strlen([])`、`count(null)`、`count('abc')`）、範囲外の値なら `ValueError`
  - **`count()` に配列でもCountableでもないものを渡すと `TypeError`** になったのは、古いコードで特に多い（`count($maybeNull)`）
- [ ] **P80-21** 🟡 **多くのNoticeがWarningに**: 未定義の変数・配列のキー・プロパティの読み込みなど。Laravelはデフォルトで警告を例外（`ErrorException`）に変えるので、**画面やジョブが500になる**。ログの量にも注意
- [ ] **P80-22** ⚙️ **デフォルトの `error_reporting` が `E_ALL`、`display_startup_errors` が有効**: 本番のphp.iniで `display_errors=Off` を明示する
- [ ] **P80-23** 🔴 **`@` 演算子で致命的なエラーを抑止できない**
- [ ] **P80-24** 🔴 **メソッドのシグネチャの互換性違反（LSP違反）が常に致命的エラー**: 親クラスやインターフェースと引数・戻り値の型が合わないクラスは、**読み込んだ時点で落ちる**（`php artisan` のキャッシュのコマンドや静的解析で拾える）

### 比較・型

- [ ] **P80-08** 🟡🔍 **数値と数値でない文字列の比較**: 数値を文字列にして比べるようになり、**`0 == "abc"` が `true` から `false` に**
  - OK: 非厳密な比較（`==`、`in_array` / `array_search` の第3引数なし、`switch`）で、数値と文字列を比べる箇所の結果が意図どおり
- [ ] **P80-25** 🟡 **数値形式の文字列の扱い**: `"123abc"` のような先頭だけ数値の文字列は算術で警告、`"abc"` は `TypeError`。末尾の空白は許可
- [ ] **P80-26** 🟡 **浮動小数点数から文字列への変換がロケールに依存しない**（常に `.` が小数点）
- [ ] **P80-09** 🟡🔍 **PDOのデフォルトのエラーモードが例外に**: Laravelを通さずに `new PDO` している箇所の挙動

### 構文・削除された機能

- [ ] **P80-01** 🔴🔍 **削除された関数**: `create_function` `each` `money_format` `hebrevc` `convert_cyr_string` `restore_include_path` `get_magic_quotes_gpc` `get_magic_quotes_runtime` `fgetss` `image2wbmp` `read_exif_data` `gmp_random` `ldap_sort` など
- [ ] **P80-02** 🔴🔍 **`__autoload()`、`$php_errormsg`、`(real)` / `(unset)` キャストの削除**
- [ ] **P80-03** 🔴🔍 **大文字小文字を区別しない定数**（`define()` の第3引数 `true`）の削除
- [ ] **P80-04** 🔴🔍 **波括弧のオフセットアクセス**（`$str{0}`）の削除
- [ ] **P80-05** 🟡🔍 **リソースからオブジェクトへの変更**: GD・cURL・OpenSSL・Sockets・XMLParser・Zlibなどが、リソースではなくオブジェクトを返す。**`is_resource()` で確認している箇所は `false` になり、エラーにならずに分岐が変わる**（`!== false` などで判定する）
- [ ] **P80-06** 🔴🔍 **`parse_str()` / `mb_parse_str()` は結果の配列の引数が必須**
- [ ] **P80-07** 🔴🔍 **引数なしの `mktime()` / `gmmktime()`**（`time()` を使う）
- [ ] **P80-10** 🔴🔍 **`password_hash()` の `salt` オプション、ソルトなしの `crypt()`**
- [ ] **P80-11** 🟡🔍 **並べ替えの比較関数が真偽値を返すと非推奨**（`return $a > $b;` → `return $a <=> $b;`）
- [ ] **P80-12** 🔴🔍 **`libxml_disable_entity_loader()`（非推奨）、`ReflectionParameter::getClass()` / `isArray()` / `isCallable()`（非推奨）**
- [ ] **P80-13** 🔴🔍 **Zipの手続き型のAPI**（`zip_open` など。非推奨）
- [ ] **P80-27** 🔴 **`match` が予約語に**（`match` という名前の関数・クラス・定数）
- [ ] **P80-28** 🔴 **ネストした三項演算子は括弧が必須**、**文字列連結 `.` と `+` `-` の優先順位の変更**
- [ ] **P80-29** 🔴 **PHP 4形式のコンストラクタ**（クラス名と同じ名前のメソッド）が使えない、**静的でないメソッドを静的に呼べない**、**未定義の定数が常に `Error`**
- [ ] **P80-30** 🔴 **`array_key_exists()` にオブジェクトを渡せない**、**`implode()` の引数を逆順にできない**
- [ ] **P80-31** ⚙️ **XML-RPC拡張が本体から外れた**、**`mbstring.func_overload` の削除**

---

## PHP 8.1

- [ ] **P81-08** 🟡 **組み込み関数の、nullを許容しない引数に `null` を渡すと非推奨**（`strlen(null)`、`str_replace('a', 'b', null)`、`trim(null)`、`htmlspecialchars(null)` など）
  - **古いコードで最も大量に出る警告**。DBのnullの値がそのまま文字列関数に渡るのが典型
  - 対処として `?? ''` を足すのは正しい場合もあるが、**nullになるべきでない値がnullになっている原因を隠していないか**も確認する（`00_how_to_audit.md` の手順4）
- [ ] **P81-07** 🟡 **PDO MySQL / PDO SQLiteで整数・浮動小数点数がネイティブな型で返る**（エミュレートされたプリペアドステートメントでも）
  - OK: `$row->id === '1'` のような**文字列との厳密な比較**がない。JSONの出力で `"1"` が `1` に変わっても、受け取る側（フロントエンド、外部システム）が問題ない
  - `PDO::ATTR_STRINGIFY_FETCHES` で従来どおりにもできる
- [ ] **P81-09** 🟡 **MySQLiのデフォルトのエラーモードが例外に**（`new mysqli` を直接使っている場合）
- [ ] **P81-10** 🟡 **`htmlspecialchars()` などのデフォルトのフラグが `ENT_QUOTES | ENT_SUBSTITUTE | ENT_HTML401` に**: シングルクォートもエスケープされる（出力の比較をしているテスト）
- [ ] **P81-01** 🔴🔍 **`strftime()` / `gmstrftime()` / `strptime()` が非推奨**
  - 日本語の曜日・月の表示に `strftime` と `setlocale` を使っている場合は、`Carbon::isoFormat()` / `translatedFormat()` や `IntlDateFormatter` に置き換える
- [ ] **P81-02** 🔴🔍 **`FILTER_SANITIZE_STRING` / `FILTER_SANITIZE_STRIPPED`、`mhash*()`、`date_sunrise()` / `date_sunset()`、`odbc_result_all()`、`FILE_BINARY` / `FILE_TEXT` が非推奨**
- [ ] **P81-03** 🔴🔍 **`Serializable` だけを実装し、`__serialize()` / `__unserialize()` がないのは非推奨**
- [ ] **P81-04** 🔴🔍 **`$GLOBALS` 配列全体への書き込みは不可**（個々の要素はよい）
- [ ] **P81-05** 🟡🔍 **組み込みのインターフェース（`ArrayAccess` `Iterator` `Countable` `JsonSerializable` など）の実装に戻り値の型が必要**: ないと非推奨の警告。`#[\ReturnTypeWillChange]` は暫定の抑止で、PHP 9で効かなくなる
- [ ] **P81-06** 🔴🔍 **オブジェクトに対する `key()` `current()` `next()` `prev()` `reset()` `end()` が非推奨**
- [ ] **P81-11** 🟡 **浮動小数点数から整数への暗黙の変換で精度が失われる場合は非推奨**（`1.5` を配列のキーに使う、など）
- [ ] **P81-12** 🟡 **継承したメソッドの `static` 変数が親のメソッドと共有される**
- [ ] **P81-13** ⚪ **`false` の変数への配列としての書き込み、トレイトの静的メンバーへの直接のアクセス、`void` 関数から参照を返す、が非推奨**

---

## PHP 8.2

- [ ] **P82-06** 🟡 **動的プロパティの作成が非推奨**: 宣言していないプロパティへの代入（`stdClass` と、`__get` / `__set` を持つクラス（Eloquentのモデルなど）は対象外）
  - OK: プロパティを宣言している。`#[\AllowDynamicProperties]` は必要な箇所だけ（P82-03）
  - **自前のクラスや古いパッケージで大量に出やすい**。実行しないと出ないので、ログで集める
- [ ] **P82-01** 🔴🔍 **`"${var}"` / `"${expr}"` の形の埋め込みが非推奨**（`"{$var}"` にする）
  - `audit_grep.sh` はBladeのテンプレートを検索しない（JavaScriptのテンプレートリテラル `` `${x}` `` を大量に誤検知するため）。**Blade内のPHPは、コンパイル済みビューへの `php -l`（`00_how_to_audit.md` の手順1）で確認する**。こちらはPHPの部分だけを正確に拾う
- [ ] **P82-02** 🔴🔍 **`utf8_encode()` / `utf8_decode()` が非推奨**（`mb_convert_encoding()` を使う）。**Shift_JISのCSVの処理などで、本来は不適切な使い方をしていることが多い**ので、置き換えの際に文字コードの前提を確認する
- [ ] **P82-04** 🟡🔍 **`strtolower()` / `strtoupper()` などがロケールに依存しない**（常にASCII）
- [ ] **P82-05** 🟡🔍 **`str_split('')` が空の配列を返す**（以前は `['']`）
- [ ] **P82-07** 🟡 **`ksort()` / `krsort()` の数値形式の文字列の比較がPHP 8の規則に**
- [ ] **P82-08** ⚪ **`call_user_func()` では使えるが `$callable()` では使えないcallable**（`"self::method"` など）、**mbstringの `QPrint` `Base64` `Uuencode` `HTML-ENTITIES`** が非推奨

---

## PHP 8.3

- [ ] **P83-01** 🔴🔍 **引数なしの `get_class()` / `get_parent_class()` が非推奨**
  - 置き換え先は **`self::class` / `get_parent_class(self::class)`（または `parent::class`）**。引数なしの `get_class()` は**メソッドを定義したクラスの名前**を返すので、`self::class` と同じ意味になる
  - **`static::class` にすると、継承先から呼んだときに継承先のクラス名に変わる**（挙動が変わる）。継承先の名前が欲しいという意図が確認できる場合だけ `static::class` にする
- [ ] **P83-02** 🔴🔍 **`assert_options()` と `ASSERT_*` 定数が非推奨**
- [ ] **P83-03** 🟡🔍 **`range()` の挙動の変更**（オブジェクト・配列で `TypeError`、数値形式の文字列の扱いなど）
- [ ] **P83-04** 🟡 **空の文字列・数値でない文字列への `++` / `--` が非推奨**（8.5でさらに進んだ）
- [ ] **P83-05** 🔴 **呼び出しのスタックの上限**（`zend.max_allowed_stack_size`）: 深い再帰で `Error` になる
- [ ] **P83-06** 🟡 **空の配列に負のインデックス `n` を代入すると、次のインデックスは `n+1`**
- [ ] **P83-07** ⚪ **静的プロパティを持つトレイトの再宣言、`mb_strimwidth()` の負の幅、`ldap_connect()` のホストとポートの分離、`MT_RAND_PHP`** など

---

## PHP 8.4

- [ ] **P84-04** 🔴🔍⚙️ **IMAP・OCI8・PDO_OCI・PSpellの拡張が本体から外れた**（PECLへ）
  - OK: 使っていない、またはPECLから全サーバーに入れている。IMAP（メールの受信処理）は `webklex/php-imap` などのPHPだけで書かれたライブラリへの移行も選択肢
- [ ] **P84-01** 🔴🔍 **暗黙のnull許容型が非推奨**: `function f(Foo $x = null)` → `function f(?Foo $x = null)`
  - **古いコードで大量に出る**。Rectorで一括で書き換えられる（`php -l` でも出る）
- [ ] **P84-02** 🔴🔍 **`trigger_error()` の `E_USER_ERROR` が非推奨、`E_STRICT` 定数が非推奨**
- [ ] **P84-03** 🔴🔍 **`fputcsv()` / `fgetcsv()` / `str_getcsv()` / `SplFileObject` のCSVのメソッドで `$escape` 引数の省略が非推奨**
  - OK: CSVの入出力で `$escape` を明示している
  - **挙動を変えずに警告だけ消すなら `escape: '\\'`（従来のデフォルト値）を渡す**。`escape: ''` にするとRFC 4180どおりの扱いになり、**バックスラッシュの直後に `"` がある値の出力・読み込みの結果が変わる**。`''` に変えるのは、その変更を意図した場合だけにする
  - どちらにしても、**CSVの出力の内容が変わらないこと**を旧版の出力と比べて確認する
- [ ] **P84-05** 🔴🔍 **`mysqli_ping()` / `mysqli_kill()` / `mysqli_refresh()`、`lcg_value()`、`xml_set_object()`、引数2つの `stream_context_set_option()` が非推奨**
- [ ] **P84-06** ⚙️🔍 **セッションの設定**: `session.sid_length` `session.sid_bits_per_character` の変更、`session.use_trans_sid` などが非推奨。`session_set_save_handler()` の3つ以上の引数も非推奨
- [ ] **P84-07** ⚙️ **OPcacheのJITのデフォルト**（`opcache.jit=disable`、`opcache.jit_buffer_size=64M`）: `jit_buffer_size` だけでJITを有効にしていたなら、`opcache.jit` も明示しないと無効のまま
- [ ] **P84-08** 🟡 **PCREの更新**: `{,3}` が数量子として解釈されるようになった（正規表現の中のリテラルの `{,`）
- [ ] **P84-09** 🔴 **`round()` が `$mode` を検証**、**`exit()` が関数に近い扱い**、**多くの拡張で不正な引数が例外に**
- [ ] **P84-10** 🟡 **MySQL 8.0.24以上で、待機のタイムアウトのエラーコードが2006から4031に**（エラーコードで再接続を判定している場合。キューワーカーなどの長時間のプロセス）
- [ ] **P84-11** ⚪ **`_` をクラス名に、`0` の負の数乗、`DatePeriod` のISO文字列のコンストラクタ、`ReflectionMethod` の1引数のコンストラクタ、`unserialize()` の大文字の `S` タグ、`CURLOPT_BINARYTRANSFER`** が非推奨

---

## PHP 8.5

- [ ] **X-01** 🔴🔍 **`array_first()` / `array_last()` が本体の関数に**: `laravel/helpers` や自前の同名のヘルパーと衝突する（`12_pitfalls_outside_official_guides.md`）
  - PHP 8.5ではほかにも組み込みの関数が増えている。**自前のグローバル関数と名前が衝突しないか**、原文の「New Functions」の節で確認する（X-04）
- [ ] **P85-01** 🔴🔍 **非正規のキャスト名 `(boolean)` `(integer)` `(double)` `(binary)` が非推奨**
- [ ] **P85-02** 🔴🔍 **`curl_close()` `curl_share_close()` `finfo_close()` `imagedestroy()` `xml_parser_free()` が非推奨**（呼び出しを削除するだけ。PHP 8.0以降はオブジェクトなので、変数がスコープを抜ければ解放される。**長時間動くワーカーで、ハンドルをプロパティに持ち続けている場合**は `unset()` か `null` の代入にする）
- [ ] **P85-03** 🔴🔍 **`$http_response_header` が非推奨**: `file_get_contents()` でHTTPを呼んだ後のレスポンスヘッダーは `http_get_last_response_headers()` で取る
- [ ] **P85-04** 🔴🔍 **`PDO` クラスのドライバ固有の定数・メソッドが非推奨**: `PDO::MYSQL_ATTR_SSL_CA` → `Pdo\Mysql::ATTR_SSL_CA` など。**古い雛形の `config/database.php` の `options` に `PDO::MYSQL_ATTR_SSL_CA` がある**
- [ ] **P85-05** 🔴🔍 **Reflectionの `setAccessible()` が非推奨**（効果がないので削除する）
- [ ] **P85-06** 🟡🔍 **`__sleep()` / `__wakeup()` がソフト非推奨**（`__serialize()` / `__unserialize()` を使う）
- [ ] **P85-07** 🔴🔍 **`SplObjectStorage::attach()` / `detach()` / `contains()`、`socket_set_timeout()`、`DATE_RFC7231` が非推奨**
- [ ] **P85-08** 🔴🔍 **バッククォート演算子（`` `ls` ``）が非推奨**: `shell_exec()` か Laravel の `Process` を使う
  - P82-01 と同じく、Blade内はコンパイル済みビューへの `php -l` で確認する
- [ ] **P85-09** 🔴🔍 **`case` の後のセミコロン（`case 1;`）が非推奨**
- [ ] **P85-10** 🟡🔍 **`null` を配列のオフセットや `array_key_exists()` のキーに使うのが非推奨**（実行時に出る）
- [ ] **P85-11** ⚙️🔍 **php.iniの変更**: `disable_classes` が削除された。**OPcacheが常に本体に組み込まれる**ので、`zend_extension=opcache` の行を見直す（有効・無効は `opcache.enable` / `opcache.enable_cli`）
- [ ] **P85-12** 🟡 **整数で表せない浮動小数点数の整数へのキャスト、`NAN` のキャストで警告**（Laravelでは警告が例外になる）
- [ ] **P85-13** 🟡 **配列でない値（`null` 以外）の `[]` / `list()` での分割代入で警告**
- [ ] **P85-14** ⚪ **定数の再宣言、`__debugInfo()` から `null` を返す、出力ハンドラの中での出力、`chr()` / `ord()` の範囲外の値、`readdir()` などに `null` を渡す、`ArrayObject` / `ArrayIterator` をオブジェクトに使う、`intl.error_level` / `report_memleaks` の設定、`MHASH_*` 定数、PDOの `uri:` 形式のDSN** が非推奨
- [ ] **P85-15** ⚪ **MySQLiのオブジェクトへのコンストラクタの再呼び出しが `Error`、`PDO::FETCH_*` の一部の定数の値の変更、`$_SESSION` のキーに `|`、Intlが ICU 57.1以上を要求**


<!-- ===== 12_pitfalls_outside_official_guides.md ===== -->

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
