#!/usr/bin/env bash
# Laravel 5.6/PHP 7.4 → Laravel 13/PHP 8.5 アップグレード後の抜け漏れ監査スクリプト
#
# 使い方:
#   bash audit_grep.sh <Laravelプロジェクトのルート> > audit_result.md
#
# - 各チェックのIDは、同じディレクトリのチェックリスト（01_〜12_ の各ファイル）のIDと対応する
# - 「ヒットした＝問題がある」ではない。ヒットした箇所を、チェックリストの「OKの状態」と照らして確認する
# - 「ヒットしない＝問題がない」でもない。書き方の揺れ（変数経由の呼び出しなど）は拾えない
# - 読み取りだけを行い、ファイルは一切変更しない
# - GNU grep を前提とする（Linux / WSL / Git for Windows の grep）

set -u

ROOT="${1:-.}"
cd "$ROOT" || { echo "ディレクトリに移動できません: $ROOT" >&2; exit 1; }

MAX_LINES="${MAX_LINES:-40}"   # 1チェックあたりに表示する最大行数
CODE_DIRS=()
for d in app bootstrap config database resources routes tests src lib; do
  [ -d "$d" ] && CODE_DIRS+=("$d")
done
EXCLUDES=(--exclude-dir=vendor --exclude-dir=node_modules --exclude-dir=storage --exclude-dir=.git --exclude-dir=public)

HITS_FILE="$(mktemp)"
trap 'rm -f "$HITS_FILE"' EXIT

print_hits() {
  # $1: ID, $2: 種別, $3: タイトル, 標準入力: grepの結果
  local id="$1" kind="$2" title="$3" out count
  out="$(cat)"
  if [ -z "$out" ]; then
    count=0
  else
    count="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
  fi
  if [ "$count" -eq 0 ]; then
    echo "- [$id] $kind $title … 0件"
    return
  fi
  echo "$count" >> "$HITS_FILE"
  echo
  echo "### [$id] $kind $title … ${count}件"
  echo
  echo '```'
  printf '%s\n' "$out" | head -n "$MAX_LINES"
  if [ "$count" -gt "$MAX_LINES" ]; then
    echo "…ほか $((count - MAX_LINES)) 件（MAX_LINES=件数 で表示件数を変えられる）"
  fi
  echo '```'
}

# chk ID 種別 タイトル 正規表現 [対象ディレクトリ...]
chk() {
  local id="$1" kind="$2" title="$3" re="$4"
  shift 4
  local dirs=("$@")
  [ "${#dirs[@]}" -eq 0 ] && dirs=("${CODE_DIRS[@]}")
  local existing=()
  for d in "${dirs[@]}"; do [ -e "$d" ] && existing+=("$d"); done
  if [ "${#existing[@]}" -eq 0 ]; then
    echo "- [$id] $kind $title … 対象なし"
    return
  fi
  grep -rnIE "${EXCLUDES[@]}" --include='*.php' -e "$re" "${existing[@]}" 2>/dev/null | print_hits "$id" "$kind" "$title"
}

# chk_ex ID 種別 タイトル 正規表現 除外する正規表現 [対象ディレクトリ...]
chk_ex() {
  local id="$1" kind="$2" title="$3" re="$4" ex="$5"
  shift 5
  local dirs=("$@")
  [ "${#dirs[@]}" -eq 0 ] && dirs=("${CODE_DIRS[@]}")
  local existing=()
  for d in "${dirs[@]}"; do [ -e "$d" ] && existing+=("$d"); done
  if [ "${#existing[@]}" -eq 0 ]; then
    echo "- [$id] $kind $title … 対象なし"
    return
  fi
  grep -rnIE "${EXCLUDES[@]}" --include='*.php' -e "$re" "${existing[@]}" 2>/dev/null | grep -vE -e "$ex" | print_hits "$id" "$kind" "$title"
}

# chk_php ID 種別 タイトル 正規表現 [対象ディレクトリ...]
# Bladeのテンプレート（*.blade.php）を除いて検索する。BladeにはJavaScriptが混ざり、
# テンプレートリテラル（`...${x}...`）や jQuery の .each() を誤検知するため。
# Bladeの中のPHPは、00_how_to_audit.md の「コンパイル済みビューへの php -l」で確認する
chk_php() {
  local id="$1" kind="$2" title="$3" re="$4"
  shift 4
  local dirs=("$@")
  [ "${#dirs[@]}" -eq 0 ] && dirs=("${CODE_DIRS[@]}")
  local existing=()
  for d in "${dirs[@]}"; do [ -e "$d" ] && existing+=("$d"); done
  if [ "${#existing[@]}" -eq 0 ]; then
    echo "- [$id] $kind $title … 対象なし"
    return
  fi
  grep -rnIE "${EXCLUDES[@]}" --include='*.php' --exclude='*.blade.php' -e "$re" "${existing[@]}" 2>/dev/null | print_hits "$id" "$kind" "$title"
}

# コメント行（//、#、/* */、PHPDoc の * の行）を除くための除外パターン
COMMENT_LINE=':[0-9]+:[[:space:]]*(\*|//|#|/\*)'

