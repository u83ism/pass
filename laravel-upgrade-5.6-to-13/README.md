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
