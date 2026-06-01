# 日本語 quick start

このページは、Rails Table Preferences を日本語の業務アプリに試験導入するときの最短導線です。詳細な正本は英語 docs に置き、このページでは「最初に何を確認するか」と「次に読むべき docs」を短くまとめます。

## 位置づけ

- 全ドキュメントの日本語訳ではありません。
- 実装済みの install / editor / preset / filter / sort / export / QA surface への入口です。
- 手順や API の詳細はリンク先の英語 docs を正本とします。
- host app 固有の認可、検索条件、CSV/Excel 生成、画面デザインは host app 側の責務です。

## 1. インストール経路を選ぶ

まず [Quick start](quick_start.md) と [Install path options](install_paths.md) を確認します。

通常の `stimulus-rails` 構成では install generator が migration、initializer、JavaScript controller、stylesheet をコピーします。

```bash
bin/rails generate rails_table_preferences:install
bin/rails db:migrate
```

Vite / `app/frontend` など package entrypoint を使う場合は、copied controller ではなく `rails_table_preferences/controller` の import と bundler alias を確認します。詳細は [JavaScript entrypoints](javascript_entrypoints.md) を参照してください。

`User` / `current_user` 以外の owner model を使う場合は、demo や JSON API を開く前に initializer で `owner_model` と `current_user_method` を設定し、その method が persisted owner record を返すことを確認します。

## 2. 最小の table preference UI を表示する

手書き table では、view-friendly な場所で column metadata を定義し、editor と table tag を同じ `table_key` で render します。

```ruby
@table_columns = [
  table_preferences_column(:order_no, label: "受注番号", default_width: 120),
  table_preferences_column(:customer_name, label: "得意先名", default_width: 240, overflow: :ellipsis),
  table_preferences_column(:delivery_date, label: "納品日", default_width: 140)
]
```

```erb
<%= table_preferences_editor(
  table_key: :orders,
  columns: @table_columns,
  title: "受注一覧の表示設定"
) %>

<%= table_preferences_table_tag(table_key: :orders, columns: @table_columns, class: "table") do %>
  <!-- existing table markup -->
<% end %>
```

Active Record metadata から convention-first に始めたい場合は、`resource_table_for` / `tree_resource_table_for` と [Resource table adapters](resource_tables.md) を先に確認します。

## 3. preset save / load の責務を確認する

owner-specific preferences は gem が保存します。shared / role / organization scoped presets を使う場合は、default resolution と運用境界を [Scoped presets](scoped_presets.md) で確認してください。

Rails Table Preferences が担当するのは table display preference と preset metadata です。誰が preset を作れるか、どの tenant / role に見せるか、業務上どの preset を標準にするかは host app の認可・運用設計に従います。

## 4. filter / sort は UI state として扱う

`filter:` や `sortable: true` は、検索 UI state と params 連携のための metadata です。実際の database query、join、authorization-aware filtering は host app または search adapter が担当します。

最初に読む docs は次の順番がおすすめです。

1. [Filter metadata](filter_metadata.md): column metadata と neutral filter/sort settings の形。
2. [Controller integration](controller_integration.md): saved preferences を controller params に反映する方法。
3. [Filter adapters](filter_adapters.md): Ransack、Datagrid、Filterrific、host application search object との境界。
4. [Select filter troubleshooting](select_filter_troubleshooting.md): select filter が query に効かないときの確認点。

## 5. export は payload を使って host app で生成する

CSV / Excel / report file の生成は Rails Table Preferences の責務ではありません。host app の export code から `rails_table_preference_export_payload` を使い、保存済みの column visibility、order、labels、metadata を再利用します。

詳しくは [Export integration](export_integration.md) を確認してください。display/preference key と export value extraction key を分ける必要がある画面では、`export_key` metadata の扱いも同 guide を正本にします。

## 6. demo / sandbox / manual QA で確認する

本番画面へ入れる前に、軽い順に確認します。

- [Demo screen generator](demo.md): `--with-demo` で editor surface、scoped preset cues、export payload preview を見る。
- [Sandbox Rails app verification](sandbox.md): minimal Rails app で install、engine mount、JavaScript/CSS、preference wiring を確認する。
- [Manual QA checklist](manual_qa.md): 実際の host app で認証、認可、layout、accessibility、既存 search/export integration を確認する。

特に dense table、horizontal scroll、fixed/pinned columns、custom CSS がある画面では、[Resize and auto-fit guidance](resize_auto_fit.md)、[Fixed columns and column groups](fixed_columns_and_groups.md)、[Accessibility baseline](accessibility.md) も合わせて確認してください。

## 7. 困ったときの入口

- install / Stimulus / CSS / API / filter/sort / scoped preset / customization: [Troubleshooting](troubleshooting.md)
- どの helper や adapter を使うか迷う: [Decision guide](decision_guide.md)
- 対応 Ruby / Rails と CI coverage: [Support matrix](support_matrix.md)
- release 前の確認: [Release checklist](release_checklist.md) と [Package verification](package_verification.md)

## Drift を避けるための読み方

この日本語 quick start は、詳細を重複させず、正本 docs への入口として維持します。挙動や API が変わった場合は、まず英語の focused docs を更新し、このページは必要なリンクや要約だけを追従させます。