# composer.json に指定のパッケージがあるか
chk_pkg() {
  local id="$1" kind="$2" title="$3" re="$4"
  [ -f composer.json ] || { echo "- [$id] composer.json がありません"; return; }
  grep -nE -e "$re" composer.json 2>/dev/null | print_hits "$id" "$kind" "$title"
}

# プロジェクト全体（PHP以外も含む）を検索する。デプロイ設定やSupervisorの設定など
chk_any() {
  local id="$1" kind="$2" title="$3" re="$4"
  grep -rnIE "${EXCLUDES[@]}" --exclude-dir=vendor -e "$re" . 2>/dev/null | grep -v "audit_grep.sh" | print_hits "$id" "$kind" "$title"
}

echo "# アップグレード後の抜け漏れ監査結果"
echo
echo "- 対象: $(pwd)"
echo "- 実行日時: $(date '+%Y-%m-%d %H:%M:%S')"
echo "- 対象ディレクトリ: ${CODE_DIRS[*]}"
echo "- 種別: 🔴=実行されればエラーになる / 🟡=エラーにならず挙動が変わる / ⚙️=設定・環境・データ / 🧹=残骸（動くが整理すべき）"
echo

# ---------------------------------------------------------------------------
echo "## 横断（最優先）"
chk  X-01 "🔴" "array_first()/array_last() の呼び出し（PHP 8.5本体の関数と衝突）" '\barray_(first|last)[[:space:]]*\('
chk_pkg X-02 "🔴" "laravel/helpers への依存が残っている" '"laravel/helpers"'
chk  X-03 "🔴" "削除された str_*/array_* グローバルヘルパーの呼び出し（str_contains/str_starts_with/str_ends_with はPHP 8.0の組み込み関数なので対象外）" '(^|[^>:$a-zA-Z0-9_])(str_(slug|random|limit|plural|singular|snake|studly|camel|kebab|title|after|before|start|finish|is|replace_(first|last|array))|array_(get|set|has|only|except|pluck|where|wrap|add|collapse|divide|dot|flatten|forget|prepend|pull|random|sort_recursive)|starts_with|ends_with|camel_case|snake_case|studly_case|kebab_case|title_case)[[:space:]]*\('
chk  X-04 "🟡" "function_exists で囲った自前のグローバル関数（本体や新しいヘルパーと衝突すると黙って相手が使われる）" "function_exists[[:space:]]*\\([[:space:]]*['\"]"

# ---------------------------------------------------------------------------
echo
echo "## Laravel 5.7（01_laravel_5.6_to_5.7.md）"
chk  L57-01 "🟡" "Blade の or 演算子（13では \"1\" や空文字が出力される）" '\{\{[^}]*[[:space:]]or[[:space:]][^}]*\}\}' resources
chk  L57-02 "🟡" "Route::redirect（301ではなく302になる）" 'Route::redirect[[:space:]]*\(' routes app
chk  L57-03 "🟡" "validate()/validated() の戻り値の利用（ルールのないキーは含まれない）" '=[[:space:]]*(\$request->validate|\$this->validate|request\(\)->validate|Validator::make[^;]*->validate|\$[a-zA-Z_]+->validated)[[:space:]]*\('
chk  L57-04 "🟡" "whereDate に日時を渡している箇所（時刻部分は無視される）" 'whereDate[[:space:]]*\('
chk  L57-05 "🔴" "テストでの \$this->artisan()（出力がモックされる）" '\$this->artisan[[:space:]]*\(' tests
chk  L57-06 "🔴" "Login イベントの手動生成（第1引数に guard が必要）" 'new[[:space:]]+(\\?Illuminate\\Auth\\Events\\)?Login[[:space:]]*\('
chk  L57-07 "🟡" "Markdownメールの旧ボタン色クラス（blue/green/red）" "button-(blue|green|red)|'color'[[:space:]]*=>[[:space:]]*'(blue|green|red)'" resources app

