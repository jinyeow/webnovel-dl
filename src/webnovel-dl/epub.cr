require "uuid"
require "zip"

require "./model/fiction"
require "./model/chapter"

module WebnovelDL
  class Epub
    CSS = <<-STRING

    @font-face {
        font-family: "Source Sans Pro";
        font-weight: normal;
        font-style: normal;
        src: url("ssp.otf");
    }

    * {
        background-color: #212121;
        color: #d3d3d3;
        font-family: "Source Sans Pro", sans-serif;
    }
    .chapter-title, a {
    color: #b381b3;
    }
    .fiction-title, .fiction-author {
    color: #f4b350;
    padding: 8px;
    padding-left: 0;
    }
    .fiction-author {
    padding-left: 16px;
    }

    STRING

    FORMAT = "%Y-%m-%d'T'%I:%M:%S'Z'"

    struct ChapterNameAssoc
      property title, file

      def initialize(@title : String, @file : String)
      end
    end

    property fiction
    property uuid : String

    def initialize(@fiction : WebnovelDL::Model::Fiction)
      @uuid = UUID.random.to_s
    end

    def container : String
      <<-STRING
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
    end

    def content : String
      i = 1
      names = Array(ChapterNameAssoc).new
      @fiction.chapters.each do |ch|
        names.push(ChapterNameAssoc.new(ch.title, "chapter#{i.to_s}"))
        i += 1
      end
      result = <<-STRING
      <?xml version="1.0" encoding="UTF-8"?>
      <package version="3.0"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:opf="http://www.idpf.org/2007/opf"
        xmlns="http://www.idpf.org/2007/opf"
        unique-identifier="Id">
        <metadata>
          <dc:identifier id="Id">#{generateUUID}</dc:identifier>
          <meta property="dcterms:modified">#{Time.now.to_s(FORMAT)}</meta>
          <dc:language>en</dc:language>
          <dc:title xml:lang="en">#{@fiction.title}</dc:title>

        </metadata>
        <manifest>
          <item id="ssp" href="ssp.otf" media-type="application/vnd.ms-opentype" />
          <item id="style" href="style.css" media-type="text/css" />
          <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
          #{names.reduce("") do |acc, name|
              acc + "<item id=\"" + name.file + "\" href=\"" + name.file + \
                ".xhtml\" mediatype=\"application/xhtml+xml\" />"
            end}
        </manifest>
        <spine>
          <itemref idref="nav"/>
          #{names.reduce("") do |acc, name|
              acc + "<itemref idref=\"" + name.file + "\" />"
            end}
        </spine>
      </package>
      STRING
    end

    def nav : String
      i = 1
      names = Array(ChapterNameAssoc).new
      @fiction.chapters.each do |ch|
        names.push(ChapterNameAssoc.new(ch.title, "chapter#{i.to_s}"))
        i += 1
      end
      result = <<-STRING
      <?xml version="1.0" encoding="UTF-8" ?>
      <html xmlns="http://www.w3.org/1999/xhtml"
            xmlns:ops="http://www.idpf.org/2007/ops"
            xml:lang="en">
        <head>
          <title>Table of Contents</title>
          <link href="style.css" rel="stylesheet" type="text/css" />
        </head>
        <body>
         <nav ops:type="toc">
          <h1 class="fiction-title">#{@fiction.title}</h1>
          <a href="nav.xhtml">Table of Contents</a>
          <ol>
            #{names.reduce("") do |acc, name|
                acc + "<li><a href=\"" + name.file + ".xhtml\">" + name.title + "</a></li>"
              end}
          </ol>
      
        </nav>
       </body>
      </html> 
      STRING
    end

    def generate_chapter(chapter : WebnovelDL::Model::Chapter) String
      result = <<-STRING
      <?xml version="1.0" encoding="UTF-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml"
            xmlns:ops="http://www.idpf.org/2007/ops"
            xml:lang="en">
        <head>
          <title>#{chapter.title}</title>
          <link href="style.css" rel="stylesheet" type="text/css" />
        </head>
        <body>
          <section ops:type="chapter">
            <h2 class="chapter-title">#{chapter.title}</h2>
            #{chapter.content}
          </section>
        </body>
      </html>
      STRING
    end

    def render(filename : String)
      file = filename
      File.open(file, "w") do |f|
        Zip::Writer.open(f) do |zip|
          zip.add "mimetype", "application/epub+zip"
          zip.add "META-INF/container.xml", container()
          zip.add "content.opf", content()
          zip.add "nav.xhtml", nav()
          zip.add "ssp.otf", "../ssp.otf"
          zip.add "style.css", CSS

          i = 1
          @fiction.chapters.each do |ch|
            zip.add "chapter#{i}.xhtml", generate_chapter(ch)
            i += 1
          end
        end
      end
    end

    # NOTE: unused in favor of UUID.random
    private def generateUUID : String
      pattern = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
      t = Time.new.epoch
      proc = ->(c : Char) {
        r = (t.to_f + rand(1.0) * 16).to_i % 16
        t = (t.to_f.to_i.to_f / 16).to_i
        if c != 'x'
          r = (r & 0x3 | 0x8)
        end
        r.to_s(16)[-1].to_s
      }
      pattern.chars.map do |c|
        if c == 'x' || c == 'y'
          proc.call(c)
        else
          c
        end
      end.join.downcase
    end
  end
end

