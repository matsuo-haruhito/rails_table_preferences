# frozen_string_literal: true

require "spec_helper"

RSpec.describe "rails_table_preferences preset search copy" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:controller_source) { File.read(File.join(repo_root, "app/javascript/rails_table_preferences/controller.js")) }

  it "describes no-match search as a load-candidate filter without changing preset actions" do
    expect(controller_source).to include(
      'presetNoSearchResultsLabel: { type: String, default: "一致する保存済み設定はありません。検索語を変更するか、検索欄を空にすると候補に戻ります。" }'
    )
    expect(controller_source).to include("empty.textContent = this.presetNoSearchResultsLabelValue")
    expect(controller_source).to include("input.setAttribute(\"aria-label\", this.presetSearchLabelValue)")
  end

  it "keeps preset search visibility and disabled state tied to the existing threshold and no-match state" do
    expect(controller_source).to include("const shouldShowSearch = allPresets.length >= this.normalizedPresetSearchThreshold")
    expect(controller_source).to include("this.presetSearchEmptyMessage.hidden = !enabled || !query || visibleCount > 0")
    expect(controller_source).to include("this.presetSelectTarget.disabled = this.busy || (enabled && Boolean(query) && visibleCount === 0)")
  end
end