# ---------------------------------------------------------------------------
echo
echo "## Laravel 5.8（02_laravel_5.7_to_5.8.md）"
chk  L58-01 "🟡" "キャッシュのTTL（分ではなく秒。0以下は削除）" '(Cache::|cache\(\)->|->tags\([^)]*\)->)(put|add|remember|putMany|setDefaultCacheTime)[[:space:]]*\(|[^a-zA-Z_]cache\([[:space:]]*\['
chk  L58-02 "🟡" "Cache::lock の利用（別インスタンスでの release は無効）" 'Cache::lock[[:space:]]*\(|->forceRelease|restoreLock'
chk  L58-03 "🟡" "パスワードの min:6（デフォルトの最小文字数は8）" "password[^;]*min:6|min:6[^;]*password"
chk  L58-04 "🔴" "Nexmo/Slack通知（別パッケージが必要。NexmoはVonageへ）" 'routeNotificationFor(Nexmo|Slack)|toNexmo|toSlack|NexmoMessage|SlackMessage|'"'"'nexmo'"'"''
chk  L58-05 "🔴" "tagged() の結果への添字アクセス（iterable を返す）" 'tagged[[:space:]]*\([^)]*\)[[:space:]]*\['
chk  L58-06 "🟡" "独自のピボットモデル（自動増分IDなら \$incrementing = true が必要）" 'extends[[:space:]]+(\\?Illuminate\\Database\\Eloquent\\Relations\\)?(Pivot|MorphPivot)\b' app
chk  L58-07 "🟡" "\$defer = true の遅延プロバイダ（無視されて即時ロードになる）" 'protected[[:space:]]+\$defer[[:space:]]*=[[:space:]]*true' app
chk  L58-08 "🟡" "実行時の環境変数の変更（env() は読み取り専用）" 'putenv[[:space:]]*\(|\$_ENV\[[^]]*\][[:space:]]*=[^=]|\$_SERVER\[[^]]*\][[:space:]]*=[^=]'
chk  L58-09 "🔴" "Event::fire / ->fire()（削除。dispatch を使う）" 'Event::fire[[:space:]]*\(|event\(\)->fire[[:space:]]*\(|\$(events|dispatcher)->fire[[:space:]]*\('
chk  L58-10 "🔴" "BelongsTo の旧メソッド名（getForeignKey/getOwnerKey など）" '->(getOwnerKey|getQualifiedForeignKey)[[:space:]]*\(|\)->getForeignKey[[:space:]]*\('
chk  L58-11 "🔴" "テストの setUp/tearDown に : void がない" 'function[[:space:]]+(setUp|tearDown|setUpBeforeClass|tearDownAfterClass)[[:space:]]*\([[:space:]]*\)[[:space:]]*(\{|$)' tests
chk  L58-12 "🟡" "MySQLのJSONの ->> 演算子（サポートされない）" "['\"][a-zA-Z_]+->>"
if [ -d resources/views/vendor/mail/markdown ]; then
  echo "- [L58-13] 🔴 resources/views/vendor/mail/markdown が存在します（resources/views/vendor/mail/text にリネームが必要）"
else
  echo "- [L58-13] 🔴 旧Markdownメールのディレクトリ … なし"
fi

# ---------------------------------------------------------------------------
echo
echo "## Laravel 6（03_laravel_5.8_to_6.md）"
chk  L60-01 "🔴" "authorizeResource（ポリシーに viewAny がないと index が403）" 'authorizeResource[[:space:]]*\(' app
chk  L60-02 "🔴" "Input ファサード（削除）" '\bInput::|Facades\\Input\b|use[[:space:]]+Input;'
chk  L60-03 "🔴" "Lang::trans / transChoice / getFromJson（改名・統合）" 'Lang::(trans|transChoice|getFromJson)[[:space:]]*\(|->(transChoice|getFromJson)[[:space:]]*\('
chk  L60-04 "🟡" "ポリシーで deny() を return していない" '^[[:space:]]*\$this->deny[[:space:]]*\(' app
chk  L60-05 "🟡" "スケジューラの between/unlessBetween（日付をまたぐ範囲の挙動が修正された）" '->(between|unlessBetween)[[:space:]]*\(' app routes
chk  L60-06 "🟡" "リレーション経由の update（BelongsTo::update はイベントもマスアサイン保護もない）" '->[a-zA-Z_]+\(\)->update[[:space:]]*\(' app
chk  L60-07 "🟡" "主キーを自動増分しないモデル（文字列キーなら \$keyType = 'string' が必要）" '\$incrementing[[:space:]]*=[[:space:]]*false' app
chk_any L60-08 "⚙️" "queue:work の起動設定（--tries のデフォルトは1回）" 'artisan[[:space:]]+(queue:work|queue:listen|horizon)([[:space:]]|$|["'"'"'])'
chk  L60-09 "🟡" "route()/action() に連想配列を渡す（パスにないキーはクエリ文字列になる）" '(route|action|URL::route|URL::action|to_route)[[:space:]]*\([^)]*,[[:space:]]*\[[^]]*=>'
chk  L60-10 "🔴" "email/resend への GET リンク（POST に変わった）" "email/resend|verification\\.resend" resources routes

# ---------------------------------------------------------------------------
echo
echo "## Laravel 7（04_laravel_6_to_7.md）"
chk  L70-01 "🔴" "例外ハンドラの Exception 型の引数（Throwable が必要）" 'function[[:space:]]+(report|render|shouldReport|renderForConsole)[[:space:]]*\([^)]*\bException[[:space:]]+\$' app
chk  L70-02 "🟡" "ジョブ・リスナーの failed(Exception \$e)（Error が起きると TypeError）" 'function[[:space:]]+failed[[:space:]]*\([^)]*\bException[[:space:]]+\$' app
chk  L70-03 "🟡" "Artisanコマンドで true/false/文字列を return（(int) にキャストされ、true は終了コード1=失敗）" '^[[:space:]]*return[[:space:]]+(true|false|'"'"'|")' app/Console
chk  L70-04 "🔴" "Blade::component（意味が変わった。旧用途は aliasComponent）" 'Blade::component[[:space:]]*\('
chk  L70-05 "🔴" "ファクトリの types（factory(X::class, 'name')）" "factory[[:space:]]*\\([^)]*::class[[:space:]]*,[[:space:]]*['\"]"
chk  L70-06 "🔴" "addHidden / addVisible（削除）" '->(addHidden|addVisible)[[:space:]]*\('
chk  L70-07 "🟡" "getOriginal（キャスト後の値を返す。生の値は getRawOriginal）" '->getOriginal[[:space:]]*\('
chk  L70-08 "🔴" "Resources\\Json\\Resource（削除。JsonResource を使う）" 'Resources\\Json\\Resource\b'
chk  L70-09 "🔴" "Foundation\\Testing\\TestResponse / Assert（名前空間の変更）" 'Foundation\\Testing\\(TestResponse|Assert)\b'
chk  L70-10 "🟡" "different ルール（パラメータが欠けても失敗）" "different:"
chk  L70-11 "🔴" "モデルの booting/booted メソッドとの衝突" 'function[[:space:]]+(booting|booted)[[:space:]]*\(' app
chk  L70-12 "🔴" "swift.mailer / swift.transport のバインディング" "swift\\.(mailer|transport)"
chk  L70-13 "🟡" "日付のシリアライズ形式を決めている箇所（無ければ全モデルが ISO-8601/UTC で出力）" 'function[[:space:]]+serializeDate[[:space:]]*\(' app
grep -rqE "function[[:space:]]+serializeDate" app 2>/dev/null || echo "  ⚠ serializeDate がどこにも定義されていません。モデルのJSON/配列の日付は 2019-12-02T20:01:00.000000Z 形式（UTC）で出力されます。意図どおりか確認してください（L70-13）"

