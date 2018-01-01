require "../spec_helper"

describe WebnovelDL::Epub do
  describe "#container" do
  end

  describe "#content" do
  end

  describe "#generate_chapter" do
    it "creates a String of XML that contains the chapter's title and text content from a Chapter object" do
      some_chapter = WebnovelDL::Model::Chapter.new(
        "Test Title",
        "<p>some content goes here</p>",
        "1234"
      )

      some_chapter.should be_a WebnovelDL::Model::Chapter

      expected_output = <<-STRING
      <?xml version="1.0" encoding="UTF-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml"
            xmlns:ops="http://www.idpf.org/2007/ops"
            xml:lang="en">
        <head>
          <title>Test Title</title>
          <link href="style.css" rel="stylesheet" type="text/css" />
        </head>
        <body>
          <section ops:type="chapter">
            <h2 class="chapter-title">Test Title</h2>
            <p>some content goes here</p>
          </section>
        </body>
      </html>
      STRING    

      some_fiction = WebnovelDL::Model::Fiction.new(
        "Fiction Title",
        "Fiction Author",
        [some_chapter]
      )

      epub = WebnovelDL::Epub.new(some_fiction)
      epub.generate_chapter(some_chapter).should eq expected_output
    end
  end

  describe "#render" do
  end
end
