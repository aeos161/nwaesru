require "tmpdir"
require "fileutils"

RSpec.describe Primus::Page do
  describe ".open" do
    it "retains artifact bytes independently of the literal YAML body" do
      Dir.mktmpdir do |directory|
        FileUtils.mkdir_p("#{directory}/data/decoded")
        File.binwrite("#{directory}/data/decoded/source.yml", "body: |\n  A\n")

        page = Dir.chdir(directory) { Primus::Page.open(path: "source") }

        expect(page).to have_attributes(
          artifact_bytes: "body: |\n  A\n", source_body: "A\n",
        )
      end
    end

    it "honors YAML strip chomping without trimming the extracted text" do
      Dir.mktmpdir do |directory|
        FileUtils.mkdir_p("#{directory}/data/decoded")
        File.binwrite("#{directory}/data/decoded/source.yml",
                      "body: |-\n  A \n")

        page = Dir.chdir(directory) { Primus::Page.open(path: "source") }

        expect(page.source_body).to eq("A ")
      end
    end

    it "captures the folded body separately from YAML layout" do
      Dir.mktmpdir do |directory|
        FileUtils.mkdir_p("#{directory}/data/decoded")
        File.binwrite("#{directory}/data/decoded/source.yml",
                      "body: >\n  A\n  B\n")

        page = Dir.chdir(directory) { Primus::Page.open(path: "source") }

        expect(page.source_body).to eq("A B\n")
      end
    end

    context "with a missing body" do
      it "reports the offending source path and body field" do
        Dir.mktmpdir do |directory|
          FileUtils.mkdir_p("#{directory}/data/decoded")
          File.binwrite("#{directory}/data/decoded/source.yml", "title: A\n")

          expect { Dir.chdir(directory) { Primus::Page.open(path: "source") } }.
            to raise_error(ArgumentError, /source\.yml.*body|body.*source\.yml/)
        end
      end
    end

    context "with a non-string body" do
      it "rejects an array instead of silently coercing it" do
        Dir.mktmpdir do |directory|
          FileUtils.mkdir_p("#{directory}/data/decoded")
          File.binwrite("#{directory}/data/decoded/source.yml", "body: [A]\n")

          expect { Dir.chdir(directory) { Primus::Page.open(path: "source") } }.
            to raise_error(ArgumentError, /body/)
        end
      end
    end

    context "with invalid UTF-8" do
      it "identifies the source path in the encoding error" do
        Dir.mktmpdir do |directory|
          FileUtils.mkdir_p("#{directory}/data/decoded")
          File.binwrite("#{directory}/data/decoded/source.yml",
                        "body: \xFF\n".b)

          expect { Dir.chdir(directory) { Primus::Page.open(path: "source") } }.
            to raise_error(ArgumentError,
                           /source\.yml.*UTF-8|UTF-8.*source\.yml/)
        end
      end
    end
  end

  describe ".new" do
    it "retains in-memory source without inventing artifact bytes" do
      body = "ᚠ \n\n"

      page = Primus::Page.new(data: body)

      expect(page).to have_attributes(
        source_body: "ᚠ \n\n", artifact_bytes: nil, source_path: nil,
      )
    end
  end
end