# ---------------------------------------------------------------------------
echo
echo "## Laravel 8（05_laravel_7_to_8.md）"
chk_pkg L80-01 "🔴" "composer.json の classmap（database/seeds 等）" '"classmap"|database/seeds'
[ -d database/seeds ] && echo "  ⚠ [L80-01] database/seeds ディレクトリが残っています（database/seeders と Database\\Seeders 名前空間が必要）"
chk  L80-02 "🧹" "旧形式のファクトリ（\$factory->define / factory() ヘルパー）" '\$factory->(define|state|afterCreating)|[^a-zA-Z_>:]factory[[:space:]]*\([[:space:]]*[A-Z\\]'
chk_pkg L80-03 "🧹" "laravel/legacy-factories が残っている" '"laravel/legacy-factories"'
chk  L80-04 "🟡" "ページネーションの links()（Bootstrap なら Paginator::useBootstrap() が必要）" '->links[[:space:]]*\(' resources
chk  L80-05 "🟡" "Paginator::useBootstrap* の呼び出し（L80-04 と突き合わせる）" 'Paginator::useBootstrap'
chk  L80-06 "🟡" "retryAfter / timeoutAt（無視される。backoff / retryUntil に改名）" '\bretryAfter\b|\btimeoutAt\b' app
chk  L80-07 "🔴" "allOnQueue / allOnConnection（withChain との組み合わせは削除）" '->(allOnQueue|allOnConnection)[[:space:]]*\('
chk_any L80-08 "🔴" "artisan down --message（削除）" 'down[[:space:]]+[^|;]*--message'
chk  L80-09 "🟡" "モデルの increment/decrement（updating/updated/saving/saved が発火）" '->(increment|decrement)[[:space:]]*\(' app
chk  L80-10 "🔴" "EventServiceProvider の register（parent::register() が必要）" 'function[[:space:]]+register[[:space:]]*\(' app/Providers/EventServiceProvider.php
chk  L80-11 "🔴" "elixir() / Mail::sendNow / decodeResponseJson(引数)" '[^a-zA-Z_]elixir[[:space:]]*\(|Mail::sendNow|->sendNow[[:space:]]*\(|decodeResponseJson[[:space:]]*\([[:space:]]*[^)[:space:]]'
chk  L80-12 "🔴" "文字列形式のコントローラ指定（RouteServiceProvider の \$namespace が必要）" "['\"][A-Za-z0-9_\\\\]*Controller@[A-Za-z0-9_]+['\"]" routes app
chk  L80-13 "⚙️" "コントローラ名前空間の設定（L80-12 と突き合わせる）" 'protected[[:space:]]+\$namespace|->namespace[[:space:]]*\(' app/Providers bootstrap

