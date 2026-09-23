require "tmpdir"
require "fileutils"

RSpec.describe Primus::LiberPrimus::Page do
  describe ".open" do
    it "retains source whitespace independently of legacy display trimming" do
      Dir.mktmpdir do |directory|
        FileUtils.mkdir_p("#{directory}/data/encoded/liber_primus")
        path = "#{directory}/data/encoded/liber_primus/page_55.yml"
        File.binwrite(path, "body: |+\n  ᚠ  \n\n")

        page = Dir.chdir(directory) {
          Primus::LiberPrimus::Page.open(page_number: 55)
        }

        expect([page.source_body, page.to_s]).to eq(["ᚠ  \n\n", "ᚠ"])
      end
    end
  end
end
