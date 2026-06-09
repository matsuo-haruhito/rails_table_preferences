# frozen_string_literal: true

RSpec.describe "rails_table_preferences datetime filter mapping" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }
  let(:docs_source) { File.read(File.join(repo_root, "docs/filter_metadata.md")) }

  it "keeps datetime and time filters on the date-style operator set" do
    expect(controller_source).to include('const DATE_TIME_FILTER_TYPES = new Set(["datetime", "datetime-local", "time"])')
    expect(controller_source).to include('DATE_TIME_FILTER_TYPES.has(String(filter.type))')
    expect(controller_source).to include('["equals", "gteq", "lteq", "between", "blank", "present"]')
  end

  it "maps datetime filter types to native browser inputs" do
    expect(controller_source).to include('if (type === "datetime" || type === "datetime-local") return "datetime-local"')
    expect(controller_source).to include('if (type === "time") return "time"')
  end

  it "documents the browser-string and host-app timezone boundary" do
    expect(docs_source).to include("`datetime` / `datetime-local`")
    expect(docs_source).to include("native `datetime-local` input")
    expect(docs_source).to include("without timezone normalization")
    expect(docs_source).to include("host application's timezone-aware query representation")
  end
end