# ---------------------------------------------------------------------------
echo
echo "## Laravel 9（06_laravel_8_to_9.md）"
chk  L90-01 "🟡" "Storage の書き込み・読み込み（失敗は例外ではなく false/null）" 'Storage::(disk\([^)]*\)->)?(put|putFile|putFileAs|write|writeStream|get|readStream|delete|move|copy|prepend|append)[[:space:]]*\(|->(putFile|putFileAs|storeAs|store)[[:space:]]*\('
chk  L90-02 "🟡" "FileNotFoundException の catch（存在しないファイルは null を返す）" 'FileNotFoundException'
chk  L90-03 "⚙️" "filesystems.php の throw 設定（無ければ失敗に気づけない）" "'throw'[[:space:]]*=>" config
chk  L90-04 "🔴" "SwiftMailer 由来のコード（Swift_* / withSwiftMessage など）" 'Swift_|withSwiftMessage|getSwiftMessage|swiftmailer'
chk  L90-05 "⚙️" "Postgres の schema 設定（search_path に改名）" "'schema'[[:space:]]*=>" config
chk  L90-06 "🟡" "独自のキャスト（set に null が渡るようになった）" 'implements[[:space:]]+[^{]*CastsAttributes|implements[[:space:]]+[^{]*CastsInboundAttributes' app
chk  L90-07 "🟡" "when/unless にクロージャを渡す（戻り値で判定されるようになった）" '->(when|unless)[[:space:]]*\([[:space:]]*(function|fn)[[:space:]]*\('
chk  L90-08 "🟡" "HTTPクライアントの利用（デフォルトのタイムアウト30秒）" 'Http::(get|post|put|patch|delete|send|withHeaders|withToken|asForm|attach|withBasicAuth|withOptions|acceptJson|baseUrl|retry|pool)\b'
chk  L90-09 "🔴" "assertDeleted（assertModelMissing に改名）" '->assertDeleted[[:space:]]*\(' tests
chk_ex L90-10 "🔴" "password バリデーションルール（current_password に改名）" "\\|password(:[a-z_]+)?['\"|]|['\"]password(:[a-z_]+)?\\|" "grant_type|current_password|[Ff]illable|[Hh]idden|->(only|except)[[:space:]]*\\("
chk  L90-11 "🔴" "Fideloper\\Proxy（削除。Illuminate の TrustProxies を使う）" 'Fideloper'
chk  L90-12 "🔴" "reduceWithKeys / reduceMany / registerCustomDoctrineType" '->(reduceWithKeys|reduceMany|registerCustomDoctrineType)[[:space:]]*\('
chk  L90-13 "🔴" "自前の str() グローバル関数の定義" 'function[[:space:]]+str[[:space:]]*\('
chk  L90-14 "🔴" "BelongsToMany の firstOrNew/firstOrCreate/updateOrCreate（比較対象が関連先テーブルに）" '\)->(firstOrNew|firstOrCreate|updateOrCreate)[[:space:]]*\(' app
chk_pkg L90-15 "🔴" "旧CORSパッケージ（fruitcake/barryvdh）" '"(fruitcake|barryvdh)/laravel-cors"'
chk  L90-16 "🔴" "Fruitcake\\Cors のミドルウェア参照" 'Fruitcake\\Cors|Barryvdh\\Cors'
chk_pkg L90-17 "🔴" "facade/ignition（spatie/laravel-ignition に置き換え）" '"facade/ignition"'

# ---------------------------------------------------------------------------
echo
echo "## Laravel 10（07_laravel_9_to_10.md）"
chk  L100-01 "🔴" "DB::raw() の文字列としての利用（(string) や連結は不可）" '\(string\)[[:space:]]*DB::raw|DB::raw[[:space:]]*\([^)]*\)[[:space:]]*\.[^.]|[^.]\.[[:space:]]*DB::raw[[:space:]]*\(|DB::raw[^;]*->__toString'
chk  L100-02 "🟡" "モデルの \$dates（削除。日付にキャストされなくなる）" 'protected[[:space:]]+\$dates\b' app
chk  L100-03 "🔴" "MocksApplicationServices のメソッド（expectsEvents など）" '->(expectsEvents|expectsJobs|expectsNotifications|doesntExpectEvents|doesntExpectJobs|withoutEvents|withoutJobs)[[:space:]]*\(' tests
chk  L100-04 "🔴" "dispatchNow / dispatch_now（dispatchSync へ）" 'dispatchNow|dispatch_now'
chk  L100-05 "🔴" "Redirect::home（削除）" 'Redirect::home|redirect\(\)->home[[:space:]]*\('
chk  L100-06 "⚙️" "Monolog を直接使う箇所（Monolog 3）" 'Monolog\\' app config
chk  L100-07 "🟡" "Cache::tags（Redis では 12.30.0 以上が必要）" 'Cache::tags|->tags[[:space:]]*\(' app
chk  L100-08 "🔴" "FormRequest の after() メソッド（予約された）" 'function[[:space:]]+after[[:space:]]*\(' app/Http/Requests

