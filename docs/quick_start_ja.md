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

既存の `app/frontend/entrypoints/application.js` などで Stimulus application をすでに start している host app では、その `application` に `application.register(...)` だけを追加します。`Application.start()` を含む例は新規 minimal entrypoint 用です。同じ host app で `Application.start()` を二重に呼ばないでください。

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

既存の GET 検索フォームで user-entered params と保存済み filter/sort を一緒に送る場合は、[Controller integration の hidden fields section](controller_integration.md#hidden-fields-for-existing-search-forms) を確認します。`table_preferences_hidden_fields(...)` は通常の hidden field を描画するだけで、検索実行や params の最終適用は host app 側が所有します。

## 5. export は payload を使って host app で生成する

CSV / Excel / report file の生成は Rails Table Preferences の責務ではありません。host app の export code から `rails_table_preference_export_payload` を使い、保存済みの column visibility、order、labels、metadata を再利用します。

詳しくは [Export integration](export_integration.md) を確認してください。display/preference key と export value extraction key を分ける必要がある画面では、`export_key` metadata の扱いも同 guide を正本にします。

## 6. 本番導入 checklist / demo / sandbox / manual QA で確認する

quick start で最小 UI が表示できたら、次は [Production integration checklist](production_integration_checklist.md) を使って、demo-only の設定と実際の host-app index screen に必要な owner、engine route、query params、authorization、layout、export 境界を切り分けます。

本番画面へ入れる前に、軽い順に確認します。

- [Demo screen generator](demo.md): `--with-demo` または `--with-demo-route` で editor surface、scoped preset cues、existing search form hidden fields preview、export payload preview を見る。
- [Sandbox Rails app verification](sandbox.md): minimal Rails app で install、engine mount、JavaScript/CSS、preference wiring を確認する。
- [Production integration checklist](production_integration_checklist.md): demo / quick start で動いた構成を、実際の host-app index screen へ移す前に owner、engine route、query params、authorization、layout、export 境界を確認する。
- [Manual QA checklist](manual_qa.md): 実際の host app で認証、認可、layout、accessibility、既存 search/export integration を確認する。

特に既存 search form を残したまま保存済み filter/sort を roundtrip させる画面では、[Demo screen generator](demo.md) の hidden fields preview と [Manual QA checklist](manual_qa.md#13-existing-search-form-integration) の existing search form integration を合わせて確認してください。

特に dense table、horizontal scroll、fixed/pinned columns、custom CSS がある画面では、[Resize and auto-fit guidance](resize_auto_fit.md)、[Fixed columns and column groups](fixed_columns_and_groups.md)、[Accessibility baseline](accessibility.md) も合わせて確認してください。

## 7. 困ったときの入口

このページでは詳細を重複させず、症状から英語正本 docs へ移動する入口だけを置きます。

- controller が動かない、Save が 404 / 401 になる、`current_user` や configured owner が nil になる: [Troubleshooting](troubleshooting.md) の install / Stimulus / engine mount / current owner sections を確認します。
- filter や sort の UI は変わるが検索結果に反映されない: [Troubleshooting](troubleshooting.md#filter-or-sort-ui-changes-do-not-change-database-results)、[Controller integration](controller_integration.md)、[Filter adapters](filter_adapters.md) を確認します。Rails Table Preferences は UI state と adapter params を扱い、database query は host app 側が適用します。
- 既存の検索フォームに保存済み filter/sort を渡したい、または hidden fields が期待どおり roundtrip しない: [Controller integration の hidden fields section](controller_integration.md#hidden-fields-for-existing-search-forms)、[Demo screen generator](demo.md)、[Manual QA checklist](manual_qa.md#13-existing-search-form-integration) を確認します。hidden field の描画、blank value omission、array params、host-app search execution を分けて見ます。
- select filter が表示されるが値が効かない、複数選択の保存値が想定と違う: [Select filter troubleshooting](select_filter_troubleshooting.md) を確認します。一般的な filter/sort params ではなく、`values_param`、scalar `options:`、host-app query ownership を切り分けます。
- shared / role / organization preset が selector に出ない: [Troubleshooting](troubleshooting.md#scoped-preset-exists-but-does-not-appear-in-the-selector) と [Scoped presets](scoped_presets.md) を確認します。`scope_context_method` が返す runtime value と保存済み `scope_key` が同じ stable identifier かを見ます。
- CSS、dense table layout、fixed / pinned columns、resize handles、accessibility state cues が崩れる: [Troubleshooting](troubleshooting.md)、[Resize and auto-fit guidance](resize_auto_fit.md)、[Fixed columns and column groups](fixed_columns_and_groups.md)、[Accessibility baseline](accessibility.md) を確認します。
- どの helper や adapter を使うか迷う: [Decision guide](decision_guide.md) を確認します。
- 対応 Ruby / Rails と CI coverage: [Support matrix](support_matrix.md) を確認します。
- release 前の確認: [Release checklist](release_checklist.md) と [Package verification](package_verification.md) を確認します。package verification が失敗した場合は、required files、package export targets、package-internal JavaScript imports、package metadata errors の要約行を最初に見ます。

## Drift を避けるための読み方

この日本語 quick start は、詳細を重複させず、正本 docs への入口として維持します。挙動や API が変わった場合は、まず英語の focused docs を更新し、このページは必要なリンクや要約だけを追従させます。

release/docs 変更時は、少なくとも次の入口が README、[docs index](index.md)、英語 focused docs と大きくズレていないか確認します。

- install path、package entrypoint、production integration、support matrix の first-run guidance。
- filter/sort、scoped presets、export payload、resource table helper の主要 surface。
- demo、sandbox、manual QA、release checklist、package verification と failure summary への確認導線。

新しい public surface を追加するときも、このページでは短い症状別入口かリンクの追加に留め、詳細手順は英語 docs を正本にします。