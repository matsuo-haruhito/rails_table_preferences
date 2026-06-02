# frozen_string_literal: true

RSpec.describe RailsTablePreferences::TablePreferencesHelper, type: :helper do
  before do
    RailsTablePreferences.configuration.unresolved_label_behavior = :humanize
  end

  describe "#table_preferences_hidden_fields" do
    it "renders controller params with scalar and array values" do
      html = helper.table_preferences_hidden_fields(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [
          { key: :customer_name, filter: { param: :search_word } },
          { key: :status, filter: { values_param: :statuses } },
          { key: :delivery_date, sort_param: :delivery_on }
        ]
      )

      expect(html).to include('type="hidden" name="search_word" value="山田"')
      expect(html).to include('type="hidden" name="statuses[]" value="未出荷"')
      expect(html).to include('type="hidden" name="statuses[]" value="出荷済"')
      expect(html).to include('type="hidden" name="sort" value="-delivery_on"')
    end

    it "renders boolean false values without emitting blank params" do
      html = helper.table_preferences_hidden_fields(
        settings: {
          filters: {
            active: { operator: :equals, value: false },
            archived: { operator: :equals, value: true },
            memo: { operator: :contains, value: "" }
          }
        },
        columns: [
          { key: :active, filter: { param: :active } },
          { key: :archived, filter: { param: :archived } },
          { key: :memo, filter: { param: :memo } }
        ]
      )

      expect(html).to include('type="hidden" name="active" value="false"')
      expect(html).to include('type="hidden" name="archived" value="true"')
      expect(html).not_to include('name="memo"')
      expect(html).not_to include('value=""')
    end

    it "renders Ransack fields under the requested namespace" do
      html = helper.table_preferences_hidden_fields(
        settings: {
          filters: {
            customer_name: { operator: :contains, value: "山田" },
            status: { operator: :in, values: %w[未出荷 出荷済] }
          },
          sorts: [{ key: :delivery_date, direction: :desc }]
        },
        columns: [:customer_name, :status, :delivery_date],
        adapter: :ransack,
        namespace: :q
      )

      expect(html).to include('type="hidden" name="q[customer_name_cont]" value="山田"')
      expect(html).to include('type="hidden" name="q[status_in][]" value="未出荷"')
      expect(html).to include('type="hidden" name="q[status_in][]" value="出荷済"')
      expect(html).to include('type="hidden" name="q[s][]" value="delivery_date desc"')
    end

    it "recursively renders nested names and skips blank values" do
      html = helper.safe_join(
        helper.send(
          :table_preferences_hidden_field_tags,
          {
            "filters" => {
              "customer_name_cont" => "山田",
              "memo_cont" => "",
              "status_in" => ["未出荷", "", nil, "出荷済"],
              "flag_in" => [true, false, "", nil]
            }
          },
          namespace: :q
        )
      )

      expect(html).to include('type="hidden" name="q[filters][customer_name_cont]" value="山田"')
      expect(html).to include('type="hidden" name="q[filters][status_in][]" value="未出荷"')
      expect(html).to include('type="hidden" name="q[filters][status_in][]" value="出荷済"')
      expect(html).to include('type="hidden" name="q[filters][flag_in][]" value="true"')
      expect(html).to include('type="hidden" name="q[filters][flag_in][]" value="false"')
      expect(html).not_to include('name="q[filters][memo_cont]"')
      expect(html).not_to include('value=""')
    end
  end
end