# ---------------------------------------------------------------------------
echo
echo "## Laravel 11（08_laravel_10_to_11.md）"
chk  L110-01 "⚙️" "マイグレーションの ->change()（書かなかった属性は削除される）" '->change[[:space:]]*\(' database
chk  L110-02 "⚙️" "double/float の桁指定・unsigned* の浮動小数点数" '->(double|float)[[:space:]]*\([^)]*,|->(unsignedDecimal|unsignedDouble|unsignedFloat)[[:space:]]*\(' database
chk  L110-03 "🟡" "Carbon の diffIn*（Carbon 3 では浮動小数点数・負の値を返す）" 'diffIn(Seconds|Minutes|Hours|Days|Weekdays|Weekends|Weeks|Months|Quarters|Years|Microseconds|Milliseconds|RealSeconds|RealMinutes|RealHours|Real)?[[:space:]]*\('
chk  L110-04 "🟡" "レート制限・ThrottlesExceptions（分ではなく秒）" 'new[[:space:]]+(Global)?Limit[[:space:]]*\(|decayMinutes|new[[:space:]]+ThrottlesExceptions(WithRedis)?[[:space:]]*\('
chk  L110-05 "🔴" "空間データの型（geometry/geography に統一）" '->(point|lineString|polygon|geometryCollection|multiPoint|multiLineString|multiPolygon|multiPolygonZ)[[:space:]]*\(' database
chk  L110-06 "🔴" "Doctrine DBAL の利用" 'Doctrine\\DBAL|getDoctrine(SchemaManager|Column|Connection)|registerDoctrineType|getAllTables|getAllViews|getAllTypes'
chk_ex L110-07 "🔴" "モデルの casts という名前のメソッド・リレーション（基底クラスと衝突）" 'function[[:space:]]+casts[[:space:]]*\(' 'casts[[:space:]]*\([[:space:]]*\)[[:space:]]*:[[:space:]]*array' app
chk  L110-08 "🟡" "独自の getAuthPassword（パスワード列名が password 以外なら \$authPasswordName が必要）" 'function[[:space:]]+getAuthPassword[[:space:]]*\(|authPasswordName' app
chk  L110-09 "🟡" "SendEmailVerificationNotification の登録（自動登録と二重になると確認メールが2通）" 'SendEmailVerificationNotification' app
chk_pkg L110-10 "🔴" "spatie/once（Laravel の once() と衝突）" '"spatie/once"'
chk_pkg L110-11 "⚙️" "マイグレーションの publish が必要なパッケージ（sanctum/passport/telescope/cashier/spark）" '"laravel/(sanctum|passport|telescope|cashier|spark-stripe)"'
if [ -f composer.json ] && grep -q '"laravel/passport"' composer.json; then
  chk  L110-12 "⚙️" "Passport のパスワードグラント（デフォルトで無効。使っているなら enablePasswordGrant が必要）" "enablePasswordGrant|PasswordGrant|password_client|passport\\.password"
else
  echo "- [L110-12] ⚙️ Passport のパスワードグラント … laravel/passport を使っていないので対象外"
fi
chk  L110-13 "⚙️" "キャッシュのキーの接頭辞（末尾の ':' が付かなくなった）" "'prefix'[[:space:]]*=>" config/cache.php config/database.php

# ---------------------------------------------------------------------------
echo
echo "## Laravel 12（09_laravel_11_to_12.md）"
chk  L120-01 "🟡" "HasUuids（UUIDv7 を返す）/ HasVersion7Uuids（削除）" 'HasUuids|HasVersion7Uuids' app
chk  L120-02 "🟡" "image バリデーションルール（SVG を拒否）" "['\"|]image(['\"|:]|$)|File::image|Rule::imageFile|->image\(\)" app
chk  L120-03 "⚙️" "local ディスクの定義（無ければルートが storage/app/private）" "'local'[[:space:]]*=>" config/filesystems.php
chk  L120-04 "🟡" "Schema::getTables/getTableListing（全スキーマ・スキーマ名付きを返す）" 'Schema::(getTables|getViews|getTypes|getTableListing)[[:space:]]*\('
chk  L120-05 "🟡" "mergeIfMissing にドット記法のキー" "mergeIfMissing[[:space:]]*\\([^)]*['\"][a-zA-Z_]+\\.[a-zA-Z_]"
chk  L120-06 "🔴" "Grammar::setConnection / Connection::withTablePrefix（削除）" '->(setConnection|withTablePrefix)[[:space:]]*\(' app

# ---------------------------------------------------------------------------
echo
echo "## Laravel 13（10_laravel_12_to_13.md）"
chk  L130-01 "🔴" "VerifyCsrfToken / ValidateCsrfToken の参照（PreventRequestForgery に改名・Sec-Fetch-Site の検証）" 'VerifyCsrfToken|ValidateCsrfToken'
chk  L130-02 "⚙️" "CSRF の除外設定（外部からのPOSTが弾かれないか）" '\$except[[:space:]]*=|validateCsrfTokens[[:space:]]*\(|preventRequestForgery[[:space:]]*\(' app bootstrap
chk  L130-03 "⚙️" "cache の serializable_classes（false ならオブジェクトのキャッシュが読めない）" "serializable_classes" config
chk  L130-04 "⚙️" "session の serialization（json に変えると全セッションが無効）" "'serialization'[[:space:]]*=>" config
chk  L130-05 "🔴" "upsert（uniqueBy が空だと例外）" '->upsert[[:space:]]*\('
chk  L130-06 "🔴" "JobAttempted / QueueBusy イベントのプロパティ" 'exceptionOccurred|QueueBusy'
chk  L130-07 "🟡" "ページネーションの旧ビュー名（pagination::default など）" 'pagination::(default|simple-default)'
chk  L130-08 "🟡" "Manager の extend（クロージャの \$this がマネージャーになる）" '::extend[[:space:]]*\(' app
chk  L130-09 "🟡" "Str のファクトリ（テストの終了時にリセットされる）" 'Str::(createUuidsUsing|createUlidsUsing|createRandomStringsUsing|freezeUuids|freezeUlids)' tests
chk  L130-10 "🟡" "ポリモーフィックな多対多で独自ピボット（テーブル名が複数形に）" '->using[[:space:]]*\(' app
chk  L130-11 "🟡" "Js::from / @js（Unicode をエスケープしない）" 'Js::from|@js[[:space:]]*\('
chk  L130-12 "🟡" "パスワードリセットのメールの件名に依存" 'Reset Password Notification'
chk  L130-13 "🟡" "ドメイン指定のルート（優先して照合される）" 'Route::domain[[:space:]]*\(|->domain[[:space:]]*\(' routes app
chk  L130-14 "🔴" "モデルの static boot / boot* メソッド（中で同じモデルをインスタンス化すると LogicException）" 'static[[:space:]]+function[[:space:]]+boot[A-Za-z]*[[:space:]]*\(' app

