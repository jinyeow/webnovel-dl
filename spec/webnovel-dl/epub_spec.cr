require "../spec_helper"

describe WebnovelDL::Epub do
  describe "#container" do
    it "creates a String of XML for the container file" do
      expected_output = <<-STRING
      <?xml version="1.0" encoding="UTF-8"?>
      <container
        xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
        version="1.0">
        <rootfiles>
          <rootfile
            full-path="content.opf"
            media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container> 
      STRING

      epub.container.should eq expected_output
    end
  end

  describe "#content" do
    it "creates a String of XML as a listing of the contents of the epub" do
    end
  end

  describe "#generate_chapter" do
    it "creates a String of XML that contains the chapter's title and text \
      content from a Chapter object" do

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

      epub.generate_chapter(some_chapter).should eq expected_output
    end
  end

  describe "#render" do
  end
end
