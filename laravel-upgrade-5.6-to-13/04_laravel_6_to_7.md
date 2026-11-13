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
  - 従来の形式を保つなら、モデル（共通の基底モデルかトレイト）で `serializeDate` を上書きする。6.xまでの実装は `$date->format($this->getDateFormat())` だったので、これに戻すのが最も忠実

    ```php
    protected function serializeDate(\DateTimeInterface $date)
    {
        return $date->format($this->getDateFormat());
    }
    ```

  - **`protected $dateFormat` を設定しても直らない**。13の `serializeDate` は `Carbon::instance($date)->toJSON()` を返すだけで、`$dateFormat` を見ない（`$dateFormat` はDBへの読み書きの形式）。逆に、全モデルに `$dateFormat` を追加すると、マイクロ秒付きのカラム（`datetime(6)`）などで**DBへの保存の形式が変わる**ので、追加した場合は既存の値の形式と合っているか確認する
  - `$casts` で `'datetime:Y-m-d H:i'` のように形式を指定した属性は、その形式で出力される（`serializeDate` の影響を受けない）
  - **モデルを通さない日付**（`response()->json(['at' => now()])` のように Carbon を直接JSONにする箇所）は、`serializeDate` では直らない。5.6のCarbon 1では `{"date": "...", "timezone_type": 3, "timezone": "Asia/Tokyo"}` という**オブジェクト**だったものが、Carbon 2以降はISO-8601の**文字列**になっている
  - **確認の方法（AIの判断を待たずに自分で確かめられる）**: 旧版と新版の両方で、同じレコードを出力して比べる

    ```bash
    php artisan tinker --execute 'echo App\User::first()->toJson(), PHP_EOL, json_encode(["now" => now()]), PHP_EOL;'
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