# ---------------------------------------------------------------------------
echo
echo "## PHP 8.0（11_php_7.4_to_8.5_checklist.md）"
chk  P80-01 "🔴" "削除された関数（create_function / each / money_format など）" '(^|[^a-zA-Z_>:$.])(create_function|each|money_format|hebrevc|convert_cyr_string|restore_include_path|get_magic_quotes_gpc|get_magic_quotes_runtime|fgetss|gzgetss|ezmlm_hash|image2wbmp|png2wbmp|jpeg2wbmp|read_exif_data|gmp_random|ldap_sort)[[:space:]]*\('
chk  P80-02 "🔴" "__autoload / \$php_errormsg / (real) / (unset) キャスト" '__autoload|\$php_errormsg|\((real|unset)\)'
chk  P80-03 "🔴" "大文字小文字を区別しない定数（define の第3引数 true）" 'define[[:space:]]*\([^)]*,[^)]*,[[:space:]]*true[[:space:]]*\)'
chk  P80-04 "🔴" "波括弧での文字列・配列のオフセットアクセス（\$str{0}）" '\$[a-zA-Z_][a-zA-Z0-9_]*\{[0-9$][^}]*\}'
chk  P80-05 "🟡" "is_resource()（多くの拡張がオブジェクトを返すようになった）" 'is_resource[[:space:]]*\('
chk  P80-06 "🔴" "parse_str / mb_parse_str の第2引数なし" '(^|[^a-zA-Z_])(mb_)?parse_str[[:space:]]*\([^,()]*\)'
chk  P80-07 "🔴" "引数なしの mktime() / gmmktime()" '(^|[^a-zA-Z_])g?mmktime[[:space:]]*\([[:space:]]*\)|(^|[^a-zA-Z_])mktime[[:space:]]*\([[:space:]]*\)'
chk_ex P80-08 "🟡" "非厳密な in_array / array_search（0 == \"abc\" が false に）" '(in_array|array_search)[[:space:]]*\(' 'true[[:space:]]*\)' app
chk  P80-09 "🟡" "Laravel を通さない PDO / mysqli の直接利用（エラーモードがデフォルトで例外）" 'new[[:space:]]+\\?PDO[[:space:]]*\(|new[[:space:]]+\\?mysqli[[:space:]]*\(|mysqli_(connect|query|real_connect)[[:space:]]*\('
chk  P80-10 "🔴" "password_hash の salt オプション / 引数1つの crypt()" "'salt'[[:space:]]*=>|(^|[^a-zA-Z_])crypt[[:space:]]*\\([^,()]*\\)"
chk  P80-11 "🟡" "usort などの比較関数で真偽値を返す" 'return[[:space:]]+\$[a-zA-Z_]+[^;]*[[:space:]](>|<)[[:space:]]+\$[a-zA-Z_]+[^;]*;'
chk  P80-12 "🔴" "libxml_disable_entity_loader / ReflectionParameter::getClass" 'libxml_disable_entity_loader|->getClass[[:space:]]*\(\)|->isArray[[:space:]]*\(\)|->isCallable[[:space:]]*\(\)'
chk  P80-13 "🔴" "Zip の手続き型 API" '(^|[^a-zA-Z_])zip_(open|read|close|entry_[a-z]+)[[:space:]]*\('

echo
echo "## PHP 8.1"
chk  P81-01 "🔴" "strftime / gmstrftime / strptime（非推奨）" '(^|[^a-zA-Z_])(g?mstrftime|strftime|strptime)[[:space:]]*\('
chk  P81-02 "🔴" "FILTER_SANITIZE_STRING / mhash / date_sunrise 等（非推奨）" 'FILTER_SANITIZE_STRING|FILTER_SANITIZE_STRIPPED|(^|[^a-zA-Z_])mhash[a-z_]*[[:space:]]*\(|date_sun(rise|set)[[:space:]]*\(|odbc_result_all|FILE_BINARY|FILE_TEXT'
chk  P81-03 "🔴" "Serializable インターフェースの実装（__serialize/__unserialize も必要）" 'implements[[:space:]]+[^{]*\bSerializable\b'
chk  P81-04 "🔴" "\$GLOBALS 配列全体への書き込み" '\$GLOBALS[[:space:]]*=[^=]|array_[a-z_]+[[:space:]]*\([[:space:]]*\$GLOBALS'
chk  P81-05 "🟡" "#[\\ReturnTypeWillChange]（暫定の抑止。PHP 9 で効かなくなる）" 'ReturnTypeWillChange'
chk  P81-06 "🔴" "オブジェクトに対する key()/current()/next()/reset()/end()" '(^|[^a-zA-Z_>:])(key|current|next|prev|reset|end)[[:space:]]*\([[:space:]]*\$this\b'

