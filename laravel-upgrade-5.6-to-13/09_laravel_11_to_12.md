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
