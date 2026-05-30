# frozen_string_literal: true

RSpec.describe "table_preferences_params Ransack adapter", type: :helper do
  it "passes normalized column metadata to the Ransack adapter" do
    params = helper.table_preferences_params(
      settings: {
        filters: {
          customer_id: { operator: :contains, value: "山田" },
          status: { operator: :equals, value: "出荷済" }
        },
        sorts: [
          { key: :customer_id, direction: :asc },
          { key: :created_at, direction: :desc }
        ]
      },
      columns: [
        helper.table_preferences_column(
          :customer_id,
          label: "Customer",
          filter: { type: :text, param: :customer_name },
          sort_param: :customer_name
        ),
        helper.table_preferences_column(:status, label: "Status", filter: { type: :select }),
        helper.table_preferences_column(:created_at, label: "Created at")
      ],
      adapter: :ransack
    )

    expect(params).to eq(
      "customer_name_cont" => "山田",
      "status_eq" => "出荷済",
      "s" => ["customer_name asc", "created_at desc"]
    )
  end
end