echo
echo "## PHP 8.2"
chk_php P82-01 "🔴" "\"\${var}\" 形式の文字列の埋め込み（非推奨。Blade内はコンパイル済みビューの php -l で確認）" '"[^"]*\$\{[a-zA-Z_]'
chk  P82-02 "🔴" "utf8_encode / utf8_decode（非推奨）" 'utf8_(encode|decode)[[:space:]]*\('
chk  P82-03 "🟡" "#[\\AllowDynamicProperties]（動的プロパティを許可している箇所）" 'AllowDynamicProperties'
chk  P82-04 "🟡" "setlocale と strtolower/strtoupper の組み合わせ（ロケールに依存しなくなった）" 'setlocale[[:space:]]*\('
chk  P82-05 "🟡" "str_split（空文字列で空の配列）" '(^|[^a-zA-Z_])str_split[[:space:]]*\('

echo
echo "## PHP 8.3"
chk  P83-01 "🔴" "引数なしの get_class() / get_parent_class()" '(^|[^a-zA-Z_])get_(parent_)?class[[:space:]]*\([[:space:]]*\)'
chk  P83-02 "🔴" "assert_options / ASSERT_* 定数" 'assert_options|ASSERT_(ACTIVE|BAIL|CALLBACK|EXCEPTION|WARNING)'
chk  P83-03 "🟡" "range()（引数の扱いが多数変更）" '(^|[^a-zA-Z_>:])range[[:space:]]*\(' app

echo
echo "## PHP 8.4"
chk_ex P84-01 "🔴" "暗黙の null 許容型（Type \$x = null。?Type が必要。コメント・PHPDocの行は除外）" '(\(|,)[[:space:]]*[A-Za-z_\\][A-Za-z0-9_\\]*[[:space:]]+&?(\.\.\.)?\$[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*null[[:space:]]*[,)]' "$COMMENT_LINE"
chk  P84-02 "🔴" "trigger_error の E_USER_ERROR / E_STRICT" 'E_USER_ERROR|E_STRICT'
chk  P84-03 "🔴" "CSV 関数（\$escape 引数を明示する必要）" '(fputcsv|fgetcsv|str_getcsv|setCsvControl)[[:space:]]*\('
chk  P84-04 "🔴" "本体から外れた拡張（IMAP / OCI8 / PSpell）" '(^|[^a-zA-Z_])(imap_[a-z_]+|oci_[a-z_]+|pspell_[a-z_]+)[[:space:]]*\(|pdo_oci|oci:dbname'
chk  P84-05 "🔴" "mysqli の ping/kill/refresh、lcg_value、xml_set_object、引数2つの stream_context_set_option" 'mysqli_(ping|kill|refresh)|->(ping|refresh)[[:space:]]*\(\)|lcg_value|xml_set_object|stream_context_set_option[[:space:]]*\([^,]*,[^,]*\)'
chk  P84-06 "🔴" "session_set_save_handler の多引数 / session.sid_* の設定" 'session_set_save_handler[[:space:]]*\([^)]*,[^)]*,|sid_length|sid_bits_per_character|use_trans_sid'

echo
echo "## PHP 8.5"
chk  P85-01 "🔴" "非正規のキャスト名 (boolean)/(integer)/(double)/(binary)" '\((boolean|integer|double|binary)\)'
chk  P85-02 "🔴" "curl_close / finfo_close / imagedestroy / xml_parser_free / curl_share_close（非推奨）" '(^|[^a-zA-Z_])(curl_close|curl_share_close|finfo_close|imagedestroy|xml_parser_free)[[:space:]]*\('
chk  P85-03 "🔴" "\$http_response_header（http_get_last_response_headers() へ）" '\$http_response_header'
chk  P85-04 "🔴" "PDO クラスのドライバ固有定数（PDO::MYSQL_ATTR_* など。config/database.php に多い）" 'PDO::(MYSQL|PGSQL|SQLITE|DBLIB|FB|ODBC|OCI)_'
chk  P85-05 "🔴" "Reflection の setAccessible（非推奨）" '->setAccessible[[:space:]]*\('
chk  P85-06 "🟡" "__sleep / __wakeup（ソフト非推奨）" 'function[[:space:]]+__(sleep|wakeup)[[:space:]]*\('
chk  P85-07 "🔴" "SplObjectStorage の attach/detach/contains、socket_set_timeout、DATE_RFC7231" 'SplObjectStorage|socket_set_timeout|RFC7231'
chk_php P85-08 "🔴" "バッククォート演算子（shell_exec の別名。Blade内はコンパイル済みビューの php -l で確認）" '(=|\(|return|echo)[[:space:]]*`'
chk  P85-09 "🔴" "case の後にセミコロン" '^[[:space:]]*(case[[:space:]][^:;?]*|default[[:space:]]*);[[:space:]]*$'
chk  P85-10 "🟡" "null を配列のオフセットや array_key_exists に使う" '\[[[:space:]]*null[[:space:]]*\]|array_key_exists[[:space:]]*\([[:space:]]*null'
chk_any P85-11 "⚙️" "disable_classes / zend_extension=opcache などの ini 設定" 'disable_classes|zend_extension[[:space:]]*=[[:space:]]*"?opcache|opcache\.jit'

echo
echo "---"
echo "ヒットした行の合計: $(awk '{s+=$1} END {print s+0}' "$HITS_FILE")"
